# coding: utf-8
#
# ANALOG DEVICES ADXL345 Digital Accelerometer.
# https://www.analog.com/en/products/adxl345.html
#

ADRS_ADXL345 = 0x53
$i2c = I2C.new()


def to_int16( b1, b2 )
  return (b1 << 8 | b2) - ((b1 & 0x80) << 9)
end


##
# ADXL345 initialize
#
#@return [Hash]  Device identify result.
#
def adxl345_init()
  data = {}

  res = $i2c.read( ADRS_ADXL345, 1, 0x00 )      # read device ID
  if res == "\xe5"
    data[:init] = :OK
  else
    data[:init] = :ERROR
    return data
  end

  $i2c.write( ADRS_ADXL345, 0x2d, 0b0000_1000 ) # POWER_CTL: Measure=1
  $i2c.write( ADRS_ADXL345, 0x31, 0b0000_1000 ) # DATA_FORMAT: FULL_RES=1
                                                #              Range=00 (2g)
  return data
end


##
# ADXL345 measure
#
#@param  [Hash] data container
#@return [Hash] data container
#@return [Nil]  error.
#
def adxl345_meas( data )
  return nil  if data[:init] == :ERROR

  res = "\x00"
  while (res.getbyte(0) & 0x80) == 0            # Check DATA_READY bit
    res = $i2c.read( ADRS_ADXL345, 1, 0x30 )
  end

  res = $i2c.read( ADRS_ADXL345, 6, 0x32 )      # Read DATA X,Y,Z
  return nil if !res

  data[:x] = to_int16( res.getbyte(1), res.getbyte(0) ).to_f / 256
  data[:y] = to_int16( res.getbyte(3), res.getbyte(2) ).to_f / 256
  data[:z] = to_int16( res.getbyte(5), res.getbyte(4) ).to_f / 256

  return data
end


#
# main
#
frame_buffer = ["ADXL345Accelerometer", "X:", "Y:", "Z:"]
frame_buffer.each_with_index {|s,i|
  lcd_location( i, 0 )
  lcd_puts(s)
}

adxl345 = adxl345_init()

while true
  next if !adxl345_meas( adxl345 )

  [adxl345[:x], adxl345[:y], adxl345[:z]].each_with_index {|v,i|
    if v > 0
      s1 = ""
      s2 = ">" * (v * 6).to_i
    else
      s1 = "<" * (-v * 6).to_i
      s2 = ""
    end

    lcd_location( i+1, 2 )
    lcd_puts( sprintf("%+5.2f%6.6s\xff%-6.6s", v, s1, s2 ))
  }

  sleep_ms 100
end
