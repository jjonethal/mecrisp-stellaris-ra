: qc>! ( c -- )                          \ output 8 bit on qspi 
   #24 lshift qc> drop ;
: qa>! ( a24 -- )                        \ output 24 bit address on qspi 
   #8 lshift qc> qc> qc> drop ;
: qc<@ ( -- c )                          \ read 1 byte from qspi
   0 qc< ;
: q<@  ( -- w )                          \ read 1 word from qspi
   0 qc< qc< qc< qc< ;
: q-read ( n da qa -- )                  \ read n bytes to destination da from qspi address qa
   q-start $03 qc>! qa>!
   q<<
   tuck + swap ?do qc<@ i ! loop
   q-stop q>> ;
: qc@  ( qa -- c )                       \ read 8 bit from qspi
   q-start $03 qc>! qa>!
   q<< qc<@ q-stop q>> ;
: qc!  ( c qa -- )                       \ write 8 bit to qspi
   q-idle-wait
   q-write-ena
   q-start $02 qc>! qa>!
   qc>! q-stop ;
: q@  ( qa -- w )                        \ read 1 word from qspi
   q-start $03 qc>! qa>!
   q<< q<@ q-stop q>> ;
: q!  ( w qa -- w )                      \ write 1 word to qspi
   q-idle-wait
   q-write-ena
   q-start $02 qc>! qa>!
   qc> qc> qc> qc> drop q-stop ;

