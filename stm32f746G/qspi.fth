\ qspi.fth
\ N25Q128A13EF840E

\ require util.fth
\ require gpio.fth

\ ***** bitfield utility functions ******
: cnt0   ( m -- b )                      \ count trailing zeros with hw support
   dup negate and 1-
   clz negate #32 + 1-foldable ;
: bits@  ( m adr -- b )                  \ get bitfield at masked position e.g $1234 v ! $f0 v bits@ $3 = . (-1)
   @ over and swap cnt0 rshift ;
: bits!  ( n m adr -- )                  \ set bitfield value n to value at masked position
   >R dup >R cnt0 lshift                 \ shift value to proper position
   R@ and                                \ mask out unrelated bits
   R> not R@ @ and                       \ invert bitmask and maskout new bits in current value
   or r> ! ;                             \ apply value and store back
                                         \ example :
                                         \   RCC_PLLCFGR.PLLN = 400 -> #400 $1FF #6 lshift RCC_PLLCFGR bits!
                                         \ PLLN: bit[14:6] -> mask :$1FF << 6 = $7FC0
                                         \ #400 $7FC0 RCC_PLLCFGR bits!
                                         \ $1FF #6 lshift constant PLLN
                                         \ #400 PLLN RCC_PLLCFGR bits!


\ QSPI_NCS - PB6  - AF10
\ QSPI_CLK - PB2  - AF9
\ QSPI_D0  - PD11 - AF9
\ QSPI_D1  - PD12 - AF9
\ QSPI_D2  - PE2  - AF9
\ QSPI_D3  - PD13 - AF9

\ ********** qspi driver io ports *******   
 #1 GPIO    constant GPIOB
 #3 GPIO    constant GPIOD
 #4 GPIO    constant GPIOE
 #2 GPIOB + constant PB2
 #6 GPIOB + constant PB6
#11 GPIOD + constant PD11
#12 GPIOD + constant PD12
#13 GPIOD + constant PD13
 #2 GPIOE + constant PE2

PB6  constant QSPI_NCS 
PB2  constant QSPI_CLK 
PD11 constant QSPI_D0
PD12 constant QSPI_D1
PE2  constant QSPI_D2
PD13 constant QSPI_D3

#10 constant AF10
 #9 constant AF9
: qspi-gpio-init-hw ( -- )
   AF10 QSPI_NCS gpio-mode-af! 
   AF9  QSPI_CLK gpio-mode-af!
   AF9  QSPI_D0  gpio-mode-af!
   AF9  QSPI_D1  gpio-mode-af!
   AF9  QSPI_D2  gpio-mode-af!
   AF9  QSPI_D3  gpio-mode-af! ;
: qspi-gpio-init-sw ( -- )
   QSPI_NCS 1 gpio-mode!
   QSPI_CLK 1 gpio-mode!
   QSPI_D0  1 gpio-mode!
   QSPI_D1  1 gpio-mode! 
   QSPI_D2  1 gpio-mode!
   QSPI_D3  1 gpio-mode! ;
: pin-off  ( pin -- m a )                \ generate pin of mask and bsrr address
   dup bsrr-off swap gpio-bsrr 1-foldable ;
: pin-on  ( pin -- m a )                 \ generate pin of mask and bsrr address
   dup bsrr-on swap gpio-bsrr 1-foldable ;
: pin-onff  ( pin -- m )                 \ pin-on but address and mask swapped
   bsrr-on dup #16 lshift or 1-foldable ;
: pin-in  ( pin -- m a )                 \ generate pin input mask and address
   dup pin# 2^ swap gpio-idr ;
: on-off ( f -- n ) 0= #16 and 1-foldable inline ;
: q-cs-0  ( -- )  QSPI_NCS pin-off ! ;   \ qspi chip select 0
: q-cs-1  ( -- )  QSPI_NCS pin-on  ! ;   \ qspi chip select 1
: q-ck-0  ( -- )  QSPI_CLK pin-off ! ;   \ qspi clock line 0
: q-ck-1  ( -- )  QSPI_CLK pin-on  ! ;   \ qspi clock line 1
: q-d0-0  ( -- )  QSPI_D0  pin-off ! ;   \ qspi D0 line 0
: q-d0-1  ( -- )  QSPI_D0  pin-on  ! ;   \ qspi D0 line 1
: q-d1-0  ( -- )  QSPI_D1  pin-off ! ;   \ qspi D1 line 0
: q-d1-1  ( -- )  QSPI_D1  pin-on  ! ;   \ qspi D1 line 1
: q-d2-0  ( -- )  QSPI_D2  pin-off ! ;   \ qspi D2 line 0
: q-d2-1  ( -- )  QSPI_D2  pin-on  ! ;   \ qspi D2 line 1
: q-d3-0  ( -- )  QSPI_D3  pin-off ! ;   \ qspi D3 line 0
: q-d3-1  ( -- )  QSPI_D3  pin-on  ! ;   \ qspi D3 line 1

: q-cs@  ( -- f )                        \ get qspi chip select
   QSPI_NCS pin# 2^ QSPI_NCS gpio-idr bit@ ;
: q-ck@  ( -- f )                        \ get qspi clock line
   QSPI_CLK pin# 2^ QSPI_CLK gpio-idr bit@ ;
: q-d0@  ( -- f )                        \ get qspi D0 line
   QSPI_D0 pin# 2^ QSPI_D0 gpio-idr bit@ ;
: q-d1@  ( -- f )                        \ get qspi D1 line
   QSPI_D1 pin# 2^ QSPI_D1 gpio-idr bit@ ;
: q-d2@  ( -- f )                        \ get qspi D2 line
   QSPI_D2 pin# 2^ QSPI_D2 gpio-idr bit@ ;
: q-d3@  ( -- f )                        \ get qspi D3 line
   QSPI_D3 pin# 2^ QSPI_D3 gpio-idr bit@ ;

: q-cs!  ( f -- )                        \ set qspi chip select
   0= $FFFF xor QSPI_NCS pin-onff and QSPI_NCS gpio-bsrr ! ;
: q-ck!  ( f -- )                        \ set qspi clock line
   0= $FFFF xor QSPI_CLK pin-onff and QSPI_CLK gpio-bsrr ! ;
: q-d0!  ( f -- )                        \ set qspi D0 line
   0= $FFFF xor QSPI_D0 pin-onff and QSPI_D0 gpio-bsrr ! ;
: q-d1!  ( f -- )                        \ set qspi D1 line
   0= $FFFF xor QSPI_D1 pin-onff and QSPI_D1 gpio-bsrr ! ;
: q-d2!  ( f -- )                        \ set qspi D2 line
   0= $FFFF xor QSPI_D2 pin-onff and QSPI_D2 gpio-bsrr ! ;
: q-d3!  ( f -- )                        \ set qspi D3 line
   0= $FFFF xor QSPI_D3 pin-onff and QSPI_D3 gpio-bsrr ! ;

: q-set-mode-bb1  ( -- )                 \ setup one wire bit bang spi mode
   q-cs-1 QSPI_NCS gpio-output
   q-ck-0 QSPI_CLK gpio-output
   q-d0-0 QSPI_D0  gpio-output 
   q-d1-1 QSPI_D1  gpio-input
   q-d2-1 QSPI_D2  gpio-output           \  /W    - no write protect
   q-d3-1 QSPI_D3  gpio-output ;         \  /HOLD - no hold 


