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

non_sensitive = 0.03
dt = 0.5
friction = 0.01
reflection = 0.8

dot_x = dot_x1 = 10     # 位置
dot_y = dot_y1 = 2
dot_vx = dot_vy = 0     # 速度

lcd_location( dot_y, dot_x )
lcd_putc(0xff)

n = 0
while true
  next if !adxl345_meas( adxl345 )

  if (n += 1) > 10
    [adxl345[:x], adxl345[:y], adxl345[:z]].each_with_index {|v,i|
      row = i+1
      s = frame_buffer[row] = sprintf("%s:%+5.2f", "XYZ"[i], v )
      if dot_x <= 6 && dot_y == row
        s = frame_buffer[row].dup
        s[dot_x] = "\xff"
      end
      lcd_location( row, 0 )
      lcd_puts(s)
    }
    n = 0
  end

  dot_vx -= adxl345[:x] * dt  if adxl345[:x].abs > non_sensitive
  dot_vy += adxl345[:y] * dt  if adxl345[:y].abs > non_sensitive

  if dot_vx > 0
    dot_vx -= friction
    dot_vx = 0  if dot_vx < 0
  else
    dot_vx += friction
    dot_vx = 0  if dot_vx > 0
  end
  if dot_vy > 0
    dot_vy -= friction
    dot_vy = 0  if dot_vy < 0
  else
    dot_vy += friction
    dot_vy = 0  if dot_vy > 0
  end

  dot_x1 += dot_vx * dt
  dot_y1 += dot_vy * dt
  #    p [dot_x1, dot_vx]

  if dot_x != dot_x1.to_i || dot_y != dot_y1.to_i
    if dot_x1 < 0
      dot_x1 = 0
      dot_vx = -dot_vx * reflection
    end
    if dot_x1 > 19
      dot_x1 = 19
      dot_vx = -dot_vx * reflection
    end
    if dot_y1 < 0
      dot_y1 = 0
      dot_vy = -dot_vy * reflection
    end
    if dot_y1 > 3
      dot_y1 = 3
      dot_vy = -dot_vy * reflection
    end

    lcd_location( dot_y, dot_x )
    lcd_puts( frame_buffer[dot_y][dot_x] || " " )

    dot_x = dot_x1.to_i
    dot_y = dot_y1.to_i
    lcd_location( dot_y, dot_x )
    lcd_putc( 0xff )
  end
  sleep_ms 50
end
