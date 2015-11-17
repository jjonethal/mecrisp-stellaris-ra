\ self-programming
reset
$00100000 constant flash-end
#1024 constant cbu-size  \ compile buffer 1k sufficient for now may be if required later
    0 variable cbu-len
cbu-size buffer:  cbu
: clear-cbu ( -- )
   cbu dup cbu-size + swap
   do 0 i ! 4 +loop
   0 cbu-len ! ;
: cbu-free? ( n -- f )
   cbu-len @ + cbu-size <= ;
: cbu-emit? ( -- f )
   cbu-len @ cbu-size < ;
: cbu-emit ( char -- )
   cbu-emit?
   if cbu-len @ dup 1+ cbu-len !
    cbu + c!
   else drop then ;
: >cbu ( adr len -- ) \ append to cbu
   dup cbu-free? 
   if cbu cbu-len dup >R @ dup >R + swap
     dup R> + R> ! 
     move
   else drop
   then ;
hook-emit? @ constant org-hook-emit?
hook-emit @ constant org-hook-emit
: dec-num  ( n -- ) base @ >R decimal 0 <# #s #> type R> base ! ; 
: hook-install  ( -- )
    ['] cbu-emit? hook-emit? !
    ['] cbu-emit  hook-emit ! ;
: cbu-dump  ( -- )
    cr ." new code:" cbu cbu-len @ type ;
: hook-restore  ( -- )
    org-hook-emit? hook-emit? !
    org-hook-emit hook-emit ! ;
: cbu-eval  ( -- ) cbu cbu-len @ evaluate ;
: create-test ( n -- ) \ create a test word definition in cbu
   >R ."  : test-hallo" R@ n. ."  ." [char] " emit ."  Hallo " R> n. [char] " emit ."  cr ; " ;
0 variable i
: src-test  ( -- )
   compiletoflash
   begin
     hook-install 
     clear-cbu
     i @ dup 1+ i ! create-test
     hook-restore
     cbu-dump
     here
     cbu-eval
     here
     swap -
     dup ." progsize " . cr
     2*
     here +  flash-end < not 
   until 
   compiletoram ;
