#
# ボード上のスイッチを押すとLEDがつきます
#

while true
  if sw1_read() == 0
    led1_write( 1 )
  else
    led1_write( 0 )
  end
end
