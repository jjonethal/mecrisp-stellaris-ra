\ qspi-flash.fth
\ QSPI_CLK - PE10
\ QSPI_CS  - PE11
\ QSPI_D0  - PE12 
\ QSPI_D1  - PE13
\ QSPI_D2  - PE14
\ QSPI_D3  - PE15
\ 
\ N25Q128A commands "C:\Users\jeanjo\Downloads\stm\n25q_128mb_3v_65nm.pdf"

$40021000 constant RCC
$4c RCC + constant RCC_AHB2ENR
$50 RCC + constant RCC_AHB3ENR

$48001000      constant GPIOE
GPIOE          constant GPIOE_MODER
$24 GPIOE +    constant GPIOE_AFRH
$10 GPIOE +    constant GPIOE_IDR
$18 GPIOE +    constant GPIOE_BSRR

$A0001000       constant QSPI_BASE
$0 QSPI_BASE +  constant QUADSPI_CR
$ff #24 lshift  constant QUADSPI_CR_PRESCALER \ Clock prescaler 0:/1 ... 255:/256
 $1             constant QUADSPI_CR_EN        \ Enable
$10 QSPI_BASE + constant QUADSPI_DLR          \ data length register 0:1 byte, 0xFFFF_FFFE: 4g-1, -1 is special
$14 QSPI_BASE + constant QUADSPI_CCR          \ communication configuration register
$18 QSPI_BASE + constant QUADSPI_AR           \ address register
$1C QSPI_BASE + constant QUADSPI_ABR          \ Alternate Bytes
$20 QSPI_BASE + constant QUADSPI_DR           \ data register
$24 QSPI_BASE + constant QUADSPI_PSMKR        \ polling status mask register
$28 QSPI_BASE + constant QUADSPI_PSMAR        \ polling status match register
$2C QSPI_BASE + constant QUADSPI_PIR          \ polling interval register

GPIOE #10 + constant qclk
GPIOE #11 + constant qcs
GPIOE #12 + constant qd0
GPIOE #13 + constant qd1
GPIOE #14 + constant qd2
GPIOE #15 + constant qd3

$9E constant Q_CMD_READ_ID
: 
: output ( init mask pin -- init mask )
  $f and 2* dup >R #3 swap lshift or
  swap 1 r> lshift or swap 3-foldable ;
: input ( init mask pin -- init mask )
  $f and 2* dup >R #3 swap lshift or 3-foldable ;
: q-csht! ( n -- )
  $7 and 8 lshift QUADSPI_DCR @ $7 #8 lshift bic or QUADSPI_DCR ! ;
: q-csht@ ( -- n )
  QUADSPI_DCR #8 rshift $7 and ;
: q-flash-size! ( n -- )
   $1f and #16 lshift QUADSPI_DCR @ $1f #16 lshift bic or QUADSPI_DCR ! ;
: q-flash-size@ ( -- n )
   QUADSPI_DCR @ #16 rshift $1f and ;
: q-gpio-hw  ( -- )                           \ qspi hw block
   GPIOE_MODER @ $FFF00000 bic                \ AF mode PE15:10
   $AAA00000 or GPIOE_MODER !
   GPIOE_AFRH @ $FFFFFF00 bic                 \ AR10 mode PE15:10
   $AAAAAA00 or GPIOE_AFRH ! ;
: gpioe-clock-ena  (  -- )                    \ enable gpioe clock
   1 4 lshift RCC_AHB2ENR bis! ;
: qspi-clock-ena  ( -- )                      \ enable qspi clock
   1 8 lshift RCC_AHB3ENR bis! ;
: qspi-clock-dis  ( -- )                      \ disable qspi clock
   1 8 lshift RCC_AHB3ENR bic! ;
: qspi-init-hw  ( -- )
   gpioe-clock-ena
   qspi-clock-ena
   qspi-gpio-hw ;
: qspi-init-sw ( -- )
   gpioe-clock-ena
   qspi-clock-ena
   GPIOE
   
: qspi-data-length! ( n -- ) 1- QUADSPI_DLR !;
: qspi-fmode-read ( m -- m ) 1 #26 lshift or ;
: q-fmode-write ( m -- m ) 3 #26 lshift bic ;
: qspi-id. ( -- ) Q_CMD_READ_ID fmode-read QUADSPI_CCR ! 3 data-length!
   qspi-c@ c.x qspi-c@ c.x qspi-c@ c.x ;
: quad-mode ;
: fast-read ;
: flash-xip-ena  ( -- )  vcr@ $f7 and vcr! ;
: xip ( -- ) qspi-xip-ena flash-xip-ena ;
: fast-read-xip-4 ( -- )
   quad-mode xip 
   0 QUADSPI_ABR !
   Q_CMD_FAST_READ SIOO 3 FMODE 3 dmode #8 DCYC 0 absize 3 abmode 2 adsize 3 imode ;
: flash-quad-mode flash-write-ena evcr@ $7f and evcr! ;
: qspi-mem-map-mode
   flash-quad-mode
   qspi-quad-mode ;
: q-read-reg-hw ( n cmd -- n0 n1 nn ) ;
: q-read-reg-bb ( n cmd -- n0 n1 nn ) ;
: q-read-reg ( n cmd -- n0 n1 nn ) ;
: q-write-reg ( nn n1 n0 n cmd -- ) ;
: q-send-cmd ( cmd -- ) ;
: q-mode-hw ( -- ) ;
: q-mode-sw ( -- ) ;