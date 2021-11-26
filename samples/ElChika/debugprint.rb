sw1 = 1
while true
  #
  # polling SW1
  #
  if sw1_read() == 0    # Push ON?
    led1_write( 1 )

    if sw1 == 0         # change 0 -> 1 ?
      debugprint()
    end
    sw1 = 1

  elsif sw1 == 1        # Release? (change 1 -> 0?)
    led1_write( 0 )
    sw1 = 0
  end

  sleep_ms 10
end
