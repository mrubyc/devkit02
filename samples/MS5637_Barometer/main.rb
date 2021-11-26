# coding: utf-8
#
# TE (Tyco Electronics)
#  MS5637-02BA03
#  INDUSTRIAL ALTIMETER PRESSURE SENSOR
#

ADRS_MS5637 = 0x76
$i2c = I2C.new

def to_int16( b1, b2 )
  return (b1 << 8 | b2) - ((b1 & 0x80) << 9)
end
def to_uint16( b1, b2 )
  return (b1 << 8 | b2)
end
def to_uint24( b1, b2, b3 )
  return b1 << 16 | b2 << 8 | b3
end

##
# MS5637 Initialize
#  (see: datasheet P10 and P7)
#
#@return [Hash]  Device identify result.
#
def ms5637_init()
  ret = {}

  # reset sensor chip
  $i2c.write( ADRS_MS5637, 0x1e )

  # read calibration data from PROM
  ret[:cal_data] = []
  (0..6).each {|n|
    s = $i2c.read( ADRS_MS5637, 2, 0xa0 | n << 1 )
    break  if !s
    ret[:cal_data] << to_uint16(s.getbyte(0), s.getbyte(1))
  }

  ret[:init] = (ret[:cal_data].size == 7) ? :OK : :ERROR

  return ret
end


##
# MS5637 Pressure and temperature calcuration.
#  (see: datasheet P7)
#
#@param  [Hash] data container
#@return [Hash] data container
#@return [Nil]  error.
#
def ms5637_meas( data = {} )
  return nil  if data[:init] == :ERROR

  c = data[:cal_data]

  # Read the D1 (uncompensated pressure) with oversampling ratio 4096.
  $i2c.write( ADRS_MS5637, 0x48 )
  sleep_ms 10
  s = $i2c.read( ADRS_MS5637, 3, 0x00 )
  return nil if !s
  d1 = to_uint24( s.getbyte(0), s.getbyte(1), s.getbyte(2) ).to_f

  # Read the D2 (uncompensated temperature) with oversampling ratio 4096.
  $i2c.write( ADRS_MS5637, 0x58 )
  sleep_ms 10
  s = $i2c.read( ADRS_MS5637, 3, 0x00 )
  d2 = to_uint24( s.getbyte(0), s.getbyte(1), s.getbyte(2) ).to_f

  # Calculate temperature.
  dt = d2 - c[5] * 2**8
  data[:temperature] = (2000 + dt * c[6] / 2**23) / 100

  # Calclate temperature compensated pressure.
  off  = c[2].to_f * 2**17 + (c[4].to_f * dt) / 2**6
  sens = c[1].to_f * 2**16 + (c[3].to_f * dt) / 2**7
  data[:pressure] = (d1 * sens / 2**21 - off) / 2**15 / 100

#  p [d1, d2, dt, off, sens ]

  return data
end


#
# main
#
lcd_location( 0, 0 )
lcd_puts "MS5637-02BA03"

ms5637 = ms5637_init()

while true
  next if !ms5637_meas( ms5637 )

  lcd_location( 1, 0 )
  lcd_puts sprintf( "Temp:%7.2f \xdfC", ms5637[:temperature] )
  lcd_location( 2, 0 )
  lcd_puts sprintf( "Pres:%7.2f hPa", ms5637[:pressure] )

  sleep 1
end
