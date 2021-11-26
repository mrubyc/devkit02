#
# 温度センサー オンボード LM60
#

lcd_location( 0, 0 )
lcd_puts("LM60 TempSensor")
adc0 = ADC.new( 0 )

while true
  v = adc0.read()
  t = (v - 424e-3) / 6.25e-3

  lcd_location( 1, 0 ) 
  lcd_puts( sprintf( "TEMP:%5.1f\xdfC", t ) )

  sleep 1
end
