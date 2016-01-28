\ gpio.fth
$40020000 constant GPIO-BASE
: gpio ( n -- adr )
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
   dup af-mask swap af-reg bits! ;
: speed-mode ( speed pin -- )            \ set speed mode 0:low speed 1:medium 2:fast 3:high speed
   dup pin# 2* #3 swap lshift
   swap port-base GPIO_OSPEEDR + bits! ;
: mode-af-fast ( af pin -- )
   #2 over speed-mode mode-af ;

