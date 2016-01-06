\ stm32f746g-disco display demo
\ pin allocations
\ B_USER  - PI11 - User button
\ USD_D0  - microsSD card
\ USD_D1  - microsSD card
\ USD_D2  - microsSD card
\ USD_D3  - microsSD card
\ USD_CLK - microSD card clock
\ USD_CMD - microSD
\ USD_DETECT - micro sd-card

#25000000 constant HSE_CLK_HZ
#16000000 constant HSI_CLK_HZ

\ LCD_BL_CTRL - PK3 display led backlight control 0-off 1-on

\ ***** utility functions ***************
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

\ ***** gpio definitions ****************
\ http://www.st.com/web/en/resource/technical/document/reference_manual/DM00124865.pdf#page=195&zoom=auto,67,755
$40020000 constant GPIO-BASE
: gpio ( n -- adr )
   $f and #10 lshift GPIO-BASE or 1-foldable ;
$04         constant GPIO_OTYPER
$08         constant GPIO_OSPEEDR
$18         constant GPIO_BSRR
$20         constant GPIO_AFRL
$24         constant GPIO_AFRH

#0  GPIO    constant GPIOA
#1  GPIO    constant GPIOB
#2  GPIO    constant GPIOC
#3  GPIO    constant GPIOD
#4  GPIO    constant GPIOE
#5  GPIO    constant GPIOF
#6  GPIO    constant GPIOG
#7  GPIO    constant GPIOH
#8  GPIO    constant GPIOI
#9  GPIO    constant GPIOJ
#10 GPIO    constant GPIOK

: pin#  ( pin -- nr )                    \ get pin number from pin
   $f and 1-foldable ;
: port-base  ( pin -- adr )              \ get port base from pin
   $f bic 1-foldable ;
: port# ( pin -- n )                     \ return gpio port number A:0 .. K:10
   #10 rshift $f and 1-foldable ;
: mode-mask  ( pin -- m )
   #3 swap pin# 2* lshift 1-foldable ;
: mode-shift ( mode pin -- mode<< )      \ shift mode by pin number * 2 for gpio_moder
   pin# 2* lshift 2-foldable ;
: set-mask! ( v m a -- )
   tuck @ swap bic rot or swap ! ;
: bsrr-on  ( pin -- v )                  \ gpio_bsrr mask pin on
   pin# 1 swap lshift 1-foldable ;
: bsrr-off  ( pin -- v )                 \ gpio_bsrr mask pin off
   pin# #16 + 1 swap lshift 1-foldable ;
: af-mask  ( pin -- mask )               \ alternate function bitmask
   $7 and #2 lshift $f swap lshift 1-foldable ;
: af-reg  ( pin -- adr )                 \ alternate function register address for pin
   dup $8 and 2/ swap
   port-base GPIO_AFRL + + 1-foldable ;
: af-shift ( af pin -- af )
   pin# #2 lshift swap lshift 2-foldable ;
: gpio-mode! ( mode pin -- )
   tuck mode-shift swap dup
   mode-mask swap port-base set-mask! ;
: mode-af ( af pin -- )
   #2 over gpio-mode!
   tuck af-shift swap dup af-mask swap
   af-reg set-mask! ;

\ ***** Flash read access config ********
$40023C00      constant FLASH_ACR
: flash-ws! ( n -- )                     \ set flash latency
   $f FLASH_ACR bits! ;
: flash-prefetch-ena  ( -- )             \ enable prefetch
   #1 #8 lshift FLASH_ACR bis! ;
: flash-art-ena?  ( -- f )               \ enable ART
   #1 #9 lshift FLASH_ACR bit@ ;
: flash-art-ena  ( -- )                  \ enable ART
   #1 #9 lshift FLASH_ACR bis! ;
: flash-art-dis  ( -- )                  \ enable ART
   #1 #9 lshift FLASH_ACR bic! ;
: flash-art-reset  ( -- )                \ enable ART
   #1 #11 lshift FLASH_ACR bis! ;
: flash-art-unreset  ( -- )              \ enable ART
   #1 #11 lshift FLASH_ACR bic! ;
: flash-art-clear  ( -- )                \ clear art cache
   flash-art-ena?
   flash-art-dis
   flash-art-reset
   flash-art-unreset
   if flash-art-ena then ;

\ ***** rcc definitions *****************
\ http://www.st.com/web/en/resource/technical/document/reference_manual/DM00124865.pdf#page=128&zoom=auto,67,755
$40023800      constant RCC_BASE         \ RCC base address
$00 RCC_BASE + constant RCC_CR           \ RCC clock control register
$1 #18 lshift  constant RCC_CR_HSEBYP    \ HSE clock bypass
$1 #17 lshift  constant RCC_CR_HSERDY    \ HSE clock ready flag
$1 #16 lshift  constant RCC_CR_HSEON     \ HSE clock enable
$1  #1 lshift  constant RCC_CR_HSIRDY    \ Internal high-speed clock ready flag
$1             constant RCC_CR_HSION     \ Internal high-speed clock enable
$04 RCC_BASE + constant RCC_PLLCFGR      \ RCC PLL configuration register
$08 RCC_BASE + constant RCC_CFGR         \ RCC clock configuration register
$20 RCC_BASE + constant RCC_APB1RSTR     \ RCC APB1 peripheral reset register
$30 RCC_BASE + constant RCC_AHB1ENR      \ AHB1 peripheral clock register
$40 RCC_BASE + constant RCC_APB1ENR      \ RCC APB1 peripheral clock enable register
$44 RCC_BASE + constant RCC_APB2ENR      \ APB2 peripheral clock enable register
$88 RCC_BASE + constant RCC_PLLSAICFGR   \ RCC SAI PLL configuration register
$8C RCC_BASE + constant RCC_DKCFGR1      \ RCC dedicated clocks configuration register
$90 RCC_BASE + constant RCC_DKCFGR2      \ RCC dedicated clocks configuration register

$0             constant PLLP/2
$1             constant PLLP/4
$2             constant PLLP/6
$3             constant PLLP/8

$0             constant PPRE/1
$4             constant PPRE/2
$5             constant PPRE/4
$6             constant PPRE/8
$7             constant PPRE/16

$0             constant HPRE/1
$8             constant HPRE/2
$9             constant HPRE/4
$A             constant HPRE/8
$B             constant HPRE/16
$C             constant HPRE/64
$D             constant HPRE/128
$E             constant HPRE/256
$F             constant HPRE/512

$0             constant PLLSAI-DIVR/2
$1             constant PLLSAI-DIVR/4
$2             constant PLLSAI-DIVR/8
$3             constant PLLSAI-DIVR/16


\ ***** rcc words ***********************
: rcc-gpio-clk-on  ( n -- )              \ enable single gpio port clock
  1 swap lshift RCC_AHB1ENR bis! ;
: rcc-gpio-clk-off  ( n -- )             \ enable gpio port n clock 0:GPIOA..10:GPIOK
  1 swap lshift RCC_AHB1ENR bic! ;
: rcc-ltdc-clk-on ( -- )                 \ turn on lcd controller clock
   #1 #26 lshift RCC_APB2ENR bis! ;
: rcc-ltdc-clk-off  ( -- )               \ tun off lcd controller clock
   #1 #26 lshift RCC_APB2ENR bic! ;
: hse-on  ( -- )                         \ turn on hsi
   RCC_CR_HSEON RCC_CR bis! ;
: hse-stable?  ( -- f )                  \ hsi running ?
   RCC_CR_HSERDY RCC_CR bit@ ;
: hse-wait-stable  ( -- )                \ turn on hsi wait until stable
   begin hse-on hse-stable? until ;
: hse-off  ( -- )                        \ turn off hse
   RCC_CR_HSEON RCC_CR bic! ;
: hse-byp-on  ( -- )                     \ turn on HSE bypass mode
   RCC_CR_HSEBYP RCC_CR bis! ;
: hsi-on  ( -- )                         \ turn on hsi
   RCC_CR_HSION RCC_CR bis! ;
: hsi-stable?  ( -- f )                  \ hsi running ?
   RCC_CR_HSIRDY RCC_CR bit@ ;
: hsi-wait-stable  ( -- )                \ turn on hsi wait until stable
   hsi-on begin hsi-stable? until ;
: clk-source-hsi  ( -- )                 \ set system clock to hsi clock
   RCC_CFGR dup @ $3 bic swap ! ;
: clk-source-hse  ( -- )                 \ set system clock to hse clock
   #1 #3 RCC_CFGR bits! ;
: clk-source-pll  ( -- )                 \ set system clock to pll clock
   #2 #3 RCC_CFGR bits! ;
: pll-off  ( -- )                        \ turn off main pll
   #1 #24 lshift RCC_CR bic! ;
: pll-on  ( -- )                         \ turn on main pll
   #1 #24 lshift RCC_CR bis! ;
: pll-ready?  ( -- f )                   \ pll stable ?
   #1 #25 lshift RCC_CR bit@ ;
: pll-wait-stable  ( -- )                \ wait until pll is stable
   begin pll-on pll-ready? until ;
: pll-clk-src-hse  ( -- )                \ set main pll source to hse
   #1 #22 lshift RCC_PLLCFGR bis! ;
: pll-m!  ( n -- )                       \ set main pll clock pre divider
   $1f RCC_PLLCFGR bits! ;
: pll-m@  ( -- n )                       \ get main pll clock pre divider
   $1f RCC_PLLCFGR bits@ ;
: pll-n!  ( n -- )                       \ set Main PLL (PLL) multiplication factor
   $1ff #6 lshift RCC_PLLCFGR bits! ;
: pll-n@  ( -- n )                       \ get Main PLL (PLL) multiplication factor
   $1ff #6 lshift RCC_PLLCFGR bits@ ;
: pll-p!  ( n -- )                       \ set  Main PLL (PLL) divider
   #3 #16 lshift RCC_PLLCFGR bits! ;
: pll-p@  ( n -- )                       \ set  Main PLL (PLL) divider
   #3 #16 lshift RCC_PLLCFGR bits@ ;
: pllsai-off  ( -- )                     \ turn off PLLSAI
   #1 #28 lshift RCC_CR bic! ;
: pllsai-on  ( -- )                      \ turn on PLLSAI
   #1 #28 lshift RCC_CR bis! ;
: pllsai-ready?  ( -- f )                \ PLLSAI stable ?
   #1 #29 lshift RCC_CR bit@ ;
: pllsai-wait-stable  ( -- )             \ wait until PLLSAI is stable
   begin pllsai-on pllsai-ready? until ;
: pllsai-n!  ( n -- )                    \ set PLLSAI clock multiplication factor
   $1ff #6 lshift RCC_PLLSAICFGR bits! ;
: pllsai-r!  ( n -- )                    \ set PLLSAI clock multiplication factor
   $7 #28 lshift RCC_PLLSAICFGR bits! ;
: pllsai-divr!  ( n -- )                 \ division factor for LCD_CLK
   $3 #16 lshift RCC_DKCFGR1 bits! ;
: ahb-prescaler! ( n -- )                \ set AHB prescaler
   $F0 RCC_CFGR bits! ;
: apb1-prescaler! ( n -- )               \ set APB1 low speed prescaler
   $7 #10 lshift RCC_CFGR bits! ;
: apb2-prescaler! ( n -- )               \ set APB2 high speed prescaler
   $7 #13 lshift RCC_CFGR bits! ;

\ ***** PWR constants and words *********
$40007000      constant PWR_BASE         \ PWR base address
$00 PWR_BASE + constant PWR_CR1          \ PWR power control register
$04 PWR_BASE + constant PWR_CSR1         \ PWR power control/status register
: overdrive-enable ( -- )                \ enable over drive mode
   #1 #16 lshift PWR_CR1 bis! ;
: overdrive-ready? ( -- f )              \ overdrive ready ?
   #1 #16 lshift PWR_CSR1 bit@ ;
: overdrive-switch-on  ( -- )            \ initiate overdrive switch
   #1 #17 lshift PWR_CR1 bis! ;
: overdrive-switch-ready?  ( -- f )      \ overdrive switch complete
   #1 #17 lshift PWR_CSR1 bit@ ;
: pwr-clock-on  ( -- )                   \ turn on power interface clock
   $01 #28 lshift RCC_APB1ENR bis! ;
: overdrive-on ( -- )                    \ turn on overdrive on ( not when system clock is pll )
   pwr-clock-on
   overdrive-enable
   begin overdrive-ready? until
   overdrive-switch-on
   begin overdrive-switch-ready? until ;
: voltage-scale-mode-3  ( -- )           \ activate voltage scale mode 3
   1 $03 #14 lshift PWR_CR1 bits! ;
: voltage-scale-mode-1  ( -- )           \ activate voltage scale mode 3
   #3 $03 #14 lshift PWR_CR1 bits! ;

\ ***** usart constants & words *********
$40011000               constant USART1_BASE
$0C                     constant USART_BRR
USART_BRR USART1_BASE + constant USART1_BRR
: usart1-clk-sel!  ( n -- )              \ set usart1 clk source
   $3 RCC_DKCFGR2 bits! ;
: usart1-baud-update!  ( baud -- )       \ update usart baudrate
   #2 usart1-clk-sel!                    \ use hsi clock
   HSI_CLK_HZ over 2/ + swap /           \ calculate baudrate for 16 times oversampling
   USART1_BRR ! ;

\ ***** clock management ****************
: sys-clk-200-mhz  ( -- )                \ supports also sdram clock <= 200 MHz
   hsi-wait-stable
   clk-source-hsi                        \ switch to hsi clock for reconfiguration
   hse-off hse-byp-on hse-on             \ hse bypass mode
   pll-off pll-clk-src-hse               \ pll use hse as clock source
   HSE_CLK_HZ #1000000 / PLL-M!          \ PLL input clock 1 Mhz
   #400 pll-n! PLLP/2 PLL-P!             \ VCO clock 400 MHz
   voltage-scale-mode-1                  \ for flash clock > 168 MHz voltage scale 1(0b011)
   overdrive-on                          \ for flash clock > 180 over drive mode
   hse-wait-stable                       \ hse must be stable before use
   pll-on
   flash-prefetch-ena                    \ activate prefetch to reduce latency impact
   #6 flash-ws!
   flash-art-clear                       \ prepare cache
   flash-art-ena                         \ turn on cache
   HPRE/1 ahb-prescaler!                 \ 200 MHz AHB
   PPRE/2 apb2-prescaler!                \ 100 MHz APB2
   PPRE/4 apb1-prescaler!                \ 50 MHz APB1
   pll-wait-stable clk-source-pll
   #115200 usart1-baud-update! ;
: pllsai-clk-96-mhz ( -- )               \ 9.6 MHz pixel clock for RK043FN48H
   pllsai-off
   #96 pllsai-n!                         \ 96 mhz
   #5  pllsai-r!                         \ 19.2 mhz
   PLLSAI-DIVR/2 pllsai-divr!            \ 9.6 mhz PLLSAIDIVR = /2
   pllsai-wait-stable ;

\ ***** lcd definitions *****************
$40016800        constant LTDC              \ LTDC base
$08 LTDC +       constant LTDC_SSR          \ LTDC Synchronization Size Configuration Register
$FFF #16 lshift  constant LTDC_SSR_HSW      \ Horizontal Synchronization Width  ( pixel-1 )
$7FF             constant LTDC_SSR_VSH      \ Vertical   Synchronization Height ( pixel-1 )
$0C LTDC +       constant LTDC_BPCR         \ Back Porch Configuration Register
$FFF #16 lshift  constant LTDC_BPCR_AHBP    \ HSYNC Width  + HBP - 1
$7FF             constant LTDC_BPCR_AVBP    \ VSYNC Height + VBP - 1
$10 LTDC +       constant LTDC_AWCR         \ Active Width Configuration Register
$FFF #16 lshift  constant LTDC_AWCR_AAW     \ HSYNC width  + HBP  + Active Width  - 1
$7FF             constant LTDC_AWCR_AAH     \ VSYNC Height + BVBP + Active Height - 1
$14 LTDC +       constant LTDC_TWCR         \ Total Width Configuration Register
$FFF #16 lshift  constant LTDC_TWCR_TOTALW  \ HSYNC Width + HBP  + Active Width  + HFP - 1
$7FF             constant LTDC_TWCR_TOTALH  \ VSYNC Height+ BVBP + Active Height + VFP - 1
$18 LTDC +       constant LTDC_GCR          \ Global Control Register
1  #31 lshift    constant LTDC_GCR_HSPOL    \ Horizontal Synchronization Polarity 0:active low 1: active high
1  #30 lshift    constant LTDC_GCR_VSPOL    \ Vertical Synchronization Polarity 0:active low 1:active high
1  #29 lshift    constant LTDC_GCR_DEPOL    \ Not Data Enable Polarity 0:active low 1:active high
1  #28 lshift    constant LTDC_GCR_PCPOL    \ Pixel Clock Polarity 0:nomal 1:inverted
1  #16 lshift    constant LTDC_GCR_DEN      \ dither enable
$7 #12 lshift    constant LTDC_GCR_DRW      \ Dither Red Width
$7  #8 lshift    constant LTDC_GCR_DGW      \ Dither Green Width
$7  #4 lshift    constant LTDC_GCR_DBW      \ Dither Blue Width
$1               constant LTDC_GCR_LTDCEN   \ LCD-TFT controller enable bit
$24 LTDC +       constant LTDC_SRCR         \ Shadow Reload Configuration Register
1 1 lshift       constant LTDC_SRCR_VBR     \ Vertical Blanking Reload
1                constant LTDC_SRCR_IMR     \ Immediate Reload
$2C LTDC +       constant LTDC_BCCR         \ Background Color Configuration Register RGB888
$FF #16 lshift   constant LTDC_BCCR_BCRED   \ Background Color Red
$FF  #8 lshift   constant LTDC_BCCR_BCGREEN \ Background Color Green
$FF              constant LTDC_BCCR_BCBLUE  \ Background Color Blue
$34 LTDC +       constant LTDC_IER          \ Interrupt Enable Register
#1 #3 lshift     constant LTDC_IER_RRIE     \ Register Reload interrupt enable
#1 #2 lshift     constant LTDC_IER_TERRIE   \ Transfer Error Interrupt Enable
#1 #1 lshift     constant LTDC_IER_FUIE     \ FIFO Underrun Interrupt Enable
#1               constant LTDC_IER_LIE      \ Line Interrupt Enable
$38 LTDC +       constant LTDC_ISR          \ Interrupt Status Register
#1 #3 lshift     constant LTDC_ISR_RRIF     \ Register Reload interrupt flag
#1 #2 lshift     constant LTDC_ISR_TERRIF   \ Transfer Error Interrupt flag
#1 #1 lshift     constant LTDC_ISR_FUIF     \ FIFO Underrun Interrupt flag
#1               constant LTDC_ISR_LIF      \ Line Interrupt flag
$3C LTDC +       constant LTDC_ICR          \ Interrupt Clear Register
#1 #3 lshift     constant LTDC_ICR_CRRIF    \ Register Reload interrupt flag
#1 #2 lshift     constant LTDC_ICR_CTERRIF  \ Transfer Error Interrupt flag
#1 #1 lshift     constant LTDC_ICR_CFUIF    \ FIFO Underrun Interrupt flag
#1               constant LTDC_ICR_CLIF     \ Line Interrupt flag
$40 LTDC +       constant LTDC_LIPCR        \ Line Interrupt Position Configuration Register
$7FF             constant LTDC_LIPCR_LIPOS  \ Line Interrupt Position
$44 LTDC +       constant LTDC_CPSR         \ Current Position Status Register
$FFFF #16 lshift constant LTDC_CPSR_CXPOS   \ Current X Position
$FFFF            constant LTDC_CPSR_CYPOS   \ Current Y Position
$48 LTDC +       constant LTDC_CDSR         \ Current Display Status Register
1 3 lshift       constant LTDC_CDSR_HSYNCS  \ Horizontal Synchronization display Status
1 2 lshift       constant LTDC_CDSR_VSYNCS  \ Vertical Synchronization display Status
1 1 lshift       constant LTDC_CDSR_HDES    \ Horizontal Data Enable display Status
1                constant LTDC_CDSR_VDES    \ Vertical Data Enable display Status
$84 LTDC +       constant LTDC_L1CR         \ Layerx Control Register
1 4 lshift       constant LTDC_LxCR_CLUTEN  \ Color Look-Up Table Enable
1 2 lshift       constant LTDC_LxCR_COLKEN  \ Color Keying Enable
1                constant LTDC_LxCR_LEN     \ layer enable

\ ***** lcd constants *******************
#0 constant LCD-PF-ARGB8888              \ pixel format argb
#1 constant LCD-PF-RGB888                \ pixel format rgb
#2 constant LCD-PF-RGB565                \ pixelformat 16 bit
#3 constant LCD-PF-ARGB1555              \ pixelformat 16 bit alpha
#4 constant LCD-PF-ARGB4444              \ pixelformat 4 bit/color + 4 bit alpha
#5 constant LCD-PF-L8                    \ pixelformat luminance 8 bit
#6 constant LCD-PF-AL44                  \ pixelformat 4 bit alpha 4 bit luminance
#7 constant LCD-PF-AL88                  \ pixelformat 8 bit alpha 8 bit luminance

\ ***** lcd gpio ports ******************
#4  GPIOE + constant PE4

#12 GPIOG + constant PG12

#7  GPIOH + constant PH7
#8  GPIOH + constant PH8

#0  GPIOJ + constant PJ0
#1  GPIOJ + constant PJ1
#2  GPIOJ + constant PJ2
#3  GPIOJ + constant PJ3
#4  GPIOJ + constant PJ4
#5  GPIOJ + constant PJ5
#6  GPIOJ + constant PJ6
#7  GPIOJ + constant PJ7
#8  GPIOJ + constant PJ8
#9  GPIOJ + constant PJ9
#10 GPIOJ + constant PJ10
#11 GPIOJ + constant PJ11
#13 GPIOJ + constant PJ13
#14 GPIOJ + constant PJ14
#15 GPIOJ + constant PJ15

#9   GPIOI + constant PI9
#10  GPIOI + constant PI10
#12  GPIOI + constant PI12
#13  GPIOI + constant PI13
#14  GPIOI + constant PI14
#15  GPIOI + constant PI15

#0  GPIOK + constant PK0
#1  GPIOK + constant PK1
#2  GPIOK + constant PK2
#3  GPIOK + constant PK3
#4  GPIOK + constant PK4
#5  GPIOK + constant PK5
#6  GPIOK + constant PK6
#7  GPIOK + constant PK7

\ ***** lcd io ports ********************
PI15 constant LCD_R0                     \ GPIO-AF14
PJ0  constant LCD_R1                     \ GPIO-AF14
PJ1  constant LCD_R2                     \ GPIO-AF14
PJ2  constant LCD_R3                     \ GPIO-AF14
PJ3  constant LCD_R4                     \ GPIO-AF14
PJ4  constant LCD_R5                     \ GPIO-AF14
PJ5  constant LCD_R6                     \ GPIO-AF14
PJ6  constant LCD_R7                     \ GPIO-AF14

PJ7  constant LCD_G0                     \ GPIO-AF14
PJ8  constant LCD_G1                     \ GPIO-AF14
PJ9  constant LCD_G2                     \ GPIO-AF14
PJ10 constant LCD_G3                     \ GPIO-AF14
PJ11 constant LCD_G4                     \ GPIO-AF14
PK0  constant LCD_G5                     \ GPIO-AF14
PK1  constant LCD_G6                     \ GPIO-AF14
PK2  constant LCD_G7                     \ GPIO-AF14

PE4  constant LCD_B0                     \ GPIO-AF14
PJ13 constant LCD_B1                     \ GPIO-AF14
PJ14 constant LCD_B2                     \ GPIO-AF14
PJ15 constant LCD_B3                     \ GPIO-AF14
PG12 constant LCD_B4                     \ GPIO-AF9
PK4  constant LCD_B5                     \ GPIO-AF14
PK5  constant LCD_B6                     \ GPIO-AF14
PK6  constant LCD_B7                     \ GPIO-AF14

PI14 constant LCD_CLK                    \ GPIO-AF14
PK7  constant LCD_DE                     \ GPIO-AF14
PI10 constant LCD_HSYNC                  \ GPIO-AF14
PI9  constant LCD_VSYNC                  \ GPIO-AF14
PI12 constant LCD_DISP
PI13 constant LCD_INT                    \ touch interrupt
PH7  constant LCD_SCL                    \ I2C3_SCL GPIO-AF4 touch i2c
PH8  constant LCD_SDA                    \ I2C3_SCL GPIO-AF4 touch i2c
PK3  constant LCD_BL                     \ lcd back light port

\ ***** LCD Timings *********************
#480 constant RK043FN48H_WIDTH
#272 constant RK043FN48H_HEIGHT
#41  constant RK043FN48H_HSYNC           \ Horizontal synchronization
#13  constant RK043FN48H_HBP             \ Horizontal back porch
#32  constant RK043FN48H_HFP             \ Horizontal front porch
#10  constant RK043FN48H_VSYNC           \ Vertical synchronization
#2   constant RK043FN48H_VBP             \ Vertical back porch
#2   constant RK043FN48H_VFP             \ Vertical front porch

RK043FN48H_WIDTH  constant MAX_WIDTH     \ maximum width
RK043FN48H_HEIGHT constant MAX_HEIGHT    \ maximum height
\ ***** lcd functions *******************
: lcd-backlight-init  ( -- )             \ initialize lcd backlight port
   LCD_BL port# rcc-gpio-clk-on          \ turn on gpio clock
   1 LCD_BL mode-shift
   LCD_BL mode-mask
   LCD_BL port-base set-mask! ;
: lcd-backlight-on  ( -- )               \ lcd back light on
   LCD_BL bsrr-on LCD_BL port-base GPIO_BSRR + ! ;
: lcd-backlight-off  ( -- )              \ lcd back light on
   LCD_BL bsrr-off LCD_BL port-base GPIO_BSRR + ! ;
: lcd-clk-init ( -- )                    \ enable 
   rcc-ltdc-clk-on
   pllsai-clk-96-mhz ;
: lcd-gpio-init ( -- )                   \ initialize all lcd gpio ports
   #14 LCD_R0 MODE-AF  #14 LCD_R1 MODE-AF  #14 LCD_R2 MODE-AF  #14 LCD_R3 MODE-AF
   #14 LCD_R4 MODE-AF  #14 LCD_R4 MODE-AF  #14 LCD_R6 MODE-AF  #14 LCD_R7 MODE-AF

   #14 LCD_G0 MODE-AF  #14 LCD_G1 MODE-AF  #14 LCD_G2 MODE-AF  #14 LCD_G3 MODE-AF
   #14 LCD_G4 MODE-AF  #14 LCD_G5 MODE-AF  #14 LCD_G6 MODE-AF  #14 LCD_G7 MODE-AF

   #14 LCD_B0 MODE-AF  #14 LCD_B1 MODE-AF  #14 LCD_B2 MODE-AF  #14 LCD_B3 MODE-AF
    #9 LCD_B4 MODE-AF  #14 LCD_B5 MODE-AF  #14 LCD_B6 MODE-AF  #14 LCD_B7 MODE-AF

   #14 LCD_VSYNC MODE-AF  #14 LCD_HSYNC MODE-AF
   #14 LCD_CLK MODE-AF    #14 LCD_DE    MODE-AF
   01 LCD_DISP gpio-mode! ;
: lcd-disp-on  ( -- )                    \ enable display
   LCD_DISP bsrr-on LCD_DISP port-base GPIO_BSRR + ! ;
: lcd-disp-off  ( -- )                   \ disable display
   LCD_DISP bsrr-off LCD_DISP port-base GPIO_BSRR + ! ;
: lcd-back-color! ( r g b -- )           \ lcd background color
   $ff and swap $ff and #8 lshift or
   swap $ff and #16 lshift or
   LTDC_BCCR @ $ffffff bic or LTDC_BCCR ! ;
: lcd-reg-update ( -- )                  \ update register settings
   1 LTDC_SRCR bis! ;
: lcd-init-polarity ( -- )               \ initialize polarity
   0 LTDC_GCR_HSPOL LTDC_GCR bits!
   0 LTDC_GCR_VSPOL LTDC_GCR bits!
   0 LTDC_GCR_DEPOL LTDC_GCR bits!
   0 LTDC_GCR_PCPOL LTDC_GCR bits! ;
: lcd-display-init ( -- )                \ set display configuration
   LTDC_GCR_LTDCEN LTDC_GCR bis!
   RK043FN48H_HSYNC 1- LTDC_SSR_HSW LTDC_SSR bits!
   RK043FN48H_VSYNC 1- LTDC_SSR_VSH LTDC_SSR bits!

   RK043FN48H_HSYNC RK043FN48H_HBP + 1- LTDC_BPCR_AHBP LTDC_BPCR bits!
   RK043FN48H_VSYNC RK043FN48H_VBP + 1- LTDC_BPCR_AVBP LTDC_BPCR bits!

   RK043FN48H_WIDTH  RK043FN48H_HSYNC + RK043FN48H_HBP + 1- LTDC_AWCR_AAW LTDC_AWCR bits!
   RK043FN48H_HEIGHT RK043FN48H_VSYNC + RK043FN48H_VBP + 1- LTDC_AWCR_AAH LTDC_AWCR bits!

   RK043FN48H_HEIGHT RK043FN48H_VSYNC +
   RK043FN48H_VBP + RK043FN48H_VFP + 1- LTDC_TWCR_TOTALH LTDC_TWCR bits!

   RK043FN48H_WIDTH RK043FN48H_HSYNC +
   RK043FN48H_HBP + RK043FN48H_HFP + 1- LTDC_TWCR_TOTALW LTDC_TWCR bits!
   0 0 0 lcd-back-color!
   lcd-init-polarity
   
   lcd-backlight-init lcd-backlight-on ;
\ ***** lcd layer functions *************
0   constant layer0
$80 constant layer1
: layer-base ( l -- offset )                 \ layer base address
   0<> $80 and LTDC + 1-foldable ;
: layer-base ( l -- offset )                 \ layer base address
   LTDC + 1-foldable ;
: lcd-layer-on  ( layer -- )                 \ turn on layer
   layer-base $84 + 1 swap bis! ;
: lcd-layer-off  ( layer -- )                \ turn off layer
   layer-base $84 + 1 swap bic! ;
: lcd-layer-color-key-ena ( l -- )           \ enable color key
   layer-base $84 + $2 swap bis! ;
: lcd-layer-color-key-dis ( l -- )           \ disable color key
   layer-base $84 + $2 swap bic! ;
: lcd-layer-color-lookup-table-ena ( l -- )  \ enable color lookup table
   layer-base $84 + $10 swap bis! ;
: lcd-layer-color-lookup-table-dis ( l -- )  \ disable color lookup table
   layer-base $84 + $10 swap bic! ;
: lcd-layer-h-start! ( start layer -- )      \ set layer window start position
   layer-base $88 + $FFF swap bits! ;
: lcd-layer-h-end!  ( end layer -- )         \ set layer window end position
   layer-base $88 + $FFF0000 swap bits! ;
: lcd-layer-v-start! ( start layer -- )      \ set layer window vertical start
   layer-base $8C + $7ff swap bits! ;
: lcd-layer-v-end! ( end layer -- )          \ set layer window vertical end
   layer-base $8C + $7ff0000 swap bits! ;
: lcd-layer-key-color! ( color layer -- )    \ set layer color keying color
   layer-base $90 + $ffffff swap bits! ;
: lcd-layer-pixel-format! ( fmt layer -- )   \ set layer pixel format
   layer-base $94 + $7 swap bits! ;
: lcd-layer-const-alpha! ( alpha layer -- )  \ set layer constant alpha
   layer-base $98 + $FF swap bits! ;
: lcd-layer-default-color! ( c layer -- )    \ set layer default color ( argb8888 )
   layer-base $9C + ! ;
: lcd-layer-blend-cfg! ( bf1 bf2 layer -- )  \ set layer blending function
   layer-base $a0 + -rot swap 8 lshift or swap ! ;
: lcd-layer-fb-adr!  ( a layer -- )          \ set layer frame buffer start adr
   layer-base $ac + ! ;
: lcd-layer-fb-adr@  ( layer -- a )          \ get layer frame buffer start adr
   layer-base $ac + @ ;
: lcd-layer-fb-pitch! ( pitch layer -- )     \ set layer line distance in byte
   layer-base $B0 + $1FFF0000 swap bits! ;
: lcd-layer-fb-line-length! ( ll layer -- )  \ set layer line length in byte
   layer-base $B0 + $1FFF swap bits! ;
: lcd-layer-num-lines! ( lines layer -- )    \ set layer number of lines to buffer
   layer-base $b4 + $7ff swap bits! ;
: lcd-layer-color-map ( c i l -- )           \ set layer color at map index
   layer-base $c4 +
   -rot $ff and #24 lshift                   \ shift index to pos [31..24]
   swap $ffffff and or                       \ cleanup color
   swap ! ;

\ setup a frame buffer   
MAX_WIDTH MAX_HEIGHT * dup BUFFER: lcd-fb0-buffer constant lcd-fb0-size#
lcd-fb0-buffer variable lcd-fb0              \ frame buffer 0 pointer
lcd-fb0-size#  variable lcd-fb0-size         \ frame buffer 0 size
: lcd-layer-colormap-gray-scale ( layer -- ) \ grayscale colormap quick n dirty
   >R
   #256 0 do
     i dup dup #8 lshift or #8 lshift or
     i r@ lcd-layer-color-map
   loop Rdrop ;
   
: fb-init-0-ff ( layer -- )              \ fill frame buffer with values 0..255
   lcd-reg-update
   lcd-layer-fb-adr@
   MAX_WIDTH MAX_HEIGHT * 0 do dup i + i swap c! loop drop ;
: lcd-layer0-init ( -- )
   layer0 lcd-layer-off
   layer0 lcd-layer-color-lookup-table-ena
   0 layer0 lcd-layer-h-start!
   MAX_WIDTH  layer0 lcd-layer-h-end!
   0 layer0 lcd-layer-v-start!
   MAX_HEIGHT layer0 lcd-layer-v-end!    \ vertical end / height
   0 layer0 lcd-layer-key-color!         \ key color black no used here
   #5 layer0 lcd-layer-pixel-format!     \ 8 bit per pixel frame buffer format
   lcd-fb0 @ layer0 lcd-layer-fb-adr!    \ set frame buffer address
   MAX_WIDTH layer0 lcd-layer-fb-pitch!
   MAX_WIDTH layer0 lcd-layer-fb-line-length!
   MAX_HEIGHT layer0 lcd-layer-num-lines!
   layer0 fb-init-0-ff
   layer0 lcd-layer-colormap-gray-scale
   layer0 lcd-layer-on
   0 layer0 lcd-layer-default-color!
   lcd-reg-update
   ;
: lcd-init  ( -- )                       \ pll-input frequency must be 1 MHz
   lcd-clk-init lcd-backlight-init
   lcd-display-init lcd-reg-update lcd-gpio-init lcd-disp-on ;
: demo ( -- )
   sys-clk-200-mhz lcd-init lcd-layer0-init lcd-reg-update lcd-backlight-on ;
