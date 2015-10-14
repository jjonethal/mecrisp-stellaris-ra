 
@ -----------------------------------------------------------------------------
  Wortbirne Flag_visible, "printstate"
print_element_state: @ ( State -- )
@ -----------------------------------------------------------------------------
  push {lr}
  cmp tos, #unknown
  bne 1f
  write "unknown"
1:

  cmp tos, #reg2
  bne 1f
  write "r2"
1:

  cmp tos, #reg3
  bne 1f
  write "r3"
1:

  cmp tos, #reg6
  bne 1f
  write "r6"
1:

  cmp tos, #constant
  bne 1f
  write "constant"
1:

  drop
  pop {pc}


@ -----------------------------------------------------------------------------
  Wortbirne Flag_visible, "vr"
view_register_allocator:
vr:
@ -----------------------------------------------------------------------------
  push {r0, r1, r2, r3, lr}

  write "TOS: "
  ldr r1, =state_tos
  ldr r0, [r1]
  pushda r0
  bl print_element_state
  write " Const: "
  ldr r1, =constant_tos
  ldr r0, [r1]
  pushda r0
  bl hexdot
  writeln ""

  write "NOS: "
  ldr r1, =state_nos
  ldr r0, [r1]
  pushda r0
  bl print_element_state
  write " Const: "
  ldr r1, =constant_nos
  ldr r0, [r1]
  pushda r0
  bl hexdot
  writeln ""

  write "3OS: "
  ldr r1, =state_3os
  ldr r0, [r1]
  pushda r0
  bl print_element_state
  write " Const: "
  ldr r1, =constant_3os
  ldr r0, [r1]
  pushda r0
  bl hexdot
  writeln ""

  write "R0: "
  ldr r1, =state_r0
  ldr r0, [r1]
  pushda r0
  bl print_element_state
  write " Const: "
  ldr r1, =constant_r0
  ldr r0, [r1]
  pushda r0
  bl hexdot
  writeln ""

  write "R1: "
  ldr r1, =state_r1
  ldr r0, [r1]
  pushda r0
  bl print_element_state
  write " Const: "
  ldr r1, =constant_r1
  ldr r0, [r1]
  pushda r0
  bl hexdot
  writeln ""

  writeln ""
  pop {r0, r1, r2, r3, pc}

