\ qspi-flash.fth
\ QSPI_CLK - PE10
\ QSPI_CS  - PE11
\ QSPI_D0  - PE12 
\ QSPI_D1  - PE13
\ QSPI_D2  - PE14
\ QSPI_D3  - PE15
\ 
\ N25Q128A commands "C:\Users\jeanjo\Downloads\stm\n25q_128mb_3v_65nm.pdf"

$66 constant Q_CMD_RESET_ENABLE
$99 constant Q_CMD_RESET_MEMORY
$9E constant Q_CMD_READ_ID
$AF constant Q_CMD_MULTIPLE_I/O_READ_ID
$5A constant Q_CMD_READ_SERIAL_FLASH_DISCOVERY_PARAM
$03 constant Q_CMD_READ
$0B constant Q_CMD_FAST_READ
$3B constant Q_CMD_DUAL_OUTPUT_FAST_READ
$0B constant Q_CMD_DUAL_INPUT/OUTPUT_FAST_READ
$6B constant Q_CMD_QUAD_OUTPUT_FAST_READ
$0B constant Q_CMD_QUAD_INPUT/OUTPUT_FAST_READ
$06 constant Q_CMD_WRITE_ENABLE
$04 constant Q_CMD_WRITE_DISABLE
$05 constant Q_CMD_READ_STATUS_REGISTER
$01 constant Q_CMD_WRITE_STATUS_REGISTER
$E8 constant Q_CMD_READ_LOCK_REGISTER
$E5 constant Q_CMD_WRITE_LOCK_REGISTER
$70 constant Q_CMD_READ_FLAG_STATUS_REGISTER
$50 constant Q_CMD_CLEAR_FLAG_STATUS_REGISTER
$B5 constant Q_CMD_READ_NONVOLATILE_CONFIGURATION_REGISTER
$B1 constant Q_CMD_WRITE_NONVOLATILE_CONFIGURATION_REGISTER
$85 constant Q_CMD_READ_VOLATILE_CONFIGURATION_REGISTER
$81 constant Q_CMD_WRITE_VOLATILE_CONFIGURATION_REGISTER
$65 constant Q_CMD_READ_ENHANCED_VOLATILE_CONFIGURATION_REGISTER
$61 constant Q_CMD_WRITE_ENHANCED_VOLATILE_CONFIGURATION_REGISTER
$02 constant Q_CMD_PAGE_PROGRAM
$A2 constant Q_CMD_DUAL_INPUT_FAST_PROGRAM
$A2 constant Q_CMD_EXTENDED_DUAL_INPUT_FAST_PROGRAM
$32 constant Q_CMD_QUAD_INPUT_FAST_PROGRAM
$12 constant Q_CMD_EXTENDED_QUAD_INPUT_FAST_PROGRAM
$20 constant Q_CMD_SUBSECTOR_ERASE
$D8 constant Q_CMD_SECTOR_ERASE
$C7 constant Q_CMD_BULK_ERASE
$7A constant Q_CMD_PROGRAM/ERASE_RESUME
$75 constant Q_CMD_PROGRAM/ERASE_SUSPEND
$4B constant Q_CMD_READ_OTP_ARRAY
$42 constant Q_CMD_PROGRAM_OTP_ARRAY

$40021000 constant RCC
$4c RCC + constant RCC_AHB2ENR
$50 RCC + constant RCC_AHB3ENR


\ qspi registers
$A0001000      constant QSPI_BASE
$0 QSPI_BASE + constant QUADSPI_CR            \
1              constant QUADSPI_CR_EN         \ Enable
$4 QSPI_BASE + constant QUADSPI_DCR           \ device configuration register
$1f #16 lshift constant QUADSPI_DCR_FSIZE     \ Flash memory size
$7   #8 lshift constant QUADSPI_DCR_CSHT      \ Chip select high time 0:1cycle ... 7:8 cycles
$1             constant QUADSPI_DCR_CKMODE    \ clock Mode 0 / 3

$8 QSPI_BASE + constant QUADSPI_SR            \ status register
$1f #8 lshift  constant QUADSPI_SR_FLEVEL     \ FIFO level
1   #5 lshift  constant QUADSPI_SR_BUSY       \ Busy
1   #4 lshift  constant QUADSPI_SR_TOF        \ Timeout flag
1   #3 lshift  constant QUADSPI_SR_SMF        \ Status match flag
1   #2 lshift  constant QUADSPI_SR_FTF        \ FIFO threshold flag
1   #1 lshift  constant QUADSPI_SR_TCF        \ Transfer complete flag
1   #0 lshift  constant QUADSPI_SR_TEF        \ Transfer error flag

$c QSPI_BASE + constant QUADSPI_FCR           \ flag clear register
1   #4 lshift  constant QUADSPI_FCR_CTOF      \ Clear timeout flag
1   #3 lshift  constant QUADSPI_FCR_CSMF      \ Clear status match flag
1   #1 lshift  constant QUADSPI_FCR_CTCF      \ Clear transfer complete flag
1   #0 lshift  constant QUADSPI_FCR_CTEF      \ Clear transfer error flag

$10 QSPI_BASE + constant QUADSPI_DLR          \ data length register 0:1 byte, 0xFFFF_FFFE: 4g-1, -1 is special

$14 QSPI_BASE + constant QUADSPI_CCR          \ communication configuration register
$1  #31 lshift  constant QUADSPI_CCR_DDRM     \ Double data rate mode
$1  #28 lshift  constant QUADSPI_CCR_SIOO     \ Send instruction only once mode
$3  #26 lshift  constant QUADSPI_CCR_FMODE    \ Functional mode 0:ind.write 1:ind.read 2:auto-poll 3:mem-map
$3  #24 lshift  constant QUADSPI_CCR_DMODE    \ Data mode 0:no data 1:1 line 2:2 line 3:4 line
$1f #18 lshift  constant QUADSPI_CCR_DCYC     \ Number of dummy cycles 0-31
$3  #16 lshift  constant QUADSPI_CCR_ABSIZE   \ Alternate bytes size 0:8bit 1:16bit 2:24bit 3:32bit
$3  #14 lshift  constant QUADSPI_CCR_ABMODE   \ Alternate bytes mode 0:no 1:1 line 2:2 line 3:4 line
$3  #12 lshift  constant QUADSPI_CCR_ADSIZE   \ Address size 0:8bit 1:16bit 2:24bit 3:32bit
$3  #10 lshift  constant QUADSPI_CCR_ADMODE   \ Address mode 0:no 1:1 line 2:2 line 3:4 line
$3   #8 lshift  constant QUADSPI_CCR_IMODE    \ Instruction mode 0:no 1:1 line 2:2 line 3:4 line
$FF             constant QUADSPI_CCR_INSTRUCTION \ Instruction

$18 QSPI_BASE + constant QUADSPI_AR           \ address register
$1C QSPI_BASE + constant QUADSPI_ABR          \ Alternate Bytes
$20 QSPI_BASE + constant QUADSPI_DR           \ data register
$24 QSPI_BASE + constant QUADSPI_PSMKR        \ polling status mask register
$28 QSPI_BASE + constant QUADSPI_PSMAR        \ polling status match register
$2C QSPI_BASE + constant QUADSPI_PIR          \ polling interval register
$FFFF           constant QUADSPI_PIR_INTERVAL \ Polling interval
$30 QSPI_BASE + constant QUADSPI_LPTR         \ low-power timeout register
$FFFF           constant QUADSPI_LPTR_TIMEOUT \ Timeout period

\ bitfield utility functions 
: cnt0   ( m -- b )                           \ count trailing zeros with hw support
   dup negate and 1-
   clz negate #32 + 1-foldable ;
: bits@  ( m adr -- b )                       \ get bitfield at masked position e.g $1234 v ! $f0 v bits@ $3 = . (-1)
   @ over and swap cnt0 rshift ;
: bits!  ( n m adr -- )                       \ set bitfield at position $1234 v ! $5 $f00 v bits! v @ $1534 = . (-1)
   >R dup >R cnt0 lshift                      \ shift value to proper pos
   R@ and                                     \ mask out unrelated bits
   R> not R@ @ and                            \ invert bitmask and makout new bits
   or r> ! ;                                  \ apply value and store back

$48001000   constant GPIOE
GPIOE       constant GPIOE_MODER
$24 GPIOE + constant GPIOE_AFRH




: gpioe-clock-ena  (  -- )                    \ enable gpioe clock
   1 4 lshift RCC_AHB2ENR bis! ;
: qspi-clock-ena  ( -- )                      \ enable qspi clock
   1 8 lshift RCC_AHB3ENR bis! ;
: gpioe-qspi  ( -- )
   GPIOE_MODER @ $FFF00000 not and            \ AF mode PE15:10
   $AAA00000 or GPIOE_MODER !
   GPIOE_AFRH @ $FF and                       \ AR10 mode PE15:10
   $AAAAAA00 or GPIOE_AFRH ! ;
: qspi-fsize! ( flash-size -- )
    QUADSPI_DCR_FSIZE QUADSPI_DCR bits! ;
: qspi-ckmode! ( f -- )
   QUADSPI_DCR_CKMODE QUADSPI_DCR bits! ;
: qspi-busy? ( -- f )
   QUADSPI_SR_BUSY QUADSPI_SR bit@ ;
: q-ena ( -- )
   QUADSPI_CR_EN QUADSPI_CR bis! ;
: qspi_csht!  ( n -- )
   QUADSPI_DCR_CSHT QUADSPI_DCR bits! ;
: qspi-init ( -- )
   gpioe-clock-ena
   qspi-clock-ena
   gpioe-qspi
   #23 qspi-fsize!
   0 qspi-ckmode! ;
: qspi-fifo-level# ( -- n )
  QUADSPI_SR @ 8 rshift $1f and ;
: q-c@ ( -- c )
   qspi-fifo-level# 0=
   QUADSPI_DR c@ $ff and or ;
: q-i-mode! ( n -- )
   QUADSPI_CCR_IMODE QUADSPI_CCR bits! ;
: q-ad-mode! ( n -- )
   QUADSPI_CCR_ADMODE QUADSPI_CCR bits! ; 
: q-ab-mode! ( n -- )
   QUADSPI_CCR_ABMODE QUADSPI_CCR bits! ;
: q-f-mode!  ( n -- )
   QUADSPI_CCR_FMODE QUADSPI_CCR bits! ;
: q-dummy!  ( n -- )
   QUADSPI_CCR_DCYC QUADSPI_CCR bits! ;
: q-datalength! ( n -- )
   1- QUADSPI_DLR ! ;

1 #26 lshift     \ fmode indirect read
1 #24 lshift or  \ dmode single line
1  #8 lshift or  \ imode single line
constant qspi-single-line-read

: read-fifo ( -- ) 
  begin  qspi-fifo-level# 0<> if q-c@ . then
  qspi-busy? not until ;
: q-read ( fkt len -- ) q-datalength! qspi-single-line-read  or QUADSPI_CCR !
   read-fifo  ;
: t qspi-init q-ena Q_CMD_READ_ID 20 q-read ;

\ QSPI_CLK - PE10
\ QSPI_CS  - PE11
\ QSPI_D0  - PE12 
\ QSPI_D1  - PE13
\ QSPI_D2  - PE14
\ QSPI_D3  - PE15

: output ( pin -- )
   1 swap dup $f and 2* 3 swap lshift swap $f not and bits! ;
: input ( pin -- )
   0 swap dup $f and 2* 3 swap lshift swap $f not and bits! ;
: push-pull ( pin -- )
   0 swap dup $f and 1 swap lshift swap $f not and $4 + bits! ;
: open-drain ( pin -- )
   1 swap dup $f and 1 swap lshift swap $f not and $4 + bits! ;
GPIOE #10 + constant qclk
GPIOE #11 + constant qcs
GPIOE #12 + constant qd0
GPIOE #13 + constant qd1
GPIOE #14 + constant qd2
GPIOE #15 + constant qd3

: qd0@ ( -- f )
   qd0 $f and 1 swap lshift qd0 $f not and $10 + bit@ ;
: qd1@ ( -- f )
   qd1 $f and 1 swap lshift qd1 $f not and $10 + bit@ ;
: qd2@ ( -- f )
   qd2 $f and 1 swap lshift qd2 $f not and $10 + bit@ ;
: qd3@ ( -- f )
   qd3 $f and 1 swap lshift qd3 $f not and $10 + bit@ ;
: qcs@ ( -- f )
   qcs $f and 1 swap lshift qcs $f not and $10 + bit@ ;
: qclk@ ( -- f )
   qclk $f and 1 swap lshift qclk $f not and $10 + bit@ ;
: qd0-1 ( )
   1 qd0 $f and lshift qd0 $f not and $18 + ! ;   
: qd1-1 ( )
   1 qd1 $f and lshift qd1 $f not and $18 + ! ;   
: qd2-1 ( )
   1 qd2 $f and lshift qd2 $f not and $18 + ! ;   
: qd3-1 ( )
   1 qd3 $f and lshift qd3 $f not and $18 + ! ;   
: qcs-1 ( )
   1 qcs $f and lshift qcs $f not and $18 + ! ;   
: qclk-1 ( )
   1 qclk $f and lshift qclk $f not and $18 + ! ;   
: qd0-0 ( )
   1 qd0 $f and 16 + lshift qd0 $f not and $18 + ! ;   
: qd1-0 ( )
   1 qd1 $f and 16 + lshift qd1 $f not and $18 + ! ;   
: qd2-0 ( )
   1 qd2 $f and 16 + lshift qd2 $f not and $18 + ! ;   
: qd3-0 ( )
   1 qd3 $f and 16 + lshift qd3 $f not and $18 + ! ;   
: qcs-0 ( )
   1 qcs $f and 16 + lshift qcs $f not and $18 + ! ;   
: qclk-0 ( )
   1 qclk $f and 16 + lshift qclk $f not and $18 + ! ;
: qd0! ( f )
   if qd0-1 else qd0-0 then ;   
: qd1! ( f )
   if qd1-1 else qd1-0 then ;   
: qd2! ( f )
   if qd2-1 else qd2-0 then ;   
: qd3! ( f )
   if qd3-1 else qd3-0 then ;   
: qcs! ( f )
   if qcs-1 else qcs-0 then ;   
: qclk! ( f )
   if qclk-1 else qclk-0 then ;   

: poll-init ( )
  qd3 output
  qd2 output
  qd0 output
  qd1 input
  qcs output
  qclk output
  qd3-1
  qd2-1 ;
: b0 1 and ;
: q. cr
 ." cs " qcs@ b0 .  
 ." clk " qclk@ b0 .  
 ." d0 " qd0@ b0 .  
 ." d1 " qd1@ b0 .  
 ." d2 " qd2@ b0 .  
 ." d3 " qd3@ b0 .  cr ;

: q-idle qcs-1 qclk-0 ;
0 variable xb
0 variable rxb
0 variable bitsel
: tx-byte ( c -- ) xb ! q-idle ." idle " q.
   $80 bitsel !
   xb @ bitsel @ and qd0! ." p0 " q.
   qcs-0 q. ;
: nb
   qclk-1  q.  \ msb-/
   qclk-0  q.  \ msb-\
   bitsel @ shr bitsel ! 
   xb @ bitsel @ and qd0! ." bitsel " bitsel @ . cr q. ;
: rb  
   qclk-1  q.  \ msb-/
   rxb @ 2* qd1@ 1 and + rxb !
   ." rxb " rxb @ hex. cr
   qclk-0  q.  \ msb-\
; 
 


: clk0 ( -- )


   