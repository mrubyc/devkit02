#
# SHARP GP2Y0A21YK
#  Distance Measuring Sensor Unit
#  Measuring distance: 10 to 80 cm
#  Analog output type
#
# https://global.sharp/products/device/lineup/selection/opto/haca/diagram.html
#

SENSOR_THRESHOLD = 1.5
$adc = ADC.new( 3 )

lcd_location( 0, 0 )
lcd_puts("GP2Y0A21YK Distance")

while true
  v = $adc.read()

  lcd_location( 2, 0 )
  lcd_puts sprintf("Vo:%5.3f", v )
  lcd_location( 3, 0 )
  lcd_puts( ((">" * (v*10).to_i) + " "*20)[0, 20] )

  if v > SENSOR_THRESHOLD
    led1_write( 1 )
  else
    led1_write( 0 )
  end

  sleep 0.1
end
