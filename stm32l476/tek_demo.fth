\ tek 4014 terminal demo

\ ASCII chars
: enum dup constant 1+ ;
0 constant ASC_NUL
1 constant ASC_SOH
2 constant ASC_STX
3 constant ASC_ETX
4 constant ASC_EOT
5 constant ASC_ENQ
6 constant ASC_ACK
7 constant ASC_BEL
8 constant ASC_BS
9 constant ASC_HT
10 constant ASC_LF
11 constant ASC_VT
12 constant ASC_FF
13 constant ASC_CR
14 constant ASC_SO
15 constant ASC_SI
16 constant ASC_DLE
17 constant ASC_DC1
18 constant ASC_DC2
19 constant ASC_DC3
20 constant ASC_DC4
21 constant ASC_NAK
22 constant ASC_SYN
23 constant ASC_ETB
24 constant ASC_CAN
25 constant ASC_EM
26 constant ASC_SUB
27 constant ASC_ESC
28 constant ASC_FS
29 constant ASC_GS
30 constant ASC_RS
31 constant ASC_US
32 constant ASC_SPC
127 constant ASC_RUBOUT
127 constant ASC_DEL

0 variable g-pos-x
0 variable g-pos-y
: store-pos ( x y -- x y )                    \ store graphics position
   2dup g-pos-y !
   g-pos-x ! ;


: ESC ASC_ESC emit ;                          \ emit esc char

: v2-add ( x1 y1 x2 y2 -- x1+x2 y1+y2 )       \ add 2 2d vectors
  rot + -rot + swap 4-foldable ;

: xl ( x -- xl )                              \ tek xposition low text
  $1F and #64 + 1-foldable ;
: xh ( x -- xh )                              \ tek xposition high part
  #5 rshift #32 + 1-foldable ;
: yl ( y -- yl )                              \ tek y position low part
  $1F and #96 + 1-foldable ;
: yh ( y -- yh )                              \ tek y pos high part
  #5 rshift #32 + 1-foldable ;
: xy ( x y -- )                               \ emit yx coordinates
  store-pos dup yh emit yl emit
  dup xh emit xl emit ;
: xypoint ( x y -- )                          \ emit yx coordinates
  dup yh emit yl emit dup xh emit xl dup emit emit ;
: xy-4k-lsb ( x y -- )                        \ least significant bits for 4k mode
  #3 and #2 lshift swap #3 and or $60 or ;
: xy4k ( x y -- )                             \ output 4kx4k coordinates
  dup yh emit
  2dup xy-4k-lsb emit
  yl emit 
  dup xh emit
  xl emit ;  
: GRAPH ( -- )                                \ switch to graphics mode
  ASC_GS emit ;

: moveto ( x y -- ) GRAPH xy ;      \ move vector start 
: moveto.a ( a -- )
   GRAPH dup @ swap 4 + @ xy ;
: lineto ( x y -- ) xy ;                      \ draw line from current pos to x y
: lineto.a ( a -- ) dup @ swap 4 + @ xy ;     \ draw line from current pos to x y
: point ( x y -- )
  GRAPH 2dup moveto lineto ;
: point ( x y -- )
  GRAPH xypoint ;
: CLS ( -- )                                  \ clear screen
   ESC ASC_FF emit ;
: dotted ( -- )                               \ dotted line mode
  ESC [char] a emit ;
: dot-dash ( -- )                             \ . - . - line mode
  ESC [char] b emit ;
: short-dash ( -- )                           \ - - - short dash line mode
  ESC [char] c emit ;
: long-dash ( -- )                            \ -- -- -- long dash line mode
  ESC [char] d emit ;
: solid-line ( -- )                           \ -------- solid line
  ESC [char] ` emit ;
: defocus-solid ( -- )
   ESC [char] h emit ;
: defocus-dotted ( -- )
   ESC [char] i emit ;
: defocus-dot-dash ( -- )
   ESC [char] j emit ;
: defocus-short-dash ( -- )
   ESC [char] k emit ;
: defocus-long-dash ( -- )
   ESC [char] l emit ;
   
: writethru-solid ( -- )
   ESC [char] p emit ;
: writethru-dotted ( -- )
   ESC [char] q emit ;
: writethru-dot-dash ( -- )
   ESC [char] r emit ;
: writethru-short-dash ( -- )
   ESC [char] s emit ;
: writethru-long-dash ( -- )
   ESC [char] t emit ;
: alpha-mode ( -- )
   ASC_US emit ;
: char-size-1 
  ESC [char] 8 emit ;   
: char-size-2 
  ESC [char] 9 emit ;   
: char-size-3 
  ESC [char] : emit ;   
: char-size-4 
  ESC [char] ; emit ;   
: >cpos ( -- key x y )                        \ read position from terminal
   key
   key 32 - 32 *                              \ xh
   key 32 - +                                 \ xl+xh
   key 32 - 32 *                              \ yh
   key 32 - +                                 \ yl + yh
   key drop ;
: cpos ( -- x y )                             \ query current cursor position
   GRAPH emit ESC ASC_ENQ emit
   >cpos rot drop ; 
   
\ display crosshair cursor wait for mouse click return x and y coordinates
: +cpos ( -- x y )                            
   GRAPH ESC ASC_SUB emit >cpos ; 
: screensize74x35 ( -- )
   ESC [char] 8 emit  ;
: screensize81x38 ( -- )
   ESC [char] 9 emit  ;
: screensize121x58 ( -- )
   ESC [char] : emit  ;
: screensize133x63 ( -- )
   ESC [char] ; emit  ;
: movotoxy ( xy -- )
   dup #16 rshift swap $ffff and moveto ;
 
: box.s ( x1 y1 x2 y2 -- )                    \ draw a box from lower left to upper right
   3 pick 3 pick moveto                       \ position begin to x1 y1
   3 pick over   lineto                       \ -> x1 y2
   2dup          lineto                       \ -> x2 y2
   over   3 pick lineto                       \ -> x2 y1
   2drop         lineto ;                     \ -> x1 y1
: box.a ( a -- )                              \ draw a box from lower left to upper right
   dup >R @ R@  4 + @                         \ position begin to x y
   r@ 8 + @ r@  4 + @
   r@ 8 + @ r@ 12 + @
   r@     @ r@ 12 + @
   r@     @ r>  4 + @
   moveto lineto lineto lineto lineto ;
: box.a2 ( a -- )                             \ draw a box from lower left to upper right
   dup @ over 4 + @ moveto                    \ position begin to x y
   dup @ over 12 + @ lineto
   dup 8 + @ over 12 + @ lineto
   dup 8 + @ over 4 + @ lineto
   dup @ swap 4 + @ lineto  ;

: box.movex0y0 ( a -- )
   2@ moveto inline ;
: box.linetox0y1 ( a -- )
   dup @ swap 12 + @ lineto  inline ;
: box.linetox1y1 ( a -- )
   8 + 2@ lineto  inline ;
: box.linetox1y0 ( a -- )
   dup 8 + @ swap 4 + @ lineto inline ;
: box.linetox0y0 ( a -- )
   2@ lineto inline ;

: box.a3 ( a -- )
  dup box.movex0y0
  dup box.linetox0y1
  dup box.linetox1y1
  dup box.linetox1y0
  box.linetox0y0 ;

0 variable box.o.x1
0 variable box.o.y1
0 variable box.o.x2
0 variable box.o.y2
: box.o ( -- )
   box.o.x1 @ box.o.y1 moveto
   box.o.x1 @ box.o.y2 lineto
   box.o.x2 @ box.o.y2 lineto
   box.o.x2 @ box.o.y1 lineto
   box.o.x1 @ box.o.y1 lineto ;
0     variable box.v.x1
0     variable box.v.y1
0     variable box.v.x2
0     variable box.v.y2
0 0 2 nvariable box.v.xy
: box.v ( -- )
  box.v.x1 @ box.v.xy !
  box.v.y1 @ box.v.xy 4 + !
  box.v.xy moveto.a
  box.v.x1 @ box.v.xy !
  box.v.y2 @ box.v.xy 4 + !
  box.v.xy lineto.a
  box.v.x2 @ box.v.xy !
  box.v.y2 @ box.v.xy 4 + !
  box.v.xy lineto.a
  box.v.x2 @ box.v.xy !
  box.v.y1 @ box.v.xy 4 + !
  box.v.xy lineto.a
  box.v.x1 @ box.v.xy !
  box.v.y1 @ box.v.xy 4 + !
  box.v.xy lineto.a ;

 0 0 0 0 4 nvariable box-fill.box
: box-fill-shrink ( a -- )
   1      over +!
   4 +  1 over +!
   4 + -1 over +!
   4 + -1 swap +! ;
: box-fill-shrink? ( a -- f )
  dup @ over 8 + @ <
  swap 4 + dup @ swap 8 + @ < and ;
: box-fill! ( x1 y1 x2 y2 a -- )
   tuck 12 + !
   tuck 8 + !
   tuck 4 + ! ! ;
: box-fill@ ( a -- x1 y1 x2 y2 )
       dup @ swap
   4 + dup @ swap
   4 + dup @ swap
   4 +     @  ;
: box-fill. ( a -- )
  dup @ .
  4 + dup @ .
  4 + dup @ .
  4 + @ . ;
: box-fill ( x1 y1 x2 y2 -- )                 \ fill a box
   box-fill.box dup >R box-fill!
   r>
   dup box-fill@ box.s   
   begin
     dup box-fill-shrink
     dup box-fill@ box.s
     dup box-fill-shrink? not
   until drop ;
: bf. box-fill.box box-fill. ;
: bfb box-fill.box ;   
   
   
: nikolaus ( -- )                             \ draw a nicolaus home 
  100 100 moveto                              \ start from lower left
  200 100 lineto                              \ draw to lower right
  100 200 lineto                              \ draw to upper left
  200 200 lineto                              \ to upper right
  150 250 lineto                              \ to top of the roof
  100 200 lineto                              \ to upper left
  100 100 lineto                              \ to lower left
  200 200 lineto                              \ to upper right
  200 100 lineto CR  ;                        \ close to lower right

: nikolausxy ( x y -- )                       \ draw nicolaus home at x y position
  2dup   0   0 v2-add moveto
  2dup 100   0 v2-add lineto
  2dup   0 100 v2-add lineto
  2dup 100 100 v2-add lineto
  2dup  50 150 v2-add lineto
  2dup   0 100 v2-add lineto
  2dup   0   0 v2-add lineto
  2dup 100 100 v2-add lineto
       100   0 v2-add lineto CR  ;
: field dup constant 4 + ;                    \ create field definitions
0 0 0 0   0 0 0 0  8 nvariable mycircle
0 field c.x0#                                 \ circle center x0
  field c.y0#                                 \ circle center y0
  field c.r#                                  \ circle radius
  field c.rr#                                 \ circle sqare radius
  field c.x#                                  \ working x val
  field c.xx#                                 \ working x square
  field c.y#                                  \ working y
  field c.yy#                                 \ working y square
  constant c.size#                            \ size of circle object in words
: c:x0 ( a -- a ) c.x0# + 1-foldable ;        \ adr circle center x0
: c:y0 ( a -- a ) c.y0# + 1-foldable ;        \ adr circle center y0
: c:r  ( a -- a ) c.r#  + 1-foldable ;        \ adr circle radius
: c:rr ( a -- a ) c.rr# + 1-foldable ;        \ adr circle sqare radius
: c:x  ( a -- a ) c.x#  + 1-foldable ;        \ adr working x val
: c:xx ( a -- a ) c.xx# + 1-foldable ;        \ adr working x square
: c:y  ( a -- a ) c.y#  + 1-foldable ;        \ adr working y
: c:yy ( a -- a ) c.yy# + 1-foldable ;        \ adr working y square

0 variable c.x0
0 variable c.y0
0 variable c.r
0 variable c.rr
0 variable c.x
0 variable c.xx
0 variable c.y
0 variable c.yy

: @1+! ( a -- n ) \ increment value at address and leave new value on stack
  dup ( a a )
  @ ( a n )
  1+ ( a n )
  dup ( a n n )
  rot ( n n a )
  ! ; ( n )
: @1-! ( a -- n ) \ decrement value at address and leave new value on stack
  dup ( a a )
  @ ( a n )
  1- ( a n )
  dup ( a n n )
  rot ( n n a )
  ! ; ( n )
: c.step  ( -- ) \ calc nex xy pixel
   c.y @1+!          ( y+1 -- )
   dup * dup c.yy !  ( yy )
   c.xx @            ( yy xx )
   + c.rr @ >
   if c.x @1-! dup * c.xx !
   then ;

: c.step-a  ( a -- )
   dup >R
   c:y @1+!             ( y+1 -- )
   dup * dup r@ c:yy !  ( yy )
   r@ c:xx @            ( yy xx )
   + r@ c:rr @ >
   if r@ c:x @1-! dup * r@ c:xx !
   then rdrop ;

   
: circle.
  ." x  " c.x  @ . cr   
  ." y  " c.y  @ . cr   
  ." xx " c.xx @ . cr   
  ." yy " c.yy @ . cr   
  ." r  " c.r  @ . cr   
  ." rr " c.rr @ . cr ;
: circle-a.  ( a -- )
  dup >R
  ." x  "    c:x  @ . cr   
  ." y  " r@ c:y  @ . cr   
  ." xx " r@ c:xx @ . cr   
  ." yy " r@ c:yy @ . cr   
  ." r  " r@ c:r  @ . cr   
  ." rr " r> c:rr @ . cr ;
: c.points  ( -- )                            \ draw the points
  c.x0 @ c.x @ + c.y0 @ c.y @ + point \ 
  c.x0 @ c.y @ + c.y0 @ c.x @ + point \ 
  c.x0 @ c.x @ - c.y0 @ c.y @ + point 
  c.x0 @ c.y @ - c.y0 @ c.x @ + point
  c.x0 @ c.x @ - c.y0 @ c.y @ - point 
  c.x0 @ c.y @ - c.y0 @ c.x @ - point
  c.x0 @ c.x @ + c.y0 @ c.y @ - point 
  c.x0 @ c.y @ + c.y0 @ c.x @ - point  ;  
: c.points-a ( a -- )                         \ draw the points
  >R
  r@ c:x0 @ r@ c:x @ + r@ c:y0 @ r@ c:y @ + point \ 
  r@ c:x0 @ r@ c:y @ + r@ c:y0 @ r@ c:x @ + point \ 
  r@ c:x0 @ r@ c:x @ - r@ c:y0 @ r@ c:y @ + point 
  r@ c:x0 @ r@ c:y @ - r@ c:y0 @ r@ c:x @ + point
  r@ c:x0 @ r@ c:x @ - r@ c:y0 @ r@ c:y @ - point 
  r@ c:x0 @ r@ c:y @ - r@ c:y0 @ r@ c:x @ - point
  r@ c:x0 @ r@ c:x @ + r@ c:y0 @ r@ c:y @ - point 
  r@ c:x0 @ r@ c:y @ + r@ c:y0 @ r@ c:x @ - point rdrop ;  

: circle ( x y r -- )
   dup c.r ! dup c.x ! dup * dup c.rr ! c.xx !
   c.y0 ! c.x0 !
   0 c.y !
   begin  c.points c.step
   c.y @ c.x @ > until ;
: circle.init-a ( x y r a )
   >R 
   r@ c:r  !
   r@ c:y0 !
   r@ c:x0 !
   r@ c:r @ r@ c:x !
   r@ c:r @ dup * r@ c:rr !
   r@ c:rr @ r@ c:xx !
   0 r@ c:y  !
   0 r@ c:yy !
   rdrop ;
: circle-a ( a -- )
   >R
   r@ c:r @ dup r@ c:x ! dup * dup r@ c:rr ! r@ c:xx !
   0 dup r@ c:y ! r@ c:yy !
   begin r@ c.points-a r@ c.step-a
   r@ c:y @ r@ c:x @ > until rdrop ;
      
: dnic cls dotted nikolaus ;                  \ draw nicles house with dotted lines
: nxy dnic 400 400 nikolausxy ;               \ draw a dotted nic-house and a one at 400 400
: nics ( n -- )                               \ draw a number of nic-houses in a line
   cls 0 do i 100 * 0 nikolausxy loop ; 
: ynnics ( y n -- )                           \ draw a line of nics at vertical position
   0 do i 100 * over nikolausxy loop ;
: mnics cls 5 0 do i 150 * 10 ynnics loop ;
: defocus-nic cls defocus-dotted nikolaus ;
: ct cls 300 300 300 mycircle circle.init-a mycircle circle-a 100 100 moveto alpha-mode rp@ . ;
: cn 300 300 mycircle c:r @ 1- mycircle circle.init-a mycircle circle-a 100 100 moveto ;
: cd mycircle circle-a. ;
: ctn cls
  300 10 do
    100 500 moveto alpha-mode rp@ . sp@ . i .
    300 300 i mycircle circle.init-a mycircle circle-a
  5 +loop ;
: pos-rel-abs ( dx dy -- x y )
  g-pos-y @ + dup g-pos-y !
  swap g-pos-x @ + dup g-pos-x ! swap ;
: mover ( x y -- ) \ move relative
   pos-rel-abs moveto ;
: liner ( x y -- ) \ move relative
   pos-rel-abs lineto ;

: h-spc 10 0 mover ;   
: I-bar 0 100 liner ;
: bulge 40 0 liner 15 -15 liner 0 -20 liner -15 -15 liner -40 0 liner ;
: BG-A 40 100 liner 40 -100 liner -18 40 mover -48 0 liner 48 18 + -40 mover ;
: BG-B  I-bar bulge bulge 55 0 mover ;
: SM-B  I-bar 0 -50 mover bulge 55 0 mover ;
: BG-P I-bar bulge 55 -50 mover ;
: t-a cls 100 100 moveto BG-A h-spc BG-B h-spc SM-b h-spc BG-P ; 
