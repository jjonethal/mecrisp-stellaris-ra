\ file:  qspi3.fth
\ author Jean Jonethal
\ qspi bitbang driver 
\ require util.fth
\ require gpio.fth
\ ********** qspi driver io ports *******   
 #1 GPIO    constant GPIOB
 #3 GPIO    constant GPIOD
 #4 GPIO    constant GPIOE
 #2 GPIOB + constant PB2
 #6 GPIOB + constant PB6
#11 GPIOD + constant PD11
#12 GPIOD + constant PD12
#13 GPIOD + constant PD13
 #2 GPIOE + constant PE2

\ ********** qspi pin constants *********
PB6  constant qcs
PB2  constant qck 
PD11 constant qd0
PD12 constant qd1
PE2  constant qd2
PD13 constant qd3


\ ********** qspi utility functions *****
: 0<-<< ( w -- w f )                     \ extract bit 31 and shift left word by 1 bit
   dup 2* swap 0< 1-foldable ;
: hh/l# ( f -- m ) 0= $FFFF xor          \ Mask high/low half word low 0:$ffff0000 1:0000FFFF
   1-foldable ;
: pin-10# ( pin -- m )                   \ pin on / off mask
   bsrr-on dup 16 lshift or 1-foldable ;
0 variable q-delay#
: q-delay ( -- ) q-delay# @ 0 do loop ;  \ delay for a variable delay

\ ********** single pin setting *********
: qck-0 ( -- ) qck pin-off ! ;
: qck-1 ( -- ) qck pin-on  ! ;
: qcs-0 ( -- ) qcs pin-off ! ;
: qcs-1 ( -- ) qcs pin-on  ! ;
: qd0-0 ( -- ) qd0 pin-off ! ;
: qd0-1 ( -- ) qd0 pin-on  ! ;
: qd1-0 ( -- ) qd1 pin-off ! ;
: qd1-1 ( -- ) qd1 pin-on  ! ;
: qd2-0 ( -- ) qd2 pin-off ! ;
: qd2-1 ( -- ) qd2 pin-on  ! ;
: qd3-0 ( -- ) qd3 pin-off ! ;
: qd3-1 ( -- ) qd3 pin-on  ! ;

: qd0! ( f -- )  hh/l# qd0 pin-10# and qd0 gpio-bsrr ! ;
: qd1! ( f -- )  hh/l# qd1 pin-10# and qd1 gpio-bsrr ! ;
: qd2! ( f -- )  hh/l# qd2 pin-10# and qd2 gpio-bsrr ! ;
: qd3! ( f -- )  hh/l# qd3 pin-10# and qd3 gpio-bsrr ! ;

: qd0@ ( -- f )  qd0 bsrr-on qd0 gpio-idr bit@ ;
: qd1@ ( -- f )  qd1 bsrr-on qd1 gpio-idr bit@ ;
: qd2@ ( -- f )  qd2 bsrr-on qd2 gpio-idr bit@ ;
: qd3@ ( -- f )  qd3 bsrr-on qd3 gpio-idr bit@ ;

: qd0-or  ( w -- w )  qd0 bsrr-on qd0 gpio-idr bit@ 1 and or ;
: qd1-or  ( w -- w )  qd1 bsrr-on qd1 gpio-idr bit@ 2 and or ;
: qd2-or  ( w -- w )  qd2 bsrr-on qd2 gpio-idr bit@ 4 and or ;
: qd3-or  ( w -- w )  qd3 bsrr-on qd3 gpio-idr bit@ 8 and or ;

\ ********** q1 single mode *************
: q1b> ( w -- w )  qck-0 dup 0< qd0! 2* q-delay qck-1 q-delay ;  
: q1c> ( w -- w )  q1b> q1b> q1b> q1b> q1b> q1b> q1b> q1b> ;
: q1b< ( w -- w )  qck-0 q-delay 2* qd1@ 1 and or qck-1 q-delay ;
: q1c< ( w -- w )  q1b< q1b< q1b< q1b< q1b< q1b< q1b< q1b< ;
: q1-init ( -- )
   qcs-1 qcs gpio-output
   qck-0 qck gpio-output
   qd0-0 qd0 gpio-output
   qd1-1 qd0 gpio-input
   qd2-1 qd2 gpio-output
   qd3-1 qd3 gpio-output ;
: q1>> ( -- ) ;
: q1<< ( -- ) ;

\ ********** q2 dual mode ***************
: q2b>  ( w -- w )  qck-0 0<-<< qd1! 0<-<< qd0! q-delay qck-1 q-delay ;
: q2c>  ( w -- w )  q2b> q2b> q2b> q2b> ;
: q2b<  ( w -- w )  qck-0 q-delay 2 lshift
   qd1-or qd0-or  qck-1 q-delay ;
: q2c<  ( w -- w )  q2b< q2b< q2b< q2b< ;
: q2>> ( -- ) qd0 gpio-output qd1 gpio-output ;
: q2<< ( -- ) qd0 gpio-input  qd1 gpio-input ;

\ ********** q4 quad mode ***************
: q4b>  ( w -- w )
   qck-0 0<-<< qd3! 0<-<< qd2! 0<-<< qd1! 0<-<< qd0! q-delay qck-1 q-delay ;
: q4c>  ( w -- w ) q4b> q4b> ;
: q4b<  ( w -- w )
   qck-0 q-delay 4 lshift
   qd3-or qd2-or qd1-or qd0-or
   qck-1 q-delay ;
: q4c<  ( w -- w ) q4b< q4b< ;
: q4>> ( -- ) q2>>  qd2 gpio-output qd3 gpio-output ;
: q4<< ( -- ) q2<<  qd2 gpio-input  qd3 gpio-input ;

\ q@
\ q!
\ qc@
\ qc!
\ qh@
\ qh!
\ q-erase-sub-sector
\ q-erase-sector
\ q-erase-all
