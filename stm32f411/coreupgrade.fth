\ core upgrade for stm32F411re

\ ********** kernel located function redefine 
\ function located in kernel must be redifined because they will not be
\ accessible once old kernel is erased
: >= ( n n -- f ) - 0< not ;                  \ redefine operation to avoid kernel call
: <  ( n n -- f ) - 0< ;                      \ redefine operation to avoid kernel call
: =  ( n n -- f ) - 0= ;

\ ********** flash register ******************
$40023C00 constant FLASH_BASE
 $0 FLASH_BASE + constant FLASH_ACR

 $4 FLASH_BASE + constant FLASH_KEYR          \ Flash key register allow access to the Flash control register
 $8 FLASH_BASE + constant FLASH_OPTKEYR

\ ********** Flash Status Register ***********
 $c FLASH_BASE + constant FLASH_SR            \ Flash status register
#1 #16 lshift    constant FLASH_SR_BSY        \ Busy 1: Flash memory operation ongoing 0: no Flash memory operation ongoing 
#1  #8 lshift    constant FLASH_SR_RDERR      \ Read Protection Error
#1  #7 lshift    constant FLASH_SR_PGSERR     \ Programming sequence error
#1  #6 lshift    constant FLASH_SR_PGPERR     \ Programming parallelism error
#1  #5 lshift    constant FLASH_SR_PGAERR     \ Programming alignment error
#1  #4 lshift    constant FLASH_SR_WRPERR     \ Write protection error
#1  #1 lshift    constant FLASH_SR_OPERR      \ Operation error
#1  #0 lshift    constant FLASH_SR_EOP        \ End of operation only set if the end of operation interrupts are enabled

\ ********** Flash Configuation Register *****
$10 FLASH_BASE + constant FLASH_CR            \ Flash control register configure and start Flash memory operations
#1 #31 lshift    constant FLASH_CR_LOCK       \ Lock write to 1 only lock flash
#1 #25 lshift    constant FLASH_CR_ERRIE      \ Error interrupt enable
#1 #24 lshift    constant FLASH_CR_EOPIE      \ End of operation interrupt enable
#1 #16 lshift    constant FLASH_CR_STRT       \ Start erase operation
#3  #8 lshift    constant FLASH_CR_PSIZE      \ Program size 00:x8 01:x16 10:x32 11:x64
$F  #3 lshift    constant FLASH_CR_SNB        \ Sector number 0-7
#1  #2 lshift    constant FLASH_CR_MER        \ Mass erase
#1  #1 lshift    constant FLASH_CR_SER        \ sector erase
#1  #0 lshift    constant FLASH_CR_PG         \ page erase

\ ********** flash constants *****************
$45670123 constant FLASH_KEY1                 \ unlock key 1 for flash program/erase operations
$CDEF89AB constant FLASH_KEY2                 \ unlock key 2 for flash program/erase operations

\ ********** flash program working data ******
0 variable flash-image-adr                    \ flash address to store new image to starts from $08000000
0 variable flash-image-size                   \ size of image to flash
0 variable flash-image-buffer-adr             \ address of buffer where programming image is stored

\ ********** flash access functions **********
: flash-unlock ( -- )                         \ unlock flash memory for erase write operations
   FLASH_KEY1 FLASH_KEYR !
   FLASH_KEY2 FLASH_KEYR ! ;
: flash-lock ( -- )                           \ lock flash operations
   FLASH_CR @ $80000000 or FLASH_CR ! ;
: flash-erase-sector ( n -- )                 \ erase flash sector
   $7 and #3 lshift                           \ mask and shift sector number
   FLASH_CR @ %1111000 not and or             \ mask out sector number
   FLASH_CR_SER or FLASH_CR !                 \ erase sector
   FLASH_CR @ FLASH_CR_STRT or FLASH_CR !  ;  \ start erase
: flash-adr->sector  ( a -- s )               \ convert address to flash sector number or -1 if wrong range
   dup  $08000000 >=                          \ >= redefined inline above
   over $08080000 < and not swap              \ valid range
   $FFFFF and
   dup   $4000 < not                          \ < redefined above
   over  $8000 < not  +
   over  $C000 < not  +
   over $10000 < not  +
   over $20000 < not  +
   over $40000 < not  +
   swap $60000 < not  + negate or ;
: flash-wait-idle ( -- )                      \ wait until current flash operation is completed
   begin FLASH_SR @ FLASH_SR_BSY and 0= until ;
: flash-write-c! ( c adr -- )
   FLASH_CR @ FLASH_CR_PSIZE not and          \ 8 bit flash program mode mode
   FLASH_CR_PG or FLASH_CR !                  \ enable program
   C!
   flash-wait-idle ;
: flash-blank ( -- )                          \ erase area for new kernel-image TODO: will be replaced by mass erase to avoid interference when shrinking
   flash-unlock
   flash-image-adr @ dup flash-image-size @ + swap
   do i dup @ 1+ 0<>
     if flash-adr->sector flash-erase-sector
     else drop then
   4 +loop flash-lock ;
: flash-write-image ( -- )                    \ write new flash image to flash
   flash-unlock
   flash-image-size @ 0
   do flash-image-buffer-adr @ i + c@
   flash-image-adr @ i + flash-write-c!
   loop
   flash-lock ;
: flash-verify  ( -- f )                      \ check if new image is equal to programmming image, return -1 if ok else 0
   -1
   flash-image-size @ 0 do
      flash-image-adr @ i + @ 
      flash-image-buffer-adr @ i + @ = and
      dup not if i . then
   4 +loop ;


\ ********** Flash test data *****************
#1024           constant  TEST-IMAGE_SIZE     \ current image size for test purposes
TEST-IMAGE_SIZE buffer:   test-image-buffer

image-buffer flash-image-buffer-adr !         \ initialise working data 
IMAGE_SIZE   flash-image-size !

: test-fill-image ( -- )
   flash-image-size @ 0 do
     i dup flash-image-buffer-adr @ + !
   4 +loop ;
: test-prog  ( -- f )                         \ test flash programming
  test-fill-image
  $8020000 flash-image-adr !                  \ $8020000 safe address at 128 kb
  flash-blank
  flash-write-image
  flash-verify  ;
