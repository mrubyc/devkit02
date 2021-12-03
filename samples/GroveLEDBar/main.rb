#
# seeed studio Grove LED Bar v2.0
# https://www.seeedstudio.com/Grove-LED-Bar-v2-0.html
#
# using MY9221 12-Channel LED Driver


##
# LED Bar class
#
class LedBar
  attr_accessor :led

  def initialize( pin_di, pin_dcki )
    @di = GPIO.new( pin_di )
    @dcki = GPIO.new( pin_dcki )
    @led = []

    13.times { @led << 0 }
  end

  ##
  # set each led brightness and display.
  #
  #@param  [Fixnum]  no         LED number.
  #@param  [Fixnum]  brightness brightness (0 - 255)
  #
  def set_led( no, brightness )
    return if no < 1 || no > 10
    return if brightness < 0 || brightness > 255

    @led[no] = brightness
    send_data()
  end


  ##
  # set led brightness like a level meter.
  #
  #@param [Fixnum]  level  0 - 10
  #@param [Fixnum]  brightness brightness (0 - 255)
  #
  def set_level( level, brightness = 0x20 )
    return if level < 0 || level > 10

    level = 10 - level
    i = 1
    while i < 13
      @led[i] = i > level ? brightness : 0
      i += 1
    end
    send_data()
  end


  ##
  # demo dimly
  #
  #@param  [Fixnum]  no         LED number.
  #
  def dimly( no )
    (1..10).each {|i|
      @led[i] = [255, 80, 10][(no - i).abs] || 0
    }
    send_data()
  end


  ##
  # DEMO ripple
  #
  #@param  [Fixnum]  no         LED number.
  #
  def ripple( no )
    (1..10).each {|i|
      @led[i] = (no == i) ? 255 : 0
    }
    send_data()

    pos1 = no - 1
    pos2 = no + 1
    while true
      (1..10).each {|i|
        lv1 = [200, 20][(pos1 - i).abs] || 0
        lv2 = [200, 20][(pos2 - i).abs] || 0
        @led[i] = [lv1, lv2].max
      }
      send_data()

      pos1 -= 1
      pos2 += 1

      break if pos1 < -1 && pos2 > 12
    end
  end


  ##
  # send buffer data
  #
  def send_data()
    @led.each {|d|
      ck = 15
      while ck >= 0
        @di.write( (d >> ck) & 0x01 )
        @dcki.write( ck & 0x01 )
        ck -= 1
      end
    }

    # send LATCH cycle.
    @di.write( 0 )
    # Tstart needs >220us
    @di.write( 1 ); @di.write( 0 )
    @di.write( 1 ); @di.write( 0 )
    @di.write( 1 ); @di.write( 0 )
    @di.write( 1 ); @di.write( 0 )
  end

end


##
# main
#
ledbar = LedBar.new( 4, 5 )     # using GPIO D4 and D5.

while true
  # level meter.
  (1..10).each {|i|
    ledbar.set_level( i )
    sleep 0.02
  }
  (1..10).each {|i|
    ledbar.set_level( 10 - i )
    sleep 0.02
  }
  sleep 1

  # each LEDs
  2.times {|n|
    (1..10).each {|i|
      ledbar.set_led( i, ((i + n) % 2) * 255 )
    }
  }

  # brightness
  [0, 5, 10, 100, 255, 100, 10, 5, 0].each {|b|
    (1..10).each {|i|
      ledbar.set_led( i, b )
    }
  }

  # dimly
  2.times {
    (-2..12).each {|no| ledbar.dimly( no ) }
    (-2..12).each {|no| ledbar.dimly( 10 - no ) }
  }

  # ripple
  [5, 8, 9, 3, 6, 2, 6].each {|no|
    ledbar.ripple( no )
  }

  sleep 1
end
