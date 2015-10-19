\ bitfield utility functions 
: cnt0   ( m -- b )                           \ count trailing zeros with hw support
   dup negate and 1-
   clz negate #32 + 1-foldable ;
: bits@  ( m adr -- b )                       \ get bitfield at masked position e.g $1234 v ! $f0 v bits@ $3 = . (-1)
   @ over and swap cnt0 rshift ;
: bits!  ( n m adr -- )                       \ set bitfield at position $1234 v ! $5 $f00 v bits! v @ $1534 = . (-1)
   >R dup >R cnt0 lshift                      \ shift value to proper pos
   R@ and                                     \ mask out unrelated bits
   R> not R@ @ and                            \ invert bitmask and makout new bits
   or r> ! ;                                  \ apply value and store back
: bit-mask! ( v m adr -- )                    \ set bit masked value at 
   >R tuck and swap not r@ @ and or r> ! ; 
: shift-mask ( v m -- sv m )
  tuck cnt0 lshift over and swap 2-foldable ;

: <<m ( v m -- sv /m )
  tuck cnt0 lshift over and swap not 2-foldable ;
: m! ( v /m a -- )
   >R r@ @ and or r> ! ;
0 variable v
: t $5 $70 <<m v m! ;

: LDMIA ( regs ptr -- instr )                 \ compile ldmia instruction
  $8 lshift or $C800 or h, immediate ;
