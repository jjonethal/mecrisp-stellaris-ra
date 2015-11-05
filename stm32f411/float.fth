\ floatingpoint
\ 8 bit exponent
\ 24 bit mantissa
: f* ( f1 f2 -- f1*f2 )
: fmantissa1 ( f -- w ) dup $7fffff and 800000 or swap 31 rshift 0 <> tuck xor swap - ;
: fmantissa2 ( f -- w ) dup $7fffff and 800000 or swap 31 rshift 0 <> tuck + xor ;
: tf dup fmantissa1 . fmantissa2 . ;
: exponent ( f -- e ) #23 rshift $FF and #127 - ;

#81       constant FPU_INT
$E000ED88 constant CPACR
: enable-fpu ( -- )
  $F #20 lshift CPACR bit!
  DSB ISB ;