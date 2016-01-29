\ gpio.fth
\ gpio driver for stm32f746
\ require utils.fth

$40020000 constant GPIO-BASE             \ base address for gpio ports
: gpio ( n -- adr )                      \ calculate base address for port bank n: 0-portA 1-portb ...
   $f and #10 lshift GPIO-BASE or 1-foldable ;
$00         constant GPIO_MODER
$04         constant GPIO_OTYPER
$08         constant GPIO_OSPEEDR
$0C         constant GPIO_PUPDR
$10         constant GPIO_IDR
$14         constant GPIO_ODR
$18         constant GPIO_BSRR
$1C         constant GPIO_LCKR
$20         constant GPIO_AFRL
$24         constant GPIO_AFRH

\ pin is an identifier for io pin consisting of gpio bank base address ored with 
\ pin number. Bank base address is obtained masking out lowest 4 bits.
\ PA3 : pin id for port a bank base + 3 for pin number $40020003

: pin#  ( pin -- nr )                    \ get pin number from pin
   $f and 1-foldable ;
: port-base  ( pin -- adr )              \ get port base from pin
   $f bic 1-foldable ;
: port# ( pin -- n )                     \ return gpio port number A:0 .. K:10
   #10 rshift $f and 1-foldable ;
: mode-mask  ( pin -- m )                \ generate bit mask for gpio_moder depending on pin nr
   #3 swap pin# 2* lshift 1-foldable ;
: mode-shift ( mode pin -- mode<< )      \ shift mode by pin number * 2 for gpio_moder
   pin# 2* lshift 2-foldable ;
: set-mask! ( v m a -- )                 \ set new value at masked position eg $A0 $f0 @a:$1234 setmask -- @a:12A4   
   tuck @ swap bic rot or swap ! ;       \ v must be clean
: bsrr-on  ( pin -- v )                  \ gpio_bsrr mask pin on
   pin# 1 swap lshift 1-foldable ;
: bsrr-off  ( pin -- v )                 \ gpio_bsrr mask pin off
   pin# #16 + 1 swap lshift 1-foldable ;
: af-mask  ( pin -- mask )               \ alternate function bitmask
   $7 and #2 lshift $f swap lshift 1-foldable ;
: af-reg  ( pin -- adr )                 \ alternate function register address for pin
   dup $8 and 2/ swap
   port-base GPIO_AFRL + + 1-foldable ;
: af-shift ( af pin -- af )              \ shift altenate function number by pin number * 4
   pin# #2 lshift swap lshift 2-foldable ;
: gpio-mode! ( mode pin -- )             \ change gpio-mode
   tuck mode-shift swap dup
   mode-mask swap port-base set-mask! ;
: gpio-mode-af ( af pin -- )                  \ set alternate function mode af for pin
   #2 over gpio-mode!
   dup af-mask swap af-reg bits! ;
: gpio-speed ( speed pin -- )            \ set speed mode 0:low speed 1:medium 2:fast 3:high speed
   dup pin# 2* #3 swap lshift
   swap port-base GPIO_OSPEEDR + bits! ;
: gpio-mode-af-fast ( af pin -- )
   #2 over gpio-speed gpio-mode-af ;

