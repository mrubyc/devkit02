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
 </pre>
*/

#ifndef	MRUBYC_LCDC_H_
#define	MRUBYC_LCDC_H_
#ifdef __cplusplus
extern "C" {
#endif


/***** Feature test switches ************************************************/
/***** System headers *******************************************************/
#include <stdint.h>

/***** Local headers ********************************************************/
/***** Constat values *******************************************************/
/***** Macros ***************************************************************/
#define lcd_locate(r,c)  lcd_location((r),(c))
#define lcd_display_on(on_off) lcd_display_control( 0x04, (on_off) )
#define lcd_cursor_on(on_off)  lcd_display_control( 0x02, (on_off) )
#define lcd_blink_on(on_off)   lcd_display_control( 0x01, (on_off) )


/***** Typedefs *************************************************************/
/***** Global variables *****************************************************/
/***** Function prototypes **************************************************/
void lcd_init( void );
void lcd_clear( void );
void lcd_location( unsigned int row, unsigned int column );
void lcd_write( void *p, int size );
void lcd_putc( int ch );
void lcd_puts( const char *s );
void lcd_display_control( int bit, int on_off );
void lcd_set_cgram( int code, uint8_t *bitmap5x8 );

void lcd_write4( uint8_t rs, uint8_t data );
void lcd_write8( uint8_t rs, uint8_t data );


/***** Inline functions *****************************************************/


#ifdef __cplusplus
}
#endif
#endif
