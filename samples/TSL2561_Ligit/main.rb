# coding: utf-8
#
# ams (TAOS) TSL2561 Ambient Light Sensor
# https://ams.com/tsl2561
#
# set MRBC_USE_MATH 1  in vm_config.h
#

ADRS_TSL2561 = 0x29
$i2c = I2C.new

TSL2561_SCALE_TBL = [0.034, 0.252, 1.0] # Data sheet Figure 18
TSL2561_OVER_INTEG_TH = 65535   # from Data Sheet Figure 8
TSL2561_UNDER_INTEG_TH = 13000  # 13000 = about MAX(=65535) * 0.8 * 0.252
TSL2561_OVER_GAIN_TH = 37177    # from Data Sheet Figure 8
TSL2561_UNDER_GAIN_TH = 7376    # 7376 = about MAX(=37177) * 0.8 / 0.252 / 16


##
# initialize
#
def tsl2561_init( param = {} )
  param[:gain] ||= 1
  param[:integ] ||= 0b10

  # Read ID(0xA)
  $i2c.write(ADRS_TSL2561, 0b1000_0000 | 0xA)
  res = $i2c.read(ADRS_TSL2561, 1 )
  param[:part_no] = res.getbyte(0) >> 4
  param[:rev_no] = res.getbyte(0) & 0x0f
  if param[:part_no] != 0b0101
    param[:init] = :ERROR
    return param
  end

  # Control(0x0) = 0x03 (POWER UP)
  $i2c.write(ADRS_TSL2561, 0b1000_0000, 0x03)

  # Timing(0x01) = GAIN(4), INTEG(1:0)
  $i2c.write(ADRS_TSL2561, 0b1000_0001, param[:gain] << 4 | param[:integ])

  param[:init] = :OK
  return param
end


##
# measure
#
def tsl2561_meas( param )
  while true
    tsl2561_read( param )
    break  if !tsl2561_adjust_gain( param )
    sleep 0.4
  end

  return tsl2561_calc_lux( param )
end


##
# read channel 0 and 1 value
#
def tsl2561_read( param )
  # ch0: sensitive to both visible and infrared light.
  # ch1: sensitive primarily to infrared light.

  # Read DATA0(0xC,0xD) using word protocol.
  $i2c.write(ADRS_TSL2561, 0b1010_0000 | 0xC)
  res = $i2c.read(ADRS_TSL2561, 2 )
  param[:ch0] = res.getbyte(1) << 8 | res.getbyte(0)

  # Read DATA1(0xE,0xF) using word protocol.
  $i2c.write(ADRS_TSL2561, 0b1010_0000 | 0xE)
  res = $i2c.read(ADRS_TSL2561, 2 )
  param[:ch1] = res.getbyte(1) << 8 | res.getbyte(0)
end


##
# Calculating Lux
#
def tsl2561_calc_lux( param )
  ch0 = param[:ch0]
  ch1 = param[:ch1]

  return 0.0  if ch0 == 0

  ratio = ch1.to_f / ch0.to_f
  if ratio <= 0.50
    lux = 0.0304 * ch0 - 0.062 * ch0 * ratio ** 1.4
  elsif ratio <= 0.61
    lux = 0.0224 * ch0 - 0.031 * ch1
  elsif ratio <= 0.80
    lux = 0.0128 * ch0 - 0.0153 * ch1
  elsif ratio <= 1.30
    lux = 0.00146 * ch0 - 0.00112 * ch1
  else
    lux = 0.0
  end

  # integ  Tint   scale
  #  10    402ms   x1.0
  #  01    101ms   x0.252
  #  00    13.7ms  x0.034
  lux /= TSL2561_SCALE_TBL[ param[:integ] ]
  lux *= 16  if param[:gain] == 0

  param[:ratio] = ratio
  param[:lux] = lux

  return lux
end


##
# adjust gain and Integration Time according to the measurement value.
#
def tsl2561_adjust_gain( param )
  #
  # (Strategy)
  # INTEG uses only 0b10 (402ms) and 0b01 (101ms). not use 0b00 (13.7ms).
  #
  #          | INTEG = 10 | INTEG = 01
  #          |  (402ms)   |  (101ms)
  # ---------+------------+------------
  # GAIN = 1 | Phase A    | B
  #  (x16)   |            |
  # ---------+------------+------------
  # GAIN = 0 | C          | D
  #  (x1)    |            |
  # ---------+------------+------------
  #
  # Transit phase
  #  (DARK) A <-> B <-> C <-> D (LIGHT)
  #

  param[:is_overflow] = false
  gain = nil
  integ = nil
  case [ param[:gain], param[:integ] ]
  when [ 1, 0b10 ]      # phase A
    if param[:ch0] >= TSL2561_OVER_INTEG_TH
      integ = 0b01
      param[:is_overflow] = true
    end

  when [ 1, 0b01 ]      # phase B
    if param[:ch0] <= TSL2561_UNDER_INTEG_TH
      integ = 0b10
    elsif param[:ch0] >= TSL2561_OVER_GAIN_TH
      gain = 0
      integ = 0b10
      param[:is_overflow] = true
    end

  when [ 0, 0b10 ]      # phase C
    if param[:ch0] <= TSL2561_UNDER_GAIN_TH
      gain = 1
      integ = 0b01
    elsif param[:ch0] >= TSL2561_OVER_INTEG_TH
      integ = 0b01
      param[:is_overflow] = true
    end

  when [ 0, 0b01 ]      # phase D
    if param[:ch0] <= TSL2561_UNDER_INTEG_TH
      integ = 0b10
    elsif param[:ch0] >= TSL2561_OVER_GAIN_TH
      param[:is_overflow] = true
    end
  else
    raise
  end

  param[:gain] = gain  if gain
  param[:integ] = integ  if integ

  if gain || integ
    # Timing(0x01) = GAIN(4), INTEG(1:0)
    $i2c.write(ADRS_TSL2561, 0b1000_0001, param[:gain] << 4 | param[:integ])
    return param[:is_adjust] = true
  end

  return param[:is_adjust] = false
end


#
# main
#
lcd_location( 0, 0 )
lcd_puts("TSL2561")
lcd_location( 1, 0 )
lcd_puts("Ambient Light Sensor")

param = tsl2561_init()
printf "Read ID RESULT: PartNO=%x, RevNo=%x\n", param[:part_no], param[:rev_no]
if param[:init] == :ERROR
  lcd_location( 2, 0 )
  lcd_puts("Sensor not found.")
  return
end

while true
  sleep_ms 500
  lux = tsl2561_meas( param )
  lcd_location( 2, 0 )
  if param[:is_overflow]
    lcd_puts( sprintf("overflow   "))
  else
    lcd_puts( sprintf("%7.1f lux", lux ))
  end
end
