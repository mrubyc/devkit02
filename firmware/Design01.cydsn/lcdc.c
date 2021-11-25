/*! @file
 @brief
 LCD Character display module controller for mruby/c devkit-01

 @author Shimane IT Open-Innovation Center.
 @version v1.30
 @date Sat Sep  1 20:08:53 2018
 @note
 <pre>
  Copyright (C) 2016-2018 Shimane IT Open-Innovation Center.
  Original author: Shimane Institute for Industrial Technology.

   This file is destributed under BSD 3-Clause License.

  Pin assigns.

  all pin continues mode. (default)
    DB4 LCD_Write() 0bit (0x01)
    DB5 LCD_Write() 1bit (0x02)
    DB6 LCD_Write() 2bit (0x04)
    DB7 LCD_Write() 3bit (0x08)
    E   LCD_Write() 4bit (0x10)
    RS  LCD_Write() 5bit (0x20)
    R/W (LOW - Write Only)

  separate control pin mode.
    DB4 LCD_DATA() 0bit (0x01)
    DB5 LCD_DATA() 1bit (0x02)
    DB6 LCD_DATA() 2bit (0x04)
    DB7 LCD_DATA() 3bit (0x08)
    RS  LCD_RS()
    E   LCD_E()
    R/W (LOW - Write Only)

 </pre>
*/

/***** Feature test switches ************************************************/
/***** System headers *******************************************************/
/***** Local headers ********************************************************/
#include "CyLib.h"
#include "LCD.h"
#include "lcdc.h"

/***** Constat values *******************************************************/
#define RS_CTRL 0
#define RS_DATA 1

// Set 1 if need row/column check.
#if 1
# define LCD_NUM_ROW 4
# define LCD_NUM_COLUMN 20
#endif

// Change this table according to the type of LCD.
static const uint8_t LCD_ROW_ADDRESS[] = { 0x00, 0x40, 0x14, 0x54 };

/***** Macros ***************************************************************/
#define DELAY_us(us)    CyDelayUs(us)
#define DELAY_ms(ms)    CyDelay(ms)

// 0:all pin continues mode,  1:separate control pin mode.
#if 0
#define LCD_RS(rs)      LCD_RS_Write(rs)
#define LCD_E(e)        LCD_E_Write(e)
#define LCD_DATA(d)     LCD_Write(d)
#endif

/***** Typedefs *************************************************************/
/***** Function prototypes **************************************************/
/***** Local variables ******************************************************/
#if defined(LCD_NUM_ROW)
static uint8_t lcd_cursor_row;
static uint8_t lcd_cursor_column;
#endif
static uint8_t lcd_display_control_bitmap = 0x08;


/***** Global variables *****************************************************/
/***** Signal catching functions ********************************************/
/***** Local functions ******************************************************/
/***** Global functions *****************************************************/

//================================================================
/*! initialize a LCD panel

*/
void lcd_init( void )
{
  DELAY_ms( 20 );			// >15ms
  lcd_write4( RS_CTRL, 0x03 );
  DELAY_ms( 5 );			// >4.1ms
  lcd_write4( RS_CTRL, 0x03 );
  DELAY_us( 200 );			// >100us
  lcd_write4( RS_CTRL, 0x03 );
  DELAY_us( 53 );			// >37us (but typ.)
  lcd_write4( RS_CTRL, 0x02 );
  DELAY_us( 53 );

  lcd_write8( RS_CTRL, 0x28 );		// 2 lines, 5x8 dots
  lcd_write8( RS_CTRL, 0x08 );		// display off
  lcd_write8( RS_CTRL, 0x01 );		// display clear
  DELAY_us( 2160 );
  lcd_write8( RS_CTRL, 0x06 );		// cursor increment, display shift off

  lcd_display_on( 1 );			// display on
}



//================================================================
/*! clear all

*/
void lcd_clear( void )
{
  lcd_write8( RS_CTRL, 0x01 );
  DELAY_us( 1520 );			// >1.52ms

#if defined(LCD_NUM_ROW)
  lcd_cursor_row = 0;
  lcd_cursor_column = 0;
#endif
}



//================================================================
/*! set display position

  @param  row		Row
  @param  column	Column
*/
void lcd_location( unsigned int row, unsigned int column )
{
#if defined(LCD_NUM_ROW)
  lcd_cursor_row = row;
  lcd_cursor_column = column;
  if( lcd_cursor_row >= LCD_NUM_ROW ) return;
  if( lcd_cursor_column >= LCD_NUM_COLUMN ) return;
#endif

  lcd_write8( RS_CTRL, (LCD_ROW_ADDRESS[ row ] + column) | 0x80 );
}



//================================================================
/*! write string

  @param  p	pointer to data.
  @param  size	data size
*/
void lcd_write( void *p, int size )
{
#if defined(LCD_NUM_ROW)
  if( lcd_cursor_row >= LCD_NUM_ROW ) return;
  if( lcd_cursor_column >= LCD_NUM_COLUMN ) return;

  if( (LCD_NUM_COLUMN - lcd_cursor_column) < size ) {
    size = LCD_NUM_COLUMN - lcd_cursor_column;
  }
  lcd_cursor_column += size;
#endif

  int i;
  uint8_t *p1 = p;
  for( i = 0; i < size; i++ ) {
    lcd_write8( RS_DATA, *p1++ );
  }
}


//================================================================
/*! Put a character

  @param  ch	character code.
*/
void lcd_putc( int ch )
{
#if defined(LCD_NUM_ROW)
  if( lcd_cursor_row >= LCD_NUM_ROW ) return;
  if( lcd_cursor_column >= LCD_NUM_COLUMN ) return;
  lcd_cursor_column++;
#endif

  lcd_write8( RS_DATA, ch );
}



//================================================================
/*! Put a string

  @param	s       String
*/
void lcd_puts( const char *s )
{
#if defined(LCD_NUM_ROW)
  if( lcd_cursor_row >= LCD_NUM_ROW ) return;
#endif

  int ch;
  while( (ch = *s++) != '\0' ) {
#if defined(LCD_NUM_ROW)
    if( lcd_cursor_column >= LCD_NUM_COLUMN ) return;
    lcd_cursor_column++;

    lcd_write8( RS_DATA, ch );
#endif
  }
}



//================================================================
/*! Display, Cursor and Blink ON or OFF

  @param  bit
  @param  on_off
*/
void lcd_display_control( int bit, int on_off )
{
  if( on_off )
    lcd_display_control_bitmap |= bit;
  else
    lcd_display_control_bitmap &= ~bit;

  lcd_write8( RS_CTRL, lcd_display_control_bitmap );
}



//================================================================
/*! Set character generator RAM

  @param  code		character code (0-7)
  @param  bitmap5x8	bitmap data. 4-0 bits x 8datas. upper to lower.
*/
void lcd_set_cgram( int code, uint8_t *bitmap5x8 )
{
  int i;
  lcd_write8( RS_CTRL, 0x40 | ((code & 0x07) * 8) );
  for( i = 0; i < 8; i++ ) {
    lcd_write8( RS_DATA, bitmap5x8[i] );
  }
}



//================================================================
/*! Write a nibble data to LCD contol or data register.

  @param  rs	Select a register 0:Control, 1:Data.
  @param  data	data (LSB 4bits)
*/
void lcd_write4( uint8_t rs, uint8_t data )
{
#ifdef LCD_RS
  /*
    separate control pin mode.
  */
  LCD_RS( rs );
  LCD_E( 0 );
  LCD_DATA( data );
  DELAY_us( 0 );		//   tAS (>140ns)

  LCD_E( 1 );
  DELAY_us( 1 );		//   PWEH (>450ns)

  LCD_E( 0 );
  DELAY_us( 1 );		//   tCYCE (>1000ns)

#else
  /*
    all pin continues mode.
  */
  data &= 0x0f;
  if( rs ) data |= 0x20;
  LCD_Write( data );		// RS, /E
  DELAY_us( 0 );		//   tAS (>140ns)

  LCD_Write( data | 0x10 );	// E
  DELAY_us( 1 );		//   PWEH (>450ns)

  LCD_Write( data );		// /E
  DELAY_us( 1 );		//   tCYCE (>1000ns)
#endif
}



//================================================================
/*! Write a data to LCD control or data register.

  @param  rs	Select a register 0:Control, 1:Data.
  @param  data	data (8bits)
*/
void lcd_write8( uint8_t rs, uint8_t data )
{
  lcd_write4( rs, data >> 4 );		// High 4 bits.
  lcd_write4( rs, data & 0x0f );	// Low 4 bits.
  DELAY_us( 53 );
}
