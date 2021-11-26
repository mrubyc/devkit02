# coding: utf-8
#
# 表示
#


key0 = key1 = ~keypad_read()
page = 0
ofs = 0

disp_fmt = [
  [ "Dust sensor SPS30" ],
  [ " PM1.0:%5d [ug/m3]", :"m_PM1.0" ],
  [ " PM2.5:%5d [ug/m3]", :"m_PM2.5" ],
  [ " PM4.0:%5d [ug/m3]", :"m_PM4.0" ],
  [ " PM10 :%5d [ug/m3]", :"m_PM10"  ],
  [ "TypSize:%5d[um]",    :TypicalPerticleSize ],
], [
  [ "Dust sensor SPS30" ],
  [ " PM1.0:%5d [#/cm3]", :"n_PM1.0" ],
  [ " PM2.5:%5d [#/cm3]", :"n_PM2.5" ],
  [ " PM4.0:%5d [#/cm3]", :"n_PM4.0" ],
  [ " PM10 :%5d [#/cm3]", :"n_PM10"  ],
  [ "TypSize:%5d[um]",    :TypicalPerticleSize ],
]



while true
  flag_disp = true

  # check key up/down
  key1 = ~keypad_read()
  pushed_keys = key1 & (key0 ^ key1)
  key0 = key1

  case pushed_keys
  when 0x04     # up
    ofs -= 1
    ofs = 0  if ofs < 0

  when 0x08     # down
    ofs += 1
    ofs = 2  if ofs > 2

  when 0x10     # left
    page = 0

  when 0x20     # right
    page = 1

  else
    flag_disp = false
  end

  if $flag_data_ready
    $flag_data_ready = false
    flag_disp = true
  end

  if flag_disp
    led1_write 1
    4.times {|i|
      lcd_location( i, 0 )
      s = sprintf( disp_fmt[page][i + ofs][0],
                   $data[ disp_fmt[page][i + ofs][1] ] )
      lcd_puts( (s + " "*40)[0,40] )
    }
    led1_write 0
  end
end
