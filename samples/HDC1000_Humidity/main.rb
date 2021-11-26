#
# TI HDC1000 humidity sensor.
# https://www.ti.com/product/HDC1000
#

ADRS_HDC1000 = 0x40
$i2c = I2C.new()

def to_uint16( b1, b2 )
  return (b1 << 8 | b2)
end

##
# HDC1000 initialize
#
#@return [Hash]  Device identify result.
#
def hdc1000_init()
  data = {}
  data[:m_id] = $i2c.read( ADRS_HDC1000, 2, 0xfe )
  data[:p_id] = $i2c.read( ADRS_HDC1000, 2, 0xff )

  if data[:m_id] == "TI" && data[:p_id] == "\x10\x00"
    $i2c.write( ADRS_HDC1000, 0x02, 0x16, 0x00 )
    data[:init] = :OK
  else
    data[:init] = :ERROR
  end

  return data
end


##
# HDC1000 measure
#
#@param  [Hash] data container
#@return [Hash] data container
#@return [Nil]  error.
#
def hdc1000_meas( data = {} )
  return nil  if data[:init] == :ERROR

  $i2c.read( ADRS_HDC1000, 0, 0x00, :NO_STOP )
  sleep( 0.007 )
  s = $i2c.read( ADRS_HDC1000, 4 )
  return nil if !s

  data[:temperature] = to_uint16(s.getbyte(0), s.getbyte(1)).to_f / 65536 * 165 - 40
  data[:humidity] = to_uint16(s.getbyte(2), s.getbyte(3)) * 100 / 65536
  return data
end


#
# main
#
lcd_location( 0, 0 )
lcd_puts("HDC1000 HumiditySensor")

hdc1000 = hdc1000_init()

while true
  next if !hdc1000_meas( hdc1000 )

  lcd_location( 1, 0 )
  lcd_puts( sprintf( "Temperature:%5.1f \xdfC", hdc1000[:temperature] ))

  lcd_location( 2, 0 )
  lcd_puts( sprintf( "Humidity:%8.0f %%", hdc1000[:humidity] ))

  sleep 1
end
