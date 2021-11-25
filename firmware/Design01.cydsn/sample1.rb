# coding: utf-8
lcd_location( 0, 0 )
lcd_puts("mruby/c devkit 02")

# 表示テーブル　表示文字, row, col の順
tbl_keys = [
  ["SW1",   2, 12],
  ["SW2",   2, 16],
  ["UP",    1,  5],
  ["DOWN",  3,  5],
  ["LEFT",  2,  1],
  ["RIGHT", 2,  6],
]

led = 0
cnt = 0
key_before = 0

while true
  cnt += 1

  led = (cnt >> 6) & 1
  led1_write( led )

  key = keypad_read()
  key = ~key & 0b0011_1111  # 負論理は扱いにくいので正論理に変換
  changed = key ^ key_before

  tbl_keys.each_with_index {|k,i|
    next  if (changed & (1 << i)) == 0

    lcd_location( k[1], k[2] )
    if (key & (1 << i)) != 0
      lcd_puts( k[0] )
    else
      lcd_puts( " " * 5 )
    end
  }

  key_before = key
end
