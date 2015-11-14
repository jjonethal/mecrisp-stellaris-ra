\ clock switching for stm32l476
\ Author 2015 Jean Jonethal
\ 

$40021000 constant RCC
$0 RCC + constant RCC_CR                      \ Clock control register
 1 #29 lshift constant RCC_CR_PLLSAI2RDY      \ SAI2 PLL clock ready flag
 1 #28 lshift constant RCC_CR_PLLSAI2ON       \ SAI2 PLL enable
 1 #27 lshift constant RCC_CR_PLLSAI1RDY      \ SAI1 PLL clock ready flag
 1 #26 lshift constant RCC_CR_PLLSAI1ON       \ SAI1 PLL enable
 1 #25 lshift constant RCC_CR_PLLRDY          \ Main PLL clock ready flag
 1 #24 lshift constant RCC_CR_PLLON           \ Main PLL enable
 1 #19 lshift constant RCC_CR_CSSON           \ Clock security system enable
 1 #18 lshift constant RCC_CR_HSEBYP          \ HSE crystal oscillator bypass
 1 #17 lshift constant RCC_CR_HSERDY          \ HSE clock ready flag
 1 #16 lshift constant RCC_CR_HSEON           \ HSE clock enable
 1 #11 lshift constant RCC_CR_HSIASFS         \ HSI16 automatic start from Stop
 1 #10 lshift constant RCC_CR_HSIRDY          \ HSI16 clock ready flag
 1  #9 lshift constant RCC_CR_HSIKERON        \ HSI16 always enable for peripheral kernels.
 1  #8 lshift constant RCC_CR_HSION           \ HSI clock enable
$f  #4 lshift constant RCC_CR_MSIRANGE        \ MSI clock ranges 
 1  #3 lshift constant RCC_CR_MSIRGSEL        \ MSI clock range selection
 1  #2 lshift constant RCC_CR_MSIPLLEN        \ MSI clock PLL enable
 1  #1 lshift constant RCC_CR_MSIRDY          \ MSI clock ready flag
 1  #0 lshift constant RCC_CR_MSION           \ MSI clock enable

$8 RCC +       constant RCC_CFGR              \ Clock configuration register
$3 2 lshift    constant RCC_CFGR_SWS          \ System clock switch status 00:MSI 01:HSI 10:HSE 11:PLL
$3             constant RCC_CFGR_SW           \ System clock switch 00:MSI 01:HSI 10:HSE 11:PLL

: hsi-on  ( -- )  RCC_CR_HSION RCC_CR bis! ;  \ turn hsi on
: hsi-off  ( -- )  RCC_CR_HSION RCC_CR bic! ; \ turn hsi on
: hsi-on?  ( -- f )                           \ is hsi on ?
   RCC_CR_HSIRDY RCC_CR bit@ ;
: wait-hsi  ( -- )                            \ turn on hsi wait until ready
   hsi-on begin hsi-on? until ;
: sys-clk-hsi  ( -- )
  1 RCC_CFGR_SW RCC_CFGR bits! ;
: msi-on  ( -- )
   RCC_CR_MSION RCC_CR bis! ;
: msi-off  ( -- )
   RCC_CR_MSION RCC_CR bic! ;
: msi-on?  ( -- f )
   RCC_CR_MSIRDY RCC_CR bit@ ;
: wait-msi  ( -- )
   msi-on  begin msi-on? until ;
: sys-clk-msi  ( -- )
  2 RCC_CFGR_SW RCC_CFGR bits! ;
   
\ ********** flash registers *****************
$40022000      constant FLASH_BASE
0 FLASH_BASE + constant FLASH_ACR 
$7             constant FLASH_ACR_LATENCY     \ 0-4 wait states other invalid
: flash-latency-vs1-48 ( -- )                 \ 2 WS at 48 MHZ
   2 FLASH_ACR_LATENCY FLASH_ACR bits! ;
: flash-latency-vs1-16 ( -- )                 \ 0 WS at 16 MHZ
   0 FLASH_ACR_LATENCY FLASH_ACR bits! ;

\ ********** power registers *****************
$40007000      constant PWR_BASE
0  PWR_BASE +  constant PWR_CR1               \ Power control register 1
#3 9 lshift    constant PWR_CR1_VOS           \ 1:Range 1 2:range2 0:invalid 3:invalid

$14 PWR_BASE + constant PWR_SR2               \ Power status register 2
1 #10 lshift   constant PWR_SR2_VOSF          \ Voltage scaling flag 0: voltage ready 1: voltage changing

\ ********** usart registers *****************
$40004400          constant USART2
$0                 constant USART_CR1
1                  constant USART_CR1_UE
$C                 constant USART_BRR
USART_CR1 USART2 + constant USART2_CR1
: VOSF?  ( -- f )                             \ voltage change pending
   PWR_SR2_VOSF PWR_SR2 bit@ ;
: voltage-scale-1  ( -- )                     \ voltage scaling 1
   1 PWR_CR1_VOS PWR_CR1 bits! ;
: voltage-scale-2  ( -- )                     \ voltage scaling 2
   2 PWR_CR1_VOS PWR_CR1 bits! ;
: wait-voltage-scale-1  ( -- )
   voltage-scale-1 begin VOSF? not until ;
: wait-voltage-scale-2  ( -- )
   voltage-scale-2 begin VOSF? not until ;
: usart-baud-115200-48MHz  ( -- )
   USART_CR1_UE USART2_CR1 bits@
   #48000000 #115200 2/ + #115200 /
   USART_BRR USART2 + !
   USART_CR1_UE USART2_CR1 bits! ;
: usart-baud-460800-48MHz  ( -- )
   USART_CR1_UE USART2_CR1 bits@
   #48000000 #460800 2/ + #460800 /
   USART_BRR USART2 + !
   USART_CR1_UE USART2_CR1 bits! ;
: usart-baud-230400-48MHz  ( -- )
   USART_CR1_UE USART2_CR1 bits@
   #48000000 #230400 2/ + #230400 /
   USART_BRR USART2 + !
   USART_CR1_UE USART2_CR1 bits! ;
: usart-baud-115200-16MHz  ( -- )
   USART_CR1_UE USART2_CR1 bits@              \ save uart state
   #16000000 #115200 2/ + #115200 /  
   USART_BRR USART2 + !
   USART_CR1_UE USART2_CR1 bits! ;            \ resore usart state
: usart-baud-hz  ( baud hz -- )               \ set baudrate for usart2
   USART_CR1_UE USART2_CR1 bits@ >R           \ save uart state
   over 2/ + swap /                           \ ( hz + baud / 2 ) / baud
   USART_BRR USART2 + !
   R> USART_CR1_UE USART2_CR1 bits! ;         \ restore uart state
: clk-src-hsi  ( -- )
   hsi-on 1 RCC_CFGR_SW RCC_CFGR bits! ;
: clk-src-msi  ( -- )
   msi-on 0 RCC_CFGR_SW RCC_CFGR bits! ;
: 16-mhz-hsi  ( -- )                          \ 16 mhz hsi mode
   hsi-on
   voltage-scale-1
   flash-latency-vs1-16
   wait-hsi sys-clk-hsi
   usart-baud-115200-16MHz  ;
: 48-mhz-msi  ( -- )                          \ 48 mhz msi mode
   hsi-on
   voltage-scale-1
   flash-latency-vs1-48
   wait-voltage-scale-1
   wait-hsi sys-clk-hsi
   msi-off
   $B RCC_CR_MSIRANGE RCC_CR bits!
   1 RCC_CR_MSIRGSEL RCC_CR bits!
   wait-msi clk-src-msi
   usart-baud-115200-48MHz  ;   
: 16-mhz-msi  ( -- )                          \ 16 mhz msi mode 
   hsi-on
   voltage-scale-1
   flash-latency-vs1-16
   wait-voltage-scale-1
   wait-hsi sys-clk-hsi
   msi-off
   $8 RCC_CR_MSIRANGE RCC_CR bits!
   1 RCC_CR_MSIRGSEL RCC_CR bits!
   wait-msi clk-src-msi
   usart-baud-115200-16MHz  ;   
: 48-mhz-msi-no-hsi  ( -- )                          \ 48 mhz msi mode
   voltage-scale-1
   flash-latency-vs1-48
   wait-voltage-scale-1
   $B RCC_CR_MSIRANGE RCC_CR bits!
   1 RCC_CR_MSIRGSEL RCC_CR bits!
   usart-baud-115200-48MHz  ;   
