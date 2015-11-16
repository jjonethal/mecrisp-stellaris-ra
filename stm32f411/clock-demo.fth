\ clock-demo.fth
\ require bits.fth
\ "E:\stm\DM00105918 NUCLEO stm32f411re datasheet.pdf"
\ "E:\stm\DM00105823 Nucleo stm32f411re user manual.pdf"
\ "E:\stm\DM00046982 PM0214 STM32F3 and STM32F4 Series Cortex-M4 programming manual.pdf"
\ datasheet stm32f411 "E:\stm\DM00115249 STM32F411xC STM32F411xE.pdf"
\ reference manual stm32f411 "E:\stm\DM00119316  RM0383 STM32F411xC_E advanced ARM-based 32-bit MCUs .pdf"

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

#8000000  constant HSE-CLK-HZ                 \ HSE clock - 8 MHz from stlink debugger
#16000000 constant HSI-CLK-HZ                 \ HSI clock - 16 MHz from internal HSI oscillator

\ ********** Register definitions ************
$40023C00 constant FLASH_BASE                 \ base address of flash registers
FLASH_BASE constant FLASH_ACR                 \ Flash access control register
1 #12 lshift constant DCRST                   \ Data cache reset
1 #11 lshift constant ICRST                   \ Instruction cache reset
1 #10 lshift constant DCEN                    \ Data cache enable
1  #9 lshift constant ICEN                    \ Instruction cache enable
1  #8 lshift constant PRFTEN                  \ Prefetch enable
$F           constant LATENCY                 \ Latency 0..15 wait states

$40023800 constant RCC
RCC       constant RCC_CR                     \ clock control register
1  #27 lshift constant PLLI2SRDY              \ PLLI2S clock ready flag
1  #26 lshift constant PLLI2SON               \ PLLI2S enable
1  #25 lshift constant PLLRDY                 \ Main PLL (PLL) clock ready flag
1  #24 lshift constant PLLON                  \ Main PLL enable
1  #19 lshift constant CSSON                  \ Clock security system enable
1  #18 lshift constant HSEBYP                 \ HSE clock bypass
1  #17 lshift constant HSERDY                 \ HSE clock ready flag
1  #16 lshift constant HSEON                  \ HSE clock enable
$FF #8 lshift constant HSICAL                 \ Internal high-speed clock calibration
$F  #3 lshift constant HSITRIM                \ Internal high-speed clock trimming
1   #1 lshift constant HSIRDY                 \ Internal high-speed clock ready flag
1             constant HSION                  \ Internal high-speed clock enable

$4 RCC +  constant RCC_PLLCFGR
$f  #24 lshift constant PLLQ                  \ Main PLL (PLL) division factor USB,SDIO,RNG 2..15
$1  #22 lshift constant PLLSRC                \ PLL and PLLI2S entry clock source 0:HSI 1:HSE
$3  #16 lshift constant PLLP                  \ PLL division factor for main system clock 00:/2 01:/4 10:/6 11:/8 (<= 100 MHz)
$3FF #6 lshift constant PLLN                  \ Main PLL multiplier for VCO 50 .. 432 ( 100 .. 432 MHz)
$3F            constant PLLM                  \ PLL input divider 2..63 ( 1..2 MHz)

$8 RCC +  constant RCC_CFGR
$3  #30 lshift constant MCO2                  \ Microcontroller clock output 2 00:SYSCLK 01:PLLI2S 10:HSE 11:PLL
$7  #27 lshift constant MCO2PRE               \ MCO2 prescaler 0xx:/1 100:/2 101:/3 110:/4 111:/5
$7  #24 lshift constant MCO1PRE               \ MCO1 prescaler 0xx:/1 100:/2 101:/3 110:/4 111:/5
$1  #23 lshift constant I2SSRC                \ I2S clock selection 0:PLLI2S 1:I2S_CKIN
$3  #21 lshift constant MCO1                  \ Microcontroller clock output 1 00:HSI 01:LSE 10:HSE 11:PLL
$1F #16 lshift constant RTCPRE                \ HSE division factor for RTC clock 00000:off 00001:off 00010:/2 00011:/3 .. 11111:/31
$7  #13 lshift constant PPRE2                 \ APB high speed prescaler (APB2) 0xx:/1 100:/2 101:/4 110:/8 111:/16 ( <= 100 MHz )
$7  #10 lshift constant PPRE1                 \ APB Low  speed prescaler (APB1) 0xx:/1 100:/2 101:/4 110:/8 111:/16 ( <= 50 MHz )
$F   #4 lshift constant HPRE                  \ AHB prescaler 0xxx:/1 1000:/2 1001:/4 1010:/8 1011:/16 1100:/64 1101:/128 1110:/256 1111:/512
$3   #2 lshift constant SWS                   \ System clock switch status 00:HSI 01:HSE 10:PLL 11:not used
$3             constant SW                    \ System clock switch 00:HSI 01:HSE 10:PLL 11:not used

$40004400      constant USART2
$8             constant USART_BRR
$FFFF          constant USART_BRR_DIV

\ **** variables **********************
HSI-CLK-HZ  variable system-clk-hz            \ we start with HSI clock

: hse-ready?   ( -- f )  HSERDY RCC_CR bit@ ;
: hse-on       ( -- )                         \ turn on hse in bypass mode
   HSEBYP RCC_CR bis! HSEON RCC_CR bis!
   begin hse-ready? until ;
: SYS-CLK-HSI  ( -- )    0 SW RCC_CFGR bits! ;
: SYS-CLK-HSE  ( -- )    1 SW RCC_CFGR bits! ;
: SYS-CLK-PLL  ( -- )    2 SW RCC_CFGR bits! ;
: SYS-CLK-SRC  ( -- n )  SWS RCC_CFGR bits@ ;
: PLL-OFF      ( -- )    PLLON RCC_CR bic! ;
: PLL-ON       ( -- )    PLLON RCC_CR bis! ;
: pll-ready?   ( -- f )  PLLRDY RCC_CR bit@ ;
: PLL-ON-WAIT  ( -- )    PLL-ON begin pll-ready? until ;
: PLL-100-HSE  ( -- )                           \ set pll to 200 MHz 100 Mhz system clock 50 MHz usb - not for USB
   1 PLLSRC RCC_PLLCFGR bits!                   \ PLLSRC HSE 8 MHZ
   HSE-CLK-HZ #2000000 / PLLM RCC_PLLCFGR bits! \ 2 MHz pll input frequency
   200 2 / PLLN RCC_PLLCFGR bits!               \ 200 Mhz PLL freq 
   0 PLLP RCC_PLLCFGR bits!                     \ /2 100 MHz pll output frequency
   200 50 / PLLQ RCC_PLLCFGR bits! ;            \ PLL48CK 50 Mhz little bit too much so there is no usb
: PLL-96-HSE  ( -- )                            \ set pll to 192 MHz 96 Mhz system clock 48 MHz usb for USB
   1 PLLSRC RCC_PLLCFGR bits!                   \ PLLSRC HSE 8 MHZ
   HSE-CLK-HZ #2000000 / PLLM RCC_PLLCFGR bits! \ 2 MHz pll input frequency
   192 2 / PLLN RCC_PLLCFGR bits!               \ 192 Mhz PLL freq 
   0 PLLP RCC_PLLCFGR bits!                     \ /2 96 MHz pll output frequency
   192 48 / PLLQ RCC_PLLCFGR bits! ;            \ PLL48CK 48 Mhz
: CACHE-CLEAR-ENA  ( -- )
   DCEN FLASH_ACR bic!
   ICEN FLASH_ACR bic!
   DCRST FLASH_ACR bis!
   ICRST FLASH_ACR bis!
   DCRST FLASH_ACR bic!
   ICRST FLASH_ACR bic!
   DCEN FLASH_ACR bis!
   ICEN FLASH_ACR bis! ;

: FLASH-WS-100MHZ  ( -- )                       \ FLASH settings for 100 MHz 3300 millivolt
   DCRST     FLASH_ACR bic!
   ICRST     FLASH_ACR bic!
   DCEN      FLASH_ACR bis!
   ICEN      FLASH_ACR bis!
   PRFTEN    FLASH_ACR bis!
   3 LATENCY FLASH_ACR bits! ;
: APB1/2  ( -- )  %100 PPRE1 RCC_CFGR bits! ;
: APB2/1  ( -- )  %000 PPRE2 RCC_CFGR bits! ;
: AHB/1   ( -- )  %000 HPRE  RCC_CFGR bits! ;
: USART2_BRR_DIV! ( n -- )                    \ set usart2 brr divider
   USART_BRR_DIV USART_BRR USART2 + bits! ;
: USART2-BAUD-FIX-50MHz ( -- )
   #50000000 #115200 2/ + #115200 / USART2_BRR_DIV! ;
: USART2-BAUD-FIX-48MHz ( -- )
   #48000000 #115200 2/ + #115200 / USART2_BRR_DIV! ;
: MEGA  ( n -- n )  #1000000 * ;
: SYS-CLK-HSE-100-MHZ ( -- )                  \ set system clock to 100 MHz HSE pll source
   HSE-ON SYS-CLK-HSI PLL-OFF
   PLL-100-HSE PLL-ON FLASH-WS-100MHZ 
   APB1/2 APB2/1 AHB/1 USART2-BAUD-FIX-50MHz
   PLL-ON-WAIT SYS-CLK-PLL 100 MEGA system-clk-hz !;
: SYS-CLK-HSE-96-MHZ ( -- )                   \ set system clock to 96 MHz HSE pll source
   HSE-ON SYS-CLK-HSI PLL-OFF
   PLL-100-HSE PLL-ON FLASH-WS-100MHZ 
   APB1/2 APB2/1 AHB/1 USART2-BAUD-FIX-48MHz
   PLL-ON-WAIT SYS-CLK-PLL 96 MEGA system-clk-hz ! ;
