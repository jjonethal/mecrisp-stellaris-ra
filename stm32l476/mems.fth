\ something to read
\ LSM303CTR 3D accelerometer and 3D magnetometer
\ http://www.st.com/st-web-ui/static/active/en/resource/technical/document/datasheet/DM00089896.pdf
\ Gyoscope L3GD20
\ http://www.st.com/web/en/resource/technical/document/datasheet/DM00036465.pdf
\ User manual UM1879 Discovery kit with STM32L476VG MCU
\ http://www.st.com/st-web-ui/static/active/en/resource/technical/document/user_manual/DM00172179.pdf
\ RM0351 Reference manual STM32L4x6 advanced ARM ® -based 32-bit MCUs
\ http://www.st.com/st-web-ui/static/active/en/resource/technical/document/reference_manual/DM00083560.pdf
\ STM32L476xx Datasheet
\ http://www.st.com/st-web-ui/static/active/en/resource/technical/document/datasheet/DM00108832.pdf
\ PM0214 Programming manual STM32F3 and STM32F4 Series Cortex ® -M4 programming manual
\ http://www.st.com/web/en/resource/technical/document/programming_manual/DM00046982.pdf
\
\ ********** Pins by Port ********************
\ GYRO_INT2 - PB8
\ MAG_CS    - PC0
\ MAG_INT   - PC1
\ MAG_DRDY  - PC2
\ MEMS_SCK  - PD1
\ GYRO_INT1 - PD2
\ MEMS_MISO - PD3
\ MEMS_MOSI - PD4
\ GYRO_CS   - PD7
\ XL_CS     - PE0
\ XL_INT    - PE1
\ 
\ ********** Pins by Name ********************
\ GYRO_CS   - PD7
\ GYRO_INT1 - PD2
\ GYRO_INT2 - PB8
\ MAG_CS    - PC0
\ MAG_DRDY  - PC2
\ MAG_INT   - PC1
\ MEMS_MISO - PD3
\ MEMS_MOSI - PD4
\ MEMS_SCK  - PD1
\ XL_CS     - PE0
\ XL_INT    - PE1
\
\ ********** debugging support ****************
0 variable DEBUG                               \ debug flag
: DEBUG? ( -- f) DEBUG @ ;                     \ turn on debugging output ?
: .debug" ( c-addr len -- )                    \ type text when debugging active
   DEBUG? if cr type ." sp " sp@ . ."  " else 2drop then ;

: .D" ( -- )                                   \ output debug text
   postpone s" postpone .debug" immediate ;
: .D DEBUG? if . else drop then ;
: debug-on -1 DEBUG ! ;
: dbg hex debug-on ;

\ ********** register definitions ************
$40021000 constant RCC_BASE


\ ********** nvic register *******************
$E000E100           constant NVIC_ISER0
$E000E280           constant NVIC_ICPR0
NVIC_ICPR0 4 +      constant NVIC_ICPR1
NVIC_ICPR0 8 +      constant NVIC_ICPR2

\ ********** gpio register *******************
$48000400           constant gpiob
gpiob               constant gpiob_moder
$04 gpiob or        constant gpiob_otyper
$10 gpiob or        constant gpiob_idr
$18 gpiob or        constant gpiob_bsrr
$20 gpiob or        constant gpiob_afrl

\ ********** utility functions ***************
: cnt0   ( m -- b )                           \ count trailing zeros with hw support
   dup negate and 1-
   clz negate #32 + 1-foldable ;
: bits@  ( m adr -- b )                       \ get bits a masked position
   @ over and swap cnt0 rshift ;
: bits!  ( n m adr -- )                       \ set masked bits at position
   >R dup >R cnt0 lshift                      \ shift value to proper pos
   R@ and                                     \ mask out unrelated bits
   R> not R@ @ and                            \ invert bitmask and makout new bits
   or r> ! ;                                  \ apply value and store back
: bit-mask! ( v m adr -- )                    \ set bit masked value at 
   >R dup >R and R> not R@ @ and or R> ! ; 

\ ********** nvic functions ******************
\ calculate nvic enable disable mask from ipsr number
\ ipsr "vector number" is interrupt position + 16 or vector_adress / 4 
: nvic-mask  ( n -- n )                        \ calculate mask for nvic 
   #16 - $1f and 1 swap lshift 1-foldable ;
: nvic-offset ( n -- n )                       \ nvic register offset depending on vector number
   #16 - #5 rshift #2 lshift 1-foldable ;
: nvic-enable-irq ( n -- )
   #16 - dup $1f and 1 swap lshift swap #5 rshift #2 lshift NVIC_ISER0 + bis! ;


: ftab: ( "name" -- )                          \ build function table head + handler
   <BUILDS  DOES> swap 2 lshift + @ execute ;

  
\ ********** spi state machine ***************
: enum dup constant 1+ ;


\ ********** variables ***********************


\ ********** state machine *******************

\ ********** spi state dispatcher table ******
ftab: spi-state-table
  ' spi->idle , \ default state
  ' spi->tx-start ,
  ' spi->tx-reg ,
  ' spi->tx-data ,
  ' spi->tx-complete ,
  ' spi->rx-start ,
  ' spi->rx-reg ,
  ' spi->rx-read-start ,
  ' spi->rx-data ,
  ' spi->rx-complete ,
  ' spi->abort ,
  ' spi->accel-start ,
  ' spi->accel-xfer ,
: end ;                                        \ see catcher :-)

\ ********** spi dispatcher functions ********
: spi-handle ( -- ) spi-state @ dup 0< not and dup spi->num-states < and spi-state-table ;
: spi-isr-ack ( -- )                           \ acknowledge interrupt
   SPI_EV nvic-mask SPI_EV nvic-offset NVIC_ICPR0 + !
   SPI_ER nvic-mask SPI_ER nvic-offset NVIC_ICPR0 + ! ;
: spi-irq-handle ( -- )                        \ default interrupt handler 
   ipsr case
     SPI_EV of spi-handle endof
     SPI_ER of spi-handle endof
     spi-old-handler @ execute                 \ invoke old handler
   endcase spi-isr-ack ;     
: spi-irq-init  ( -- ) 0 spi-dbg-irq-nr ! irq-collection @  irq-old-handler ! ['] spi-irq-handle irq-collection ! ;
: spi-setup  ( -- )  spi-irq-init spi-init SPI_EV nvic-enable-irq SPI_ER nvic-enable-irq ;
: spi-test  ( -- )   spi-handle ;


: accel-test  ( -- ) dbg key . spi-setup hex spi->accel-start  ;


