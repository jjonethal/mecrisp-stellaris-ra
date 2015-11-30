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

\ some shorcuts 
Q_CMD_READ_VOLATILE_CONFIGURATION_REGISTER           constant Q_CMD_READ_VCR
Q_CMD_WRITE_VOLATILE_CONFIGURATION_REGISTER          constant Q_CMD_WRITE_VCR
Q_CMD_READ_ENHANCED_VOLATILE_CONFIGURATION_REGISTER  constant Q_CMD_READ_EVCR
Q_CMD_WRITE_ENHANCED_VOLATILE_CONFIGURATION_REGISTER constant Q_CMD_WRITE_EVCR



$40021000 constant RCC
$4c RCC + constant RCC_AHB2ENR
$50 RCC + constant RCC_AHB3ENR


\ qspi registers
$A0001000      constant QSPI_BASE
$0 QSPI_BASE + constant QUADSPI_CR            \
$ff #24 lshift constant QUADSPI_CR_PRESCALER  \ Clock prescaler 0:/1 ... 255:/256
 $1 #23 lshift constant QUADSPI_CR_PMM        \ Polling match mode 0:and 1:or
 $1 #22 lshift constant QUADSPI_CR_APMS       \ Automatic poll mode stop
 $1 #20 lshift constant QUADSPI_CR_TOIE       \ TimeOut interrupt enable
 $1 #19 lshift constant QUADSPI_CR_SMIE       \ Status match interrupt enable
 $1 #18 lshift constant QUADSPI_CR_FTIE       \ FIFO threshold interrupt enable
 $1 #17 lshift constant QUADSPI_CR_TCIE       \ Transfer complete interrupt enable
 $1 #16 lshift constant QUADSPI_CR_TEIE       \ Transfer error interrupt enable
 $f  #8 lshift constant QUADSPI_CR_FTHRES     \ FIFO threshold level
 $1  #4 lshift constant QUADSPI_CR_SSHIFT     \ Sample shift
 $1  #3 lshift constant QUADSPI_CR_TCEN       \ Timeout counter enable
 $1  #2 lshift constant QUADSPI_CR_DMAEN      \ DMA enable
 $1  #1 lshift constant QUADSPI_CR_ABORT      \ Abort request
 $1            constant QUADSPI_CR_EN         \ Enable
$4 QSPI_BASE + constant QUADSPI_DCR           \ device configuration register
$1f #16 lshift constant QUADSPI_DCR_FSIZE     \ Flash memory size (log (byte size)/log(2)) -1
 $7  #8 lshift constant QUADSPI_DCR_CSHT      \ Chip select high time 0:1cycle ... 7:8 cycles
 $1            constant QUADSPI_DCR_CKMODE    \ clock Mode 0 / 3

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
: qspi-fsize! ( flash-size -- )               \ set qspi flash size 
   QUADSPI_DCR_FSIZE QUADSPI_DCR bits! ;
: qspi-prescaler! ( prescaler -- )
   QUADSPI_CR_PRESCALER QUADSPI_CR bits! ;
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
   0 qspi-ckmode!
   #7 qspi_csht!
   #15 qspi-prescaler!
   q-ena ;
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


: SIOO ( v -- v ) #1 #28 lshift or 1-foldable inline ; \ 0:instr. on every transaction 1:instr. on 1st transaction 
: FMODE ( v fm -- v ) #26 lshift or 2-foldable inline ; \ 0:ind write 1:ind read 2:poll 3:memmap
: DMODE ( v dm -- v ) #24 lshift or 2-foldable inline ; \ 0:no 1:1Line 2:2line 3:4line
: DUMMY ( v du -- v ) #18 lshift or 2-foldable inline ; \ 0-31 dummy cycles
: ABSIZE ( v abs -- v ) 8 / 1 - #16 lshift or 2-foldable ; \ 8,16,24,32
: ABMODE ( v abm -- v ) #14 lshift or 2-foldable inline ; \ 0:no 1:1Line 2:2line 3:4line
: ADSIZE ( v ads -- v ) 8 / 1 - #12 lshift or 2-foldable ; \ 8,16,24,32
: ADMODE ( v adm -- v ) #10 lshift or 2-foldable inline ; \ 0:no 1:1Line 2:2line 3:4line
: IMODE  ( v im -- v ) #8 lshift or 2-foldable inline ; \ 0:no 1:1Line 2:2line 3:4line


1 variable qspi-ab-mode                       \ alternate byte mode 1:1-wire 2:2-wire 3:4wire
1 variable qspi-adr-mode                      \ address mode 1:1-wire 2:2-wire 3:4wire
1 variable qspi-cmd-mode                      \ instruction mode 1:1-wire 2:2-wire 3:4wire
1 variable qspi-data-mode                     \ data mode 1:1-wire 2:2-wire 3:4wire
8 variable qspi-dummy#                        \ number of dummy cycles for fast read 8:1-wire 10:4-wire

: qspi-read-reg ( cmd -- n )                  \ compose read register command param depending on mode
   qspi-cmd-mode @ imode 1 fmode qspi-data-mode @ dmode ;
: qspi-write-reg ( cmd -- n )                 \ compose write register command param depending on mode
   qspi-cmd-mode @ imode 0 fmode qspi-data-mode @ dmode ;
: qspi-send-cmd  ( cmd -- n )                 \ compose command depending on mode
   qspi-cmd-mode @ imode 0 fmode ;
: qspi-send-cmd-adr ( cmd -- n )              \ compose command send address and cmd
   qspi-cmd-mode @ imode 0 fmode #24 adsize qspi-adr-mode @ admode ;
: qspi-send-cmd-adr-data ( cmd -- n )         \ compose command send address and cmd
   qspi-cmd-mode @ imode 0 fmode #24 adsize qspi-adr-mode @ admode
   qspi-data-mode @ dmode ;
: qspi-receive-cmd-adr-data ( cmd -- n )      \ compose command send address and cmd
   qspi-cmd-mode @ imode 1 fmode #24 adsize qspi-adr-mode @ admode
   qspi-data-mode @ dmode ;

: q-fifo. ( -- )                              \ dump qspi fifo
  begin qspi-fifo-level# 0<> if q-c@ . then
  qspi-busy? not until ;
: qc-c@ ( -- c )                              \ fetch next byte from fifo
  qspi-busy?
  if
    begin qspi-fifo-level#
    0<> qspi-busy? not or until
    q-c@
  else -1
  then ;
: qc-c! ( c -- )                              \ write byte when fifo has place free
\   qspi-busy? if
      begin qspi-fifo-level# 15 < 
      until QUADSPI_DR c!
\   then
   ;
: q-reg@ ( len cmd -- c1 c2 ... cn )          \ read len bytes from register
   over q-datalength! qspi-read-reg  QUADSPI_CCR !
   0 do qc-c@ loop ;
: q-reg. ( len cmd -- )                       \ dump len bytes from register
   over q-datalength! qspi-read-reg  QUADSPI_CCR !
   0 do qc-c@ . loop ;
: q-reg! ( cn ... c2 c1 len cmd -- )          \ send len bytes to register
   qspi-write-reg QUADSPI_CCR !
   dup q-datalength! 
   0 do qc-c! loop ;
: q-cmd! ( cmd -- )                           \ send cmd
   qspi-send-cmd QUADSPI_CCR ! ;
: q-wr-ena ( -- )                             \ send write enable command
   Q_CMD_WRITE_ENABLE q-cmd! ;
: q-wr-dis ( -- )                             \ send write enable command
   Q_CMD_WRITE_DISABLE q-cmd! ;
: q-id. ( -- )                                \ dump id of qspi chip
   hex qspi-init q-ena #3 Q_CMD_READ_ID q-reg. ;
: q-vcr@ ( -- vcfg )                          \ read volatile configuraton register
   1 Q_CMD_READ_VCR q-reg@ ;
: q-vcr! ( vcfg -- )                          \ write volatile configuration register
   1 Q_CMD_WRITE_VCR q-reg! ;
: q-evcr@ ( -- evcfg )                        \ read extended volatile configuraton register
   1  Q_CMD_READ_EVCR q-reg@ ;
: q-evcr! ( evcfg -- )                        \ write extended volatile configuration register
   1 Q_CMD_WRITE_EVCR q-reg! ;
: q-sr@ ( -- c )                              \ get status register     
  1 Q_CMD_READ_STATUS_REGISTER q-reg@ ;
: q-bsy? ( -- f )                             \ qspi chip busy ?
   q-sr@ 1 and 0<> ;
: q-wait-complete ( -- )                      \ wait until qspi flash chip is ready
   begin q-bsy? not until ;
: q-wr-adr-cmd ( a cmd -- )                   \ initiate send address command 
  q-wr-ena qspi-send-cmd-adr QUADSPI_CCR !
  QUADSPI_AR ! ; \ trigger transfer after address write
: q-erase-sub-sector ( a -- )
  Q_CMD_SUBSECTOR_ERASE q-wr-adr-cmd  q-wait-complete ;
: q-erase-sector ( a -- )
  Q_CMD_SECTOR_ERASE    q-wr-adr-cmd  q-wait-complete ;
: q-program-page ( buffer len adr -- )        \ program one page   
   q-wr-ena Q_CMD_PAGE_PROGRAM qspi-send-cmd-adr-data QUADSPI_CCR !
   QUADSPI_AR ! dup q-datalength!
   0 do dup @ qc-c! 1+ loop q-wait-complete ;
: q-flash! ( w adr -- )                       \ write a word to address
   q-wr-ena Q_CMD_PAGE_PROGRAM
   qspi-send-cmd-adr-data QUADSPI_CCR !
   QUADSPI_AR ! 4 q-datalength!  QUADSPI_DR !
   q-wait-complete ;
: q-dummy-cycles ( -- n )                     \ get current number of dummy cycles
   q-vcr@ #4 rshift $F and ;
: q-wait-idle ( -- )
    begin qspi-busy? not until ;
: q-flash@ ( adr -- w )
   q-wait-idle
   Q_CMD_FAST_READ qspi-receive-cmd-adr-data
   qspi-dummy# @ DUMMY QUADSPI_CCR !
   #4 q-datalength! QUADSPI_AR ! 
   qc-c@ qc-c@ #8 lshift or qc-c@ #16 lshift or qc-c@ #24 lshift or ;
: q-flash-c@ ( adr -- w )
   q-wait-idle 
   Q_CMD_FAST_READ qspi-receive-cmd-adr-data
   qspi-dummy# @ DUMMY QUADSPI_CCR !
   #1 q-datalength! QUADSPI_AR ! 
   qc-c@ ;
: qspi-quad-mode ( -- set quad mode )
   q-wr-ena q-wait-idle
   q-evcr@ q-wait-idle $7F and q-wr-ena q-wait-idle q-evcr! q-wait-idle
   #3 qspi-ab-mode !
   #3 qspi-adr-mode !
   #3 qspi-cmd-mode !
   #3 qspi-data-mode !
   #10 qspi-dummy# ! ;
: qspi-single-mode ( -- set quad mode )
   q-wr-ena q-wait-idle
   q-evcr@ q-wait-idle $80 or q-wr-ena q-wait-idle q-evcr! q-wait-idle
   #1 qspi-ab-mode !
   #1 qspi-adr-mode !
   #1 qspi-cmd-mode !
   #1 qspi-data-mode ! 
   #8 qspi-dummy# ! ;
   
: q-c@ ( adr -- c )                           \ shortcut for q-flash-c@
   q-flash-c@ ;

: u.4 ( u -- ) 0 <# # # # # #> type ;
: u.2 ( u -- ) 0 <# # # #> type ;
: < ( a b -- f ) - 0< 2-foldable inline ;
: > ( a b -- f ) swap - 0< 2-foldable inline ;
: >= ( a b -- f ) - 0< not 2-foldable inline ;
: step. ( n -- )
   dup $FFFF and 0 = if . cr else drop then ;
: c. ( n -- )                                 \ emit printable character or "."
   dup #32 >= and dup #127 < and dup 0= [char] . and or emit ;
: c[]<->c. ( c1 c2 .. cn n -- )               \ reverse output character list
   dup 0 ?do swap >R loop                     \ suffle to return stack
   0 ?do R> c. loop ;                         \ output in reverse order

\ dump memory to terminal
\ 0x00000000 | XX XX .. XX | xx..x 
' c@ variable c@-hook
\ dump memory to terminal
\ 0x00000000 | XX XX .. XX | xx..x 
: gdump-line ( adr n -- )                     \ dump a number of bytes using 'c@ up to 16 to terminal
   #16 min                                    \ max 16 bytes per line
   cr over ( a n a )                          \ start display on new line get address for output
   hex. ( a n )                               \ output address in hex
   [char] | emit space                        \ output separator
   tuck ( n a n )                             \ calc loop limits endadress a+n startaddress a
   tuck ( n n a n )                           \ save n for later shuffeling
   over ( n n a n a )
   + swap ( n n a+n a )                       \ calculate dump end address and swap with start address
   do ( n n )                                 \ loop index is address
     i c@-hook @ execute ( n n c )            \ get address byte
     dup ( n n c c )
     u.2 space ( n n c )                      \ output byte value and space
     swap ( n c n )                           \ and put byte on stack for later text display 
   loop 
   dup ( n c...c n n )                        \ fill remaining space in hex line when n<16
   #16 swap ( n c...c n 16 n )                \ prepare loop counter
   ?do 3 spaces loop ( n c..c n )             \ put 3 spaces for 2 hex digits + limiter
   [char] | emit                              \ put a bar
   0 do >R loop ( n -- ) ( R: -- cc )         \ shuffle char list from stack to return stack
   0 do r> c. loop ;                          \ reverse output char list

: gdump ( adr len 'c@ -- )                    \ dump area
    >R                                        \ move away new c@ handler
   c@-hook @ -rot                             \ save function handle
   base @ -rot hex                            \ switch to hex display
   r> c@-hook !                               \ use new c@ handler
   2dup over + swap                           \ calculate loop end-adr start-adr
   ?do i over gdump-line                      \ address length  
      #16 - #16 +loop                         \ reduce length by 16 increase index address by 16
   2drop                                      \ drop old start and length
   base !                                     \ restore original display base
   c@-hook ! ;                                \ restore c@-hook
: q-dump ( adr len -- )                       \ dump qspi memory from chip address
   ['] q-flash-c@ gdump ;   
: q-dump ( adr len -- )                       \ dump qspi memory from chip address
   c@-hook @ gdump ;   
: q!-test #16 #1024 * #1024 * 0 do 
   i step. i dup q-flash! 4 +loop ;
: qd-key ( adr -- adr f )                     \ key handler for qd next adr & flag:false cont true stop
   key case
     [char] q of -1       endof               \ q-quit
     [char] b of $100 - 0 endof               \ b back 256 bytes
     [char] j of $100 - 0 endof               \ j (vi) back 256 bytes
     [char] k of $100 + 0 endof               \ k next 256 bytes
     #32      of $100 + 0 endof               \ space next 256 bytes
     #13      of $100 + 0 endof               \ carriage return
     -1 swap                                  \ all other keys stop
   endcase ;
: qd ( adr )                                  \ dump qspi mem start from adr
   hex begin dup $100 q-dump qd-key until drop ;
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

: qd0!-t ( f )
   0= $FFFF and 1 + qd0 $f and lshift qd0 $f not and $18 + ! ;
: qd1!-t ( f )
   0= $FFFF and 1 + qd1 $f and lshift qd1 $f not and $18 + ! ;   

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
  gpioe-clock-ena
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
 ." d3 " qd3@ b0 . ;

: q.  ( -- ) dup drop ;

 
: q-idle qcs-1 qclk-0 ;
0 variable txb
0 variable rxb
0 variable bitsel
: tx-byte ( c -- ) txb ! q-idle ." idle " q.
   $80 bitsel !
   txb @ bitsel @ and qd0! ." p0 " q.
   qcs-0 q. ;
: nb ( next bit )
   qclk-1  q.  \ msb-/
   qclk-0  q.  \ msb-\
   bitsel @ shr bitsel ! 
   txb @ bitsel @ and qd0! ." bitsel " bitsel @ . cr q. ;
: rb  
   qclk-1  q.  \ msb-/
   rxb @ 2* qd1@ 1 and + rxb !
   ." rxb " rxb @ hex. cr
   qclk-0  q. ;  \ msb-\  

\ : q. dup drop ( -- ) ;   
   
: tx-byte ( c -- )
   \ dup cr ." send " hex.
   8 0 do dup $80 and qd0! q. shl qclk-1 q. qclk-0 q. loop
   drop ;
: rx-byte ( -- c )
\   ." rx-byte "
   q.
   0
   8 0 do qclk-1 q. shl qd1@ 1 and or  qclk-0 q. loop ;
: xfer-cmd ( c -- )   
   q-idle dup $80 and qd0! qcs-0 q.
   tx-byte ;
: xfer-complete ( -- )
   q-idle ;
: get-id Q_CMD_READ_ID xfer-cmd
   20 0 do i . rx-byte  hex. cr loop
   xfer-complete ;
: get-nvcr ( -- )
   Q_CMD_READ_VOLATILE_CONFIGURATION_REGISTER xfer-cmd
   rx-byte 8 lshift rx-byte or xfer-complete ;
: q-write-enable ( -- )
   Q_CMD_WRITE_ENABLE xfer-cmd xfer-complete ;
: q-write-disable ( -- )
   Q_CMD_WRITE_DISABLE xfer-cmd xfer-complete ;
: q-read-mem ( buffer num a -- ) \ transfer num byte from address to buffer
   $03 xfer-cmd dup #16 rshift $ff and tx-byte 
   dup #8 rshift $ff and tx-byte
   $ff and tx-byte
   0 do rx-byte over i + c! loop 
   xfer-complete drop ;
: q-bb-c@ ( a -- c )
  $03 xfer-cmd
  dup #16 rshift $ff and tx-byte
  dup  #8 rshift $ff and tx-byte
  $ff and tx-byte
  \ .s
  rx-byte q-idle ;
: qdbb ( adr -- )
   poll-init 
   c@-hook @ swap
   ['] q-bb-c@ c@-hook !
   qd c@-hook ! ;
: qdd ( adr -- )
   qspi-init
   c@-hook @ swap
   ['] q-flash-c@ c@-hook !
   qd
   c@-hook ! ;
\ $53C250B fast read 15 dummy 
: q-fast-read  $500250B 14 DUMMY QUADSPI_CCR ! 0 QUADSPI_AR ! ;
: fast-read-1-1-1 $500250B #8 DUMMY QUADSPI_CCR ! ;

$B 1 FMODE 3 DMODE #10 dummy #24 adsize 3 admode 3 imode constant fast-read-4-4-4
$B 1 FMODE 1 DMODE  #8 dummy #24 adsize 1 admode 1 imode constant fast-read-1-1-1

\ test number of dummy cycles
: qq ( dummy ) $500250B swap DUMMY QUADSPI_CCR ! 0 QUADSPI_AR ! 
   begin qspi-fifo-level# 0<> until 
   QUADSPI_DR c@ . ;
   
   