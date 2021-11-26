#
# ST LPS25H
# MEMS pressure sensor: 260-1260 hPa absolute digital output barometer
# https://www.st.com/ja/mems-and-sensors/lps25h.html
#

ADRS_LPS25H = 0x5c
$i2c = I2C.new()

def to_int16( b1, b2 )
  return (b1 << 8 | b2) - ((b1 & 0x80) << 9)
end
def to_uint24( b1, b2, b3 )
  return b1 << 16 | b2 << 8 | b3
end


##
# LPS25H initialize
#
#@return [Hash]  Device identify result.
#
def lps25h_init()
  data = {}
  $i2c.write( ADRS_LPS25H, 0x20, 0x90 )
  data[:init] = :OK

  return data
end


##
# LPS25H measure
#
#@param  [Hash] data container
#@return [Hash] data container
#@return [Nil]  error.
#
def lps25h_meas( data = {} )
  return nil  if data[:init] == :ERROR

  s = $i2c.read( ADRS_LPS25H, 5, 0xa8 )
  data[:pressure] = to_uint24( s.getbyte(2), s.getbyte(1), s.getbyte(0) ).to_f / 4096
  data[:temperature] = 42.5 + to_int16(s.getbyte(4), s.getbyte(3)).to_f / 480

  return data
end


##
# main
#
lcd_location( 0, 0 )
lcd_puts "LPS25H Barometer"

data = lps25h_init()

while true
  lps25h_meas( data )

  lcd_location( 1, 0 )
  lcd_puts sprintf( "Temp:%7.2f \xdfC", data[:temperature] )
  lcd_location( 2, 0 )
  lcd_puts sprintf( "Pres:%7.2f hPa", data[:pressure] )

  sleep 1
end
