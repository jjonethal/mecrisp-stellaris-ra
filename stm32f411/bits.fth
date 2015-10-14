
: bits3! ( v m a -- )
   -rot swap
   over cnt0 lshift over and  ( -- a m vm )
   swap not ( -- a vm /m )
   2 pick @ and   ( -- )
   or swap ! ;
 