# coding: utf-8
#
# SENSIRION SGP30
#  Indoor Air Quality Sensor for TVOC and CO2eq Measurements
#

ADRS_SGP30 = 0x58

def to_uint16( b1, b2 )
  return (b1 << 8 | b2)
end

#
# define Fixnum#downto
#
class Fixnum
  def downto(n)
    i = self
    while i >= n
      yield i
      i -= 1
    end
  end
end

#
# calculate CRC8
#
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
# SGP30 read data and check CRC subroutine.
#
def sgp30_read_data( cmd, duration, bytes )
  $i2c.write( ADRS_SGP30, (cmd >> 8) & 0xff, (cmd & 0xff), :NO_STOP )
  sleep_ms duration  if duration > 0
  s = $i2c.read( ADRS_SGP30, bytes )
  return nil  if !s

  # check CRC
  s2 = ""
  ret = ""
  s.each_byte {|byte|
    if s2.length == 2
      return nil  if crc8( s2 ) != byte
      ret << s2
      s2 = ""
    else
      s2 << byte
    end
  }

  return ret
end


##
# SGP30 initalize
#
#@return [Hash]  Device identify result.
#
def sgp30_init()
  data = {}

  s = sgp30_read_data( 0x3682, 0, 9 )   # Get serial ID
  if !s
    data[:init] = :ERROR
    return data
  end

  sid = ""
  s.each_byte {|b| sid << sprintf("%02X", b) }
  data[:s_id] = sid

  s =sgp30_read_data( 0x202f, 0, 3 )    # Get feature set
  data[:feature_set] = to_uint16( s.getbyte(0), s.getbyte(1) )

  sgp30_read_data( 0x2003, 10, 0 )      # IAQ init

  data[:init] = :OK
  return data
end


##
# SGP30 measure
#
#@param  [Hash] data container
#@return [Hash] data container
#@return [Nil]  error.
#
def sgp30_meas( data = {} )
  return nil  if data[:init] == :ERROR

  s = sgp30_read_data( 0x2008, 12, 6 )  # Measure IAQ
  return nil  if !s

  data[:co2eq] = to_uint16( s.getbyte(0), s.getbyte(1) )
  data[:tvoc]  = to_uint16( s.getbyte(2), s.getbyte(3) )

  return data
end




#
# main
#
$i2c = I2C.new

lcd_location( 0, 0 )
lcd_puts("Air Quality Sensor")
lcd_location( 1, 15 )
lcd_puts("SGP30")

# initialize sensor
sgp30 = sgp30_init()

if sgp30[:init] == :ERROR
  lcd_location( 2, 0 )
  lcd_puts("Sensor init error.")
  return
end

# waiting sensor initialize phase
lcd_location( 2, 1 )
lcd_puts("Serial:#{sgp30[:s_id]}")
15.downto(0) {|i|
  lcd_location( 3, 1 )
  lcd_puts( sprintf("waiting init %2d", i ))
  sleep 1
}
lcd_location( 2, 0 )
lcd_puts(" "*20)
lcd_location( 3, 0 )
lcd_puts(" "*20)

# main loop
while true
  10.times {
    next  if !sgp30_meas( sgp30 )

    lcd_location( 2, 1 )
    lcd_puts sprintf( "TVOC :%5d ppb", sgp30[:tvoc] )
    lcd_location( 3, 1 )
    lcd_puts sprintf( "CO2eq:%5d ppm", sgp30[:co2eq] )
    sleep 1
  }

  s = sgp30_read_data( 0x2015, 10, 6 )          # Get IAQ baseline
  puts "baseline: #{s.inspect}"
  # (NOTE)
  #  ここでは参考として、IAQ baseline データが変化することを確認するのみとしている。
end
