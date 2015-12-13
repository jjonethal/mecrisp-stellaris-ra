\ qspi-flash.fth
\ QSPI_CLK - PE10
\ QSPI_CS  - PE11
\ QSPI_D0  - PE12 
\ QSPI_D1  - PE13
\ QSPI_D2  - PE14
\ QSPI_D3  - PE15


$40021000          constant RCC
$4c RCC +          constant RCC_AHB2ENR
$50 RCC +          constant RCC_AHB3ENR

$48001000          constant GPIOE
GPIOE              constant GPIOE_MODER
$24 GPIOE +        constant GPIOE_AFRH
$10                constant GPIO_IDR
$18                constant GPIO_BSRR
GPIOE GPIO_IDR  +  constant GPIOE_IDR
GPIOE GPIO_BSRR +  constant GPIOE_BSRR
$04 GPIOE +        constant GPIOE_OTYPER

GPIOE              constant q-port            \ qspi base port
q-port GPIO_BSRR + constant q-bsrr            \ qspi bsrr bit set reset register
q-port GPIO_IDR  + constant q-idr             \ qspi input data register
GPIOE #10 +        constant qclk              \ qspi pin definition for clock PE10
GPIOE #11 +        constant qcs               \ qspi pin definition for chip select PE11
GPIOE #12 +        constant qd0               \ qspi pin definition for dq0 PE12
GPIOE #13 +        constant qd1               \ qspi pin definition for dq1 PE13
GPIOE #14 +        constant qd2               \ qspi pin definition for dq2 PE14
GPIOE #15 +        constant qd3               \ qspi pin definition for dq3 PE15

: mode-in  ( pin -- n )  \ input mode for pin gpio_moder
   drop 0 1-foldable inline ;
: mode-out  ( pin -- n )  \ output mode for pin gpio_moder
   $f and 2* 1 swap lshift 1-foldable ; 
: mode-mask  ( pin -- n )  \ the mode mask for pin
   $f and 2* #3 swap lshift 1-foldable ;
: mode-af  ( pin -- af )  \ alternate function mode for 
   $f and 2* #2 swap lshift 1-foldable ;
qclk mode-out 
qcs  mode-out or
qd0  mode-in  or
qd1  mode-in  or
qd2  mode-in  or
qd3  mode-in  or constant q-mode-bb-init      \ input mode for data output for control 
qclk mode-mask 
qcs  mode-mask or
qd0  mode-mask or
qd1  mode-mask or
qd2  mode-mask or
qd3  mode-mask or constant q-mode-mask        \ mode mask for qspi pins
qd0 $f and #1 swap lshift      constant qd0-1 \ bsrr def for qd0-1
qd0 $f and #16 + 1 swap lshift constant qd0-0 \ bsrr def for qd0-0
qd0-0 qd0-1 or                 constant qd0-x \ mask for set+reset qd0
qd1 $f and #1 swap lshift      constant qd1-1 \ bsrr def for qd1-1
qd1 $f and #16 + 1 swap lshift constant qd1-0 \ bsrr def for qd1-0
qd1-0 qd1-1 or                 constant qd1-x \ mask for qd1 set+reset
qclk $f and 1 swap lshift      constant qclk-1 \ bsrr def qspi clk-1
qclk $f and $10000 swap lshift constant qclk-0 \ bsrr def qspi clk-0
qcs $f and 1 swap lshift       constant qcs-1 \ bsrr def qspi chip select 1
qcs $f and $10000 swap lshift  constant qcs-0 \ bsrr def qspi chip select 0
qd0 $f and                     constant q-d-shift# \ shift amound for data nibble in to shift
: qd@  ( -- n )  q-idr @ q-d-shift# rshift $f and ; \ get qspi data pins
: qd1@ ( -- f )  qd1-1 q-idr bit@ ;
: q-bsrr!  ( n -- )  q-bsrr ! ; \ output data via bsrr 
: qclk-1!  ( -- )  qclk-1 q-bsrr ! ; \ set qspi clock 1
: qclk-0!  ( -- )  qclk-0 q-bsrr ! ; \ reset qspi clock
: qcs-0!  ( -- )  qcs-0 q-bsrr ! ; \ set qspi chip select to 0
: qcs-1!  ( -- )  qcs-1 q-bsrr ! ; \ set qspi chip select to 1
: qd0!  ( b -- )  \ output bit to qd0
   qd0-1 swap 0= #16 and lshift q-bsrr ! ;
: qd!  ( n -- )  $f and dup not $f and #16 lshift or q-d-shift# lshift q-bsrr ! ;
: q-bb-1-tx-bit  ( c -- c )  qclk-0! dup $80 and qd0! 2* $FE and qclk-1! ;
: q-bb-1-tx-nibble  ( c -- c )  q-bb-1-tx-bit q-bb-1-tx-bit q-bb-1-tx-bit q-bb-1-tx-bit ;
: q-bb-4-tx-nibble  ( c -- c )  qclk-0! dup qd! qclk-1! 4 lshift ;
: q-bb-4-tx-byte  ( c -- )  q-bb-4-tx-nibble q-bb-4-tx-nibble drop ;
: q-bb-1-tx-byte  ( c -- )  q-bb-1-tx-nibble q-bb-1-tx-nibble drop ;
: q-bb-1-rx-bit  ( n1 -- n2 )  qclk-0! qclk-1! shl qd1@ 1 and or ; 
: q-bb-1-rx-nibble  ( -- c )  0 q-bb-1-rx-bit q-bb-1-rx-bit q-bb-1-rx-bit q-bb-1-rx-bit ;
: q-bb-1-rx-byte  ( -- c )  q-bb-1-rx-nibble 4 lshift q-bb-1-tx-nibble or ;
: q-gpio-bb-init  ( -- )  q-port @ q-mode-mask bic q-mode-bb-init or q-port ! ;

