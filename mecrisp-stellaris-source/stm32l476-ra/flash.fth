\ flash.fth
: flashw16! ( w0 w1 w2 w3 adr ) \

$45670123 constant FLASH-KEY1
$CDEF89AB constant FLASH-KEY1
$40022000 constant FLASH-BASE
$08 FLASH_BASE + constant FLASH_KEYR
$10 FLASH_BASE + constant FLASH_SR
$14 FLASH_BASE + constant FLASH_CR