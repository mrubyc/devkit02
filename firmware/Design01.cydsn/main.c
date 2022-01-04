/*! @file
  @brief
  mruby/c firmware for mruby/c devkit 02

  <pre>
  Copyright (C) 2018-2021 Kyushu Institute of Technology.
  Copyright (C) 2018-2021 Shimane IT Open-Innovation Center.

  This file is distributed under BSD 3-Clause License.

  </pre>
*/


#include <project.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "mrubyc.h"
#include "lcdc.h"
#include "uart2.h"
#include "c_i2c.h"
#include "c_uart.h"
#include "c_spi.h"
#include "c_eeprom.h"

#include "mrbc_monitor.h"


#define PWM_FREQ 2400000
#define PWM_COUNT_MAX 65535

#define MEMORY_SIZE (1024*32)	// mruby/c workarea.
static uint8_t memory_pool[MEMORY_SIZE];


/* Flash ROM structure.
  (e.g. MRBC_MAX_BYTECODES = 4)
 0000 size1	(uint16_t * 4)
 0002 size2
 0004 size3
 0006 size4
 0008 IREP1	(size1 bytes)
 xxxx IREP2	(size2 bytes)
 xxxx IREP3	(size3 bytes)
 xxxx IREP4	(size4 bytes)
*/
const uint8_t CYCODE mruby_bytecode[MRBC_SIZE_IREP_STRAGE] = {
  0xf8,0xff, 0,0, 0,0, 0,0,

0x52,0x49,0x54,0x45,0x30,0x30,0x30,0x36,0x8c,0xf9,0x00,0x00,0x02,0x4e,0x4d,0x41,
0x54,0x5a,0x30,0x30,0x30,0x30,0x49,0x52,0x45,0x50,0x00,0x00,0x02,0x30,0x30,0x30,
0x30,0x32,0x00,0x00,0x03,0xa1,0x00,0x07,0x00,0x0f,0x00,0x01,0x00,0x00,0x00,0xbd,
0x10,0x07,0x06,0x08,0x06,0x09,0x2e,0x07,0x00,0x02,0x10,0x07,0x4f,0x08,0x00,0x2e,
0x07,0x01,0x01,0x4f,0x07,0x01,0x08,0x08,0x03,0x09,0x0c,0x46,0x07,0x03,0x4f,0x08,
0x02,0x08,0x09,0x03,0x0a,0x10,0x46,0x08,0x03,0x4f,0x09,0x03,0x07,0x0a,0x0b,0x0b,
0x46,0x09,0x03,0x4f,0x0a,0x04,0x09,0x0b,0x0b,0x0c,0x46,0x0a,0x03,0x4f,0x0b,0x05,
0x08,0x0c,0x07,0x0d,0x46,0x0b,0x03,0x4f,0x0c,0x06,0x08,0x0d,0x0c,0x0e,0x46,0x0c,
0x03,0x46,0x07,0x06,0x01,0x01,0x07,0x06,0x02,0x06,0x03,0x06,0x04,0x21,0x00,0xb2,
0x01,0x07,0x03,0x3c,0x07,0x01,0x01,0x03,0x07,0x0c,0x08,0x2e,0x07,0x02,0x01,0x07,
0x08,0x2e,0x07,0x03,0x01,0x01,0x02,0x07,0x10,0x07,0x01,0x08,0x02,0x2e,0x07,0x04,
0x01,0x10,0x07,0x2e,0x07,0x05,0x00,0x01,0x05,0x07,0x2e,0x07,0x06,0x00,0x03,0x08,
0x3f,0x2e,0x07,0x03,0x01,0x01,0x05,0x07,0x01,0x08,0x04,0x2e,0x07,0x07,0x01,0x01,
0x06,0x07,0x01,0x07,0x01,0x55,0x08,0x00,0x2f,0x07,0x08,0x00,0x01,0x07,0x05,0x01,
0x04,0x07,0x11,0x07,0x22,0x07,0x00,0x60,0x0f,0x07,0x37,0x07,0x67,0x00,0x00,0x00,
0x07,0x00,0x00,0x11,0x6d,0x72,0x75,0x62,0x79,0x2f,0x63,0x20,0x64,0x65,0x76,0x6b,
0x69,0x74,0x20,0x30,0x32,0x00,0x00,0x03,0x53,0x57,0x31,0x00,0x00,0x03,0x53,0x57,
0x32,0x00,0x00,0x02,0x55,0x50,0x00,0x00,0x04,0x44,0x4f,0x57,0x4e,0x00,0x00,0x04,
0x4c,0x45,0x46,0x54,0x00,0x00,0x05,0x52,0x49,0x47,0x48,0x54,0x00,0x00,0x00,0x09,
0x00,0x0c,0x6c,0x63,0x64,0x5f,0x6c,0x6f,0x63,0x61,0x74,0x69,0x6f,0x6e,0x00,0x00,
0x08,0x6c,0x63,0x64,0x5f,0x70,0x75,0x74,0x73,0x00,0x00,0x02,0x3e,0x3e,0x00,0x00,
0x01,0x26,0x00,0x00,0x0a,0x6c,0x65,0x64,0x31,0x5f,0x77,0x72,0x69,0x74,0x65,0x00,
0x00,0x0b,0x6b,0x65,0x79,0x70,0x61,0x64,0x5f,0x72,0x65,0x61,0x64,0x00,0x00,0x01,
0x7e,0x00,0x00,0x01,0x5e,0x00,0x00,0x0f,0x65,0x61,0x63,0x68,0x5f,0x77,0x69,0x74,
0x68,0x5f,0x69,0x6e,0x64,0x65,0x78,0x00,0x00,0x00,0x02,0x1f,0x00,0x04,0x00,0x09,
0x00,0x00,0x00,0x00,0x00,0x75,0x00,0x00,0x33,0x08,0x00,0x00,0x1f,0x04,0x06,0x00,
0x07,0x05,0x01,0x06,0x02,0x2e,0x05,0x00,0x01,0x2e,0x04,0x01,0x01,0x06,0x05,0x41,
0x04,0x23,0x04,0x00,0x21,0x0f,0x04,0x37,0x04,0x10,0x04,0x01,0x05,0x01,0x07,0x06,
0x2e,0x05,0x02,0x01,0x01,0x06,0x01,0x08,0x07,0x2e,0x06,0x02,0x01,0x2e,0x04,0x03,
0x02,0x1f,0x04,0x05,0x00,0x07,0x05,0x01,0x06,0x02,0x2e,0x05,0x00,0x01,0x2e,0x04,
0x01,0x01,0x06,0x05,0x2e,0x04,0x04,0x01,0x23,0x04,0x00,0x66,0x10,0x04,0x01,0x05,
0x01,0x06,0x06,0x2e,0x05,0x02,0x01,0x2e,0x04,0x05,0x01,0x21,0x00,0x73,0x10,0x04,
0x4f,0x05,0x00,0x0b,0x06,0x3f,0x05,0x2e,0x04,0x05,0x01,0x37,0x04,0x00,0x00,0x00,
0x01,0x00,0x00,0x01,0x20,0x00,0x00,0x00,0x06,0x00,0x02,0x3c,0x3c,0x00,0x00,0x01,
0x26,0x00,0x00,0x02,0x5b,0x5d,0x00,0x00,0x0c,0x6c,0x63,0x64,0x5f,0x6c,0x6f,0x63,
0x61,0x74,0x69,0x6f,0x6e,0x00,0x00,0x02,0x21,0x3d,0x00,0x00,0x08,0x6c,0x63,0x64,
0x5f,0x70,0x75,0x74,0x73,0x00,0x45,0x4e,0x44,0x00,0x00,0x00,0x00,0x08,
};

extern UART_HANDLE uh[];


//================================================================
/*! タイマー割込ハンドラ
*/
CY_ISR(isr_Tick)
{
  mrbc_tick();
}


//================================================================
/*! HAL
*/
int hal_write(int fd, const void *buf, int nbytes)
{
#if 0
  static int flag_connect = 1;

  if( !USBUART_CDCIsReady() ) {
    if( !flag_connect ) return 0;

    // wait about 100 ms.
    for( int i = 0; i < 10; i++ ) {
      CyDelay( 10 );
      if( USBUART_CDCIsReady() ){
	flag_connect = 1;
	goto WRITE_OK;
      }
    }
    flag_connect = 0;
    return 0;
  }

 WRITE_OK:
  usbuart_write( buf, nbytes );
  return nbytes;

#else

  return uart_write( &uh[0], buf, nbytes );
#endif
}

int hal_flush(int fd)
{
  return 0;
}

int _write(int fd, const void *buf, int nbytes)
{
  return hal_write(fd, buf, nbytes);
}


//================================================================
/*! mruby/c methods
*/
//================================================================
/*! オンボードSW 現在状態の読み込み
*/
static void c_sw1_read(mrbc_vm *vm, mrbc_value v[], int argc)
{
  int sw1 = SW1_Read();
  SET_INT_RETURN(sw1);
}

//================================================================
/*! オンボードLED ON/OFF
*/
static void c_led1_write(mrbc_vm *vm, mrbc_value v[], int argc)
{
  LED1_Write(GET_INT_ARG(1));
}


//================================================================
/*! LCD表示場所指定
*/
static void c_lcd_location(mrbc_vm *vm, mrbc_value v[], int argc)
{
  int row = GET_INT_ARG(1);
  int col = GET_INT_ARG(2);

  lcd_location(row, col);
}


//================================================================
/*! LCD表示　1文字
*/
static void c_lcd_putc(mrbc_vm *vm, mrbc_value v[], int argc)
{
  int ch = GET_INT_ARG(1);

  lcd_putc( ch );
}

//================================================================
/*! LCD表示　文字列
*/
static void c_lcd_puts(mrbc_vm *vm, mrbc_value v[], int argc)
{
  lcd_write( mrbc_string_cstr(&v[1]), mrbc_string_size(&v[1]) );
}

//================================================================
/*! LCD表示　全消去
*/
static void c_lcd_clear(mrbc_vm *vm, mrbc_value v[], int argc)
{
  lcd_clear();
}

//================================================================
/*! LCD表示　カーソル表示 ON / OFF
*/
static void c_lcd_cursor_on(mrbc_vm *vm, mrbc_value v[], int argc)
{
  lcd_cursor_on( GET_INT_ARG(1) );
}

//================================================================
/*! LCD表示　ブリンク ON / OFF
*/
static void c_lcd_blink_on(mrbc_vm *vm, mrbc_value v[], int argc)
{
  lcd_blink_on( GET_INT_ARG(1) );
}


//================================================================
/*! LCD表示　CGRAM設定

  lcd_set_cgram( 1, "\x00\x01..." )
*/
static void c_lcd_set_cgram(mrbc_vm *vm, mrbc_value v[], int argc)
{
  int code = v[1].i;
  uint8_t *bitmap5x8 = (uint8_t *)mrbc_string_cstr(&v[2]);
  lcd_set_cgram( code, bitmap5x8 );
}


//================================================================
/*! メインボード上キーパッド　現在状態の読み込み
*/
static void c_keypad_read(mrbc_vm *vm, mrbc_value v[], int argc)
{
  int kpad = KEYPAD_Read();	// bitmapped
  SET_INT_RETURN(kpad);
}


//================================================================
/*! GPIO constructor

  gpio1 = GPIO.new( 1 )  # 1 to 5
*/
static void c_gpio_new(mrbc_vm *vm, mrbc_value v[], int argc)
{
  *v = mrbc_instance_new(vm, v->cls, sizeof(int));
  int n;
  if( mrbc_type(v[1]) == MRBC_TT_FIXNUM ) {
    n = mrbc_fixnum(v[1]);
  } else {
    n = -1;
  }

  *(int *)(v->instance->data) = n;
}


//================================================================
/*! GPIO setmode

  gpio1.setmode( mode )
*/
static void c_gpio_setmode(mrbc_vm *vm, mrbc_value v[], int argc)
{
  int pin_num = *((int *)v->instance->data);

  //  printf("PIN: %d\n", pin_num);

  // TODO
  // とりあえずモードは、0:入力 1:出力としておく
  int mode;
  switch( mrbc_fixnum(v[1]) ) {
  case 0: mode = PIN_DM_DIG_HIZ; break;
  case 1: mode = PIN_DM_STRONG;  break;
  default: goto ERROR_RETURN;
  }

  switch( pin_num ) {
  // (note) ch1 is shared with PWM1
  case 2: GRV_D2_SetDriveMode( mode ); break;
  case 3: GRV_D3_SetDriveMode( mode ); break;
  case 4: GRV_D4_SetDriveMode( mode ); break;
  case 5: GRV_D5_SetDriveMode( mode ); break;
  default: goto ERROR_RETURN;
  }

  SET_TRUE_RETURN();
  return;

 ERROR_RETURN:
  SET_FALSE_RETURN();
}


//================================================================
/*! GPIO read

  gpio1.read()
*/
static void c_gpio_read(mrbc_vm *vm, mrbc_value v[], int argc)
{
  int pin_num = *((int *)v->instance->data);
  int ret;

  switch( pin_num ) {
  // (note) ch1 is shared with PWM1
  case 2: ret = GRV_D2_Read(); break;
  case 3: ret = GRV_D3_Read(); break;
  case 4: ret = GRV_D4_Read(); break;
  case 5: ret = GRV_D5_Read(); break;
  default: goto ERROR_RETURN;
  }

  SET_INT_RETURN( ret );
  return;

 ERROR_RETURN:
  SET_NIL_RETURN();
}


//================================================================
/*! GPIO write

  gpio1.write( 0 or 1 )
*/
static void c_gpio_write(mrbc_vm *vm, mrbc_value v[], int argc)
{
  int pin_num = *((int *)v->instance->data);
  int data = !!mrbc_fixnum(v[1]);

  switch( pin_num ) {
  case 1:
    PWM1_WriteCompare( 0 );
    if( data ) {
      PWM1_SetCompareMode(PWM1__B_PWM__GREATER_THAN_OR_EQUAL_TO);
    } else {
      PWM1_SetCompareMode(PWM1__B_PWM__LESS_THAN);
    }

  case 2: GRV_D2_Write( data ); break;
  case 3: GRV_D3_Write( data ); break;
  case 4: GRV_D4_Write( data ); break;
  case 5: GRV_D5_Write( data ); break;
  default: goto ERROR_RETURN;
  }

  SET_TRUE_RETURN();
  return;

 ERROR_RETURN:
  SET_FALSE_RETURN();
}



//================================================================
/*! ADC constructor

  adc1 = ADC.new( 1 )  # 0 to 3
*/
static void c_adc_new(mrbc_vm *vm, mrbc_value v[], int argc)
{
  *v = mrbc_instance_new(vm, v->cls, sizeof(int16_t));
  int16_t n;
  if( mrbc_type(v[1]) == MRBC_TT_FIXNUM ) {
    n = mrbc_fixnum(v[1]);
  } else {
    n = -1;
  }

  *(int16_t *)(v->instance->data) = n;
}


//================================================================
/*! ADC read

  adc1.read()	# return voltage by Float
*/
static void c_adc_read(mrbc_vm *vm, mrbc_value v[], int argc)
{
  int ch = *((int16_t *)v->instance->data);

  GRV_AMux_1_Select( ch );
  GRV_ADC_1_StartConvert();
  GRV_ADC_1_IsEndConversion( GRV_ADC_1_WAIT_FOR_RESULT );

  SET_FLOAT_RETURN( 2.048 / 4096 * GRV_ADC_1_GetResult16() );
}


//================================================================
/*! ADC read_u16

  adc1.read_u16()	# return voltage by Float
*/
static void c_adc_read_u16(mrbc_vm *vm, mrbc_value v[], int argc)
{
  int ch = *((int16_t *)v->instance->data);

  GRV_AMux_1_Select( ch );
  GRV_ADC_1_StartConvert();
  GRV_ADC_1_IsEndConversion( GRV_ADC_1_WAIT_FOR_RESULT );

  SET_INT_RETURN( GRV_ADC_1_GetResult16() );
}


//================================================================
/*! PWM constructor

  pwm1 = PWM.new( n )  # n = 0 or 1
*/
static void c_pwm_new(mrbc_vm *vm, mrbc_value v[], int argc)
{
  *v = mrbc_instance_new(vm, v->cls, sizeof(uint16_t) * 3);
  uint16_t n;
  if( mrbc_type(v[1]) == MRBC_TT_FIXNUM ) {
    n = mrbc_fixnum(v[1]);
  } else {
    console_printf("Specify PWM channel 0 or 1.");
    return;
  }
  if( n > 1 ) {
    console_printf("Specify PWM channel 0 or 1.");
    return;
  }

  uint16_t *data = (uint16_t *)v->instance->data;
  data[0] = n;		// channel (0-1)
  data[1] = 0;		// period
  data[2] = 0x4000;	// duty    (0-0x8000)
}


//================================================================
/*! PWM 周波数設定

  pwm1.frequency( 1000 )
*/
static void c_pwm_frequency(mrbc_vm *vm, mrbc_value v[], int argc)
{
  uint16_t *data = (uint16_t *)v->instance->data;
  double freq;
  int duty, period, compare;

  switch( mrbc_type(v[1]) ) {
  case MRBC_TT_FIXNUM:
    freq = mrbc_fixnum(v[1]);
    break;
  case MRBC_TT_FLOAT:
    freq = mrbc_float(v[1]);
    break;
  default:
    console_printf("PWM#frequency needs fixnum or float.");
    return;
  }
  if( freq < 0 ) return;

  if( freq == 0 ) {
    period = 0;
  } else {
    period = PWM_FREQ / freq;
  }
  if( period > PWM_COUNT_MAX ) return;

  data[1] = period;
  duty = data[2];

  compare = period * duty / 0x8000;

  if( data[0] == 0 ) {
    PWM0_WritePeriod( period );
    PWM0_WriteCompare( compare );
  } else {
    PWM1_WritePeriod( period );
    PWM1_WriteCompare( compare );
  }
}

//================================================================
/*! PWM デューティー比設定

  pwm1.duty( 512 )	# 0 to 1024
  pwm1.duty( 0.5 )	# 0.0 to 1.0
*/
static void c_pwm_duty(mrbc_vm *vm, mrbc_value v[], int argc)
{
  uint16_t *data = (uint16_t *)v->instance->data;
  int duty, period, compare;

  switch( mrbc_type(v[1]) ) {
  case MRBC_TT_FIXNUM:
    duty = mrbc_fixnum(v[1]) * 32;  // input 0-1024  using 0-32768
    break;
  case MRBC_TT_FLOAT:
    duty = mrbc_float(v[1]) * 32768;
    break;
  default:
    console_printf("PWM#duty needs fixnum or float.");
    return;
  }
  if( duty < 0 ) return;
  if( duty > 0x8000 ) return;

  period = data[1];
  data[2] = duty;

  compare = period * duty / 0x8000;

  if( data[0] == 0 ) {
    PWM0_WritePeriod( period );
    PWM0_WriteCompare( compare );
  } else {
    PWM1_WritePeriod( period );
    PWM1_WriteCompare( compare );
  }
}

//================================================================
/*! PWM 周期設定
*/
static void c_pwm_period_us(mrbc_vm *vm, mrbc_value v[], int argc)
{
  uint16_t *data = (uint16_t *)v->instance->data;
  int duty, period, compare;

  period = GET_INT_ARG(1);
  if( period < 0 ) return;

  period = period * (PWM_FREQ / 1000) / 1000;
  if( period > PWM_COUNT_MAX ) return;

  data[1] = period;
  duty = data[2];

  compare = period * duty / 0x8000;

  if( data[0] == 0 ) {
    PWM0_WritePeriod( period );
    PWM0_WriteCompare( compare );
  } else {
    PWM1_WritePeriod( period );
    PWM1_WriteCompare( compare );
  }
}



//================================================================
/*! デバグ表示
*/
static void c_debugprint(mrbc_vm *vm, mrbc_value v[], int argc)
{
#if !defined(NDEBUG)
  void pqall(void);

  hal_disable_irq();
  for( int i = 0; i < 79; i++ ) {
    console_putchar('=');
  }
  console_putchar('\n');
  mrbc_alloc_print_memory_pool();

  pqall();

  int total, used, free, fragment;
  mrbc_alloc_statistics( &total, &used, &free, &fragment );
  console_printf("Memory total:%d, used:%d, free:%d, fragment:%d\n",
		 total, used, free, fragment );

  total = MAX_SYMBOLS_COUNT;
  mrbc_symbol_statistics( &used );
  console_printf("Symbol table: %d/%d %d%% used.\n",
		 used, total, 100 * used / total );

  hal_enable_irq();
#endif
}


//================================================================
/*! define mruby/c method for on-board devices.
*/
static void define_other_device_methods(void)
{
  mrbc_define_method(0, 0, "sw1_read",   c_sw1_read);
  mrbc_define_method(0, 0, "led1_write", c_led1_write);
  mrbc_define_method(0, 0, "lcd_location", c_lcd_location);
  mrbc_define_method(0, 0, "lcd_putc", c_lcd_putc);
  mrbc_define_method(0, 0, "lcd_puts", c_lcd_puts);
  mrbc_define_method(0, 0, "lcd_clear", c_lcd_clear);
  mrbc_define_method(0, 0, "lcd_cursor_on", c_lcd_cursor_on);
  mrbc_define_method(0, 0, "lcd_blink_on", c_lcd_blink_on);
  mrbc_define_method(0, 0, "lcd_set_cgram", c_lcd_set_cgram);

  mrbc_define_method(0, 0, "keypad_read", c_keypad_read);

  mrbc_class *gpio = mrbc_define_class(0, "GPIO", 0);
  mrbc_define_method(0, gpio, "new", c_gpio_new);
  mrbc_define_method(0, gpio, "setmode", c_gpio_setmode);
  mrbc_define_method(0, gpio, "read", c_gpio_read);
  mrbc_define_method(0, gpio, "write", c_gpio_write);

  mrbc_class *adc = mrbc_define_class(0, "ADC", 0);
  mrbc_define_method(0, adc, "new", c_adc_new);
  mrbc_define_method(0, adc, "read", c_adc_read);
  mrbc_define_method(0, adc, "read_u16", c_adc_read_u16);

  mrbc_class *pwm = mrbc_define_class(0, "PWM", 0);
  mrbc_define_method(0, pwm, "new", c_pwm_new);
  mrbc_define_method(0, pwm, "frequency", c_pwm_frequency );
  mrbc_define_method(0, pwm, "duty", c_pwm_duty );
  mrbc_define_method(0, pwm, "period_us", c_pwm_period_us );

  mrbc_define_method(0, 0, "debugprint", c_debugprint);
}


//================================================================
/*! mruby/c main
*/
static void mrubyc_start(void)
{
  uint16_t *tbl_bytecode_size = (uint16_t *)mruby_bytecode;
  const uint8_t *bytecode = mruby_bytecode + sizeof(uint16_t) * MRBC_MAX_BYTECODES;

  for( int i = 0 ; i < MRBC_MAX_BYTECODES ; i++ ) {
    if( tbl_bytecode_size[i] == 0 ) break;
    mrbc_create_task( bytecode, 0 );
    bytecode += tbl_bytecode_size[i];
  }

  mrbc_run();
}


//================================================================
/*! main
*/
int main()
{
  /*
    initialize
  */
  CyGlobalIntEnable;
  isr_Tick_StartEx(isr_Tick);

  // on-board devices.
  Em_EEPROM_Start();
  Opamp_1_Start();
  PWM0_Start();
  PWM1_Start();
  PWM1_SetCompareMode(PWM1__B_PWM__LESS_THAN);
  UART_0_Start();

  mrbc_monitor_init();
  lcd_init();

  // grove devices.
  GRV_AMux_1_Start();
  GRV_ADC_1_Start();

  // init mruby/c vm's
  mrbc_init(memory_pool, MEMORY_SIZE);
  mrbc_init_class_uart(0);	// -DMRBC_NUM_UART=2
  mrbc_init_class_i2c(0);
  mrbc_init_class_spi(0);
  mrbc_init_class_eeprom(0);
  define_other_device_methods();

  console_print("\r\n\x1b(B\x1b)B\x1b[0m\x1b[2JStart system.\n");
  lcd_location( 0, 0 );
  lcd_puts( "mruby/c devkit 02" );
  lcd_location( 1, 5 );
  lcd_puts( "firm rev 1.0.0" );

  /*
    main
  */
  int flag_monitor_or_exec;
  flag_monitor_or_exec = mrbc_monitor_or_exec();

  while( 1 ) {
    if( flag_monitor_or_exec == 0 ) {
      // start mruby/c VM
      lcd_clear();
      console_print("Start mruby/c program.\n");
      mrubyc_start();

      lcd_location( 3, 15 );
      lcd_puts( "done" );
      lcd_blink_on( 1 );
      console_print("\r\nmruby/c done.\n");
    }

    flag_monitor_or_exec = mrbc_monitor_run();
  }
}
