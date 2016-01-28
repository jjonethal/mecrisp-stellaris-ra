\ qspi.fth
\ N25Q128A13EF840E
\ QSPI_NCS - PB6 - AF10
\ QSPI_CLK - PB2 - AF9
\ QSPI_D0  - PD11 - AF9
\ QSPI_D1  - PD12 - AF9
\ QSPI_D2  - PE2  - AF9
\ QSPI_D3  - PD13 - AF9

 #2 GPIOB + constant PB2
 #6 GPIOB + constant PB6
#11 GPIOD + constant PD11
#12 GPIOD + constant PD12
#13 GPIOD + constant PD13
 #2 GPIOE + constant PE2

PB6  constant QSPI_NCS 
PB2  constant QSPI_CLK 
PD11 constant QSPI_D0
PD12 constant QSPI_D1
PE2  constant QSPI_D2
PD13 constant QSPI_D3

: gpio-mode-af ( pin -- )
   
 
: qspi-gpio-init-hw ( -- )
   AF10 QSPI_NCS gpio-mode-af 
   AF9  QSPI_CLK gpio-mode-af
   AF9  QSPI_D0  gpio-mode-af
   AF9  QSPI_D1  gpio-mode-af
   AF9  QSPI_D2  gpio-mode-af
   AF9  QSPI_D3  gpio-mode-af ;
: qspi-send-cmd ( cmd -- ) ;
: qspi-read ( n adr -- ) ;
: qspi-write-data ( d n a -- ) ;
: qspi-mem-map-mode  ( -- ) ; \ set to memory mapped mode
: qspi-bb-q-read ( cmd -- ) ; \ bitbang read quad
: qspi-bb-q-write ( data n adr -- ) ; \ write bitbang quad
