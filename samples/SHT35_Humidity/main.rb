#
# Sensirion SHT35
# Humidity and Temperature Sensor
#

ADRS_SHT35 = 0x45
$i2c = I2C.new()

def to_uint16( b1, b2 )
  return (b1 << 8 | b2)
end

def crc8(data)
  crc = 0xff

  data.each_byte {|b|
    crc ^= b
    8.times {
      crc <<= 1
      crc ^= 0x31  if crc > 0xff
      crc &= 0xff
    }
  }
  return crc
end


##
# SHT35 initialize
#
#@return [Hash]  Device identify result.
#
def sht35_init()
  data = {}

  $i2c.write( ADRS_SHT35, 0x30, 0xa2 )          # Reset
  res = $i2c.read( ADRS_SHT35, 3, 0xf3, 0x2d )  # Read Status
  if crc8(res[0,2]) != res.getbyte(2)
    data[:init] = :ERROR
  else
    data[:init] = :OK
  end

  return data
end


##
# SHT35 measure
#
#@param  [Hash] data container
#@return [Hash] data container
#@return [Nil]  error.
#
def sht35_meas( data = {} )
  return nil  if data[:init] == :ERROR

  $i2c.write( ADRS_SHT35, 0x2c, 0x06 )
  sleep_ms( 12 )
  res = $i2c.read( ADRS_SHT35, 6 )

  # check CRC
  s2 = ""
  res.each_byte {|byte|
    if s2.length == 2
      return nil  if crc8( s2 ) != byte
      s2 = ""
    else
      s2 << byte
    end
  }
  st = to_uint16( res.getbyte(0), res.getbyte(1) ).to_f
  srh = to_uint16( res.getbyte(3), res.getbyte(4) ).to_f

  data[:temperature] = -45 + 175 * st / 65535
  data[:humidity]    = 100 * srh / 65535

  return data
end


#
# main
#
lcd_location( 0, 0 )
lcd_puts("SHT35 HumiditySensor")

sht35 = sht35_init()

while true
  next if !sht35_meas( sht35 )

  lcd_location( 1, 0 )
  lcd_puts( sprintf( "Temperature:%5.1f \xdfC", sht35[:temperature] ))

  lcd_location( 2, 0 )
  lcd_puts( sprintf( "Humidity:%8.0f %%", sht35[:humidity] ))

  sleep 1
end
