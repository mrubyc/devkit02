# coding: utf-8
# Sensirion SPS30 Fine Dust Sensor.
#
# https://www.sensirion.com/jp/environmental-sensors/particulate-matter-sensors-pm25/
#

ADRS_SPS30 = 0x69

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
# SPS30 initalize
#
#@return [Hash]  Device identify result.
#
def sps30_init()
  data = {}

  sps30_write_data( 0xd304, "" )        # Reset
  sleep_ms 100

  s = sps30_read_data( 0xd002, 12 )     # Read Product type (for identify)
  if s != "00080000"
    data[:init] = :ERROR
    return data
  end

  s = sps30_read_data( 0xd033, 48 )     # Read serial number.
  pos = s.index("\x00")
  data[:s_id] = pos ? s[0, pos] : s

  s = sps30_read_data( 0xd100, 3 )      # Read version.
  data[:version] = sprintf("%d.%d", s.getbyte(0), s.getbyte(1))

  sps30_write_data( 0x0010, "\x05\x00" ) # Start Measurement.
  sleep_ms 20

  return data
end


##
# SPS30 read_data
#
def sps30_read_data( cmd, bytes )
  $i2c.write( ADRS_SPS30, (cmd >> 8) & 0xff, (cmd & 0xff) )
  s = $i2c.read( ADRS_SPS30, bytes )
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
# SPS30 write data
#
def sps30_write_data( cmd, data )
  wd = ""
  wd << ((cmd >> 8) & 0xff)
  wd << (cmd & 0xff)

  s2 = ""
  data.each_byte {|byte|
    s2 << byte
    if s2.length == 2
      wd << s2 << crc8(s2)
      s2 = ""
    end
  }

  $i2c.write( ADRS_SPS30, wd )
end


##
# SPS30 data index
#
def sps30_data_index()
  [ :"m_PM1.0", :"m_PM2.5", :"m_PM4.0", :"m_PM10",
    :"n_PM0.5", :"n_PM1.0", :"n_PM2.5", :"n_PM4.0", :"n_PM10",
    :TypicalPerticleSize
  ]
end


##
# SPS30 measure
#
#@param  [Hash] data container
#@return [Hash] data container
#@return [Nil]  error.
#
def sps30_meas( data = {} )
  return nil  if data[:init] == :ERROR

  s = sps30_read_data( 0x0202, 3 )      # Read Data-ready flag
  if !s
    data[:error] = "Can't get data ready flag."
    data[:flag_data_ready] = false
    return nil
  end
  data[:flag_data_ready] = (s.getbyte(1) == 0x01)
  return nil  if !data[:flag_data_ready]

  s = sps30_read_data( 0x0300, 30 )     # Read measured values
  if !s
    data[:error] = "Can't get measurement values."
    return nil
  end

  i = 0
  sps30_data_index.each {|idx|
    data[idx] = to_uint16( s.getbyte(i), s.getbyte(i+1) )
    i += 2
  }

  return data
end



#
# main
#
$i2c = I2C.new

data = sps30_init()
if data[:init] == :ERROR
  lcd_puts "Sensor Error."

else
  while true
    if !sps30_meas( data )
      sleep_ms 100
      next
    end

    p data
    $data = data
    $flag_data_ready = true
  end
end
