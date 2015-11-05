\ i2c.fth
\ "E:\stm\DM00105918 NUCLEO stm32f411re datasheet.pdf"
\ "E:\stm\DM00105823 Nucleo stm32f411re user manual.pdf"
\ datasheet stm32f411 "E:\stm\DM00115249 STM32F411xC STM32F411xE.pdf"
\ reference manual stm32f411 "E:\stm\DM00119316  RM0383 STM32F411xC_E advanced ARM-based 32-bit MCUs .pdf"

0 constant i2c-base
: I2C_CR1 ( a -- a ) ;
: I2C_CR2 ( a -- a ) 4 + 1-foldable inline ;

: i2c-init  ( a -- a ) ;
: i2c-s-tx-adr  ( a -- a ) ;
: i2c-s-tx-reg  ( a -- a ) ;
: i2c-s-tx-data  ( a -- a ) ;
: i2c-s-tx-finish  ( a -- a ) ;
: i2c-s-rx-cfg-adr  ( a -- a ) ;
: i2c-s-rx-cfg-reg  ( a -- a ) ;
: i2c-s-rx-adr  ( a -- a ) ;
: i2c-s-rx-data  ( a -- a ) ;
: i2c-s-rx-finish  ( a -- a ) ;
