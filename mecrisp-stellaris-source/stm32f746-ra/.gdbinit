target remote localhost:3333
monitor reset halt 
display /10i $pc
display /x $r6
display /x $r0
display /x $r1
display /x $r2
display /x $r3
display /x $r4
display /x $r5
display /x $r7
display /x *$r7

