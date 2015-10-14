@
@    Mecrisp-Stellaris - A native code Forth implementation for ARM-Cortex M microcontrollers
@    Copyright (C) 2013  Matthias Koch
@
@    This program is free software: you can redistribute it and/or modify
@    it under the terms of the GNU General Public License as published by
@    the Free Software Foundation, either version 3 of the License, or
@    (at your option) any later version.
@
@    This program is distributed in the hope that it will be useful,
@    but WITHOUT ANY WARRANTY; without even the implied warranty of
@    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
@    GNU General Public License for more details.
@
@    You should have received a copy of the GNU General Public License
@    along with this program.  If not, see <http://www.gnu.org/licenses/>.
@

@ Register allocator tools to work with the stack model.

@ -----------------------------------------------------------------------------
generiere_konstante: @ Nimmt Konstante in r3 entgegen, generiert wenn nötig passende Opcodes
                           @ und gibt den Register in r3 zurück, in der sie daraufhin enthalten ist.
@ -----------------------------------------------------------------------------
  push {r0, r1, r2, lr}

  bl generiere_konstante_common

  str r3, [r0, #offset_constant_r0]
  movs r1, #constant
  str r1, [r0, #offset_state_r0]

  movs r3, #0
  pushda r3
  bl registerliteralkomma
  pop {r0, r1, r2, pc}

@ -----------------------------------------------------------------------------
generiere_adresskonstante: @ Nimmt Konstante in r3 entgegen, generiert wenn nötig passende Opcodes
                           @ und gibt den Register in r3 zurück, in der sie daraufhin enthalten ist.
@ -----------------------------------------------------------------------------
  push {r0, r1, r2, lr}

  bl generiere_konstante_common

  str r3, [r0, #offset_constant_r1]
  movs r1, #constant
  str r1, [r0, #offset_state_r1]

  movs r3, #1
  pushda r3
  bl registerliteralkomma
  pop {r0, r1, r2, pc}

@ -----------------------------------------------------------------------------
generiere_konstante_common:
@ -----------------------------------------------------------------------------

  ldr r0, =allocator_base

  @ Prüfe, ob die Konstante schon in r0 liegt. Dann bin ich fertig,
  ldr r1, [r0, #offset_state_r0]
  cmp r1, #unknown
  beq 1f
    ldr r1, [r0, #offset_constant_r0]
    cmp r1, r3
    bne 1f
      movs r3, #0
      pop {r0, r1, r2, pc}
1:@ Die gesuchte Konstante ist nicht in r0.


  @ Prüfe, ob die Konstante schon in r1 liegt. Dann bin ich fertig,
  ldr r1, [r0, #offset_state_r1]
  cmp r1, #unknown
  beq 1f
    ldr r1, [r0, #offset_constant_r1]
    cmp r1, r3
    bne 1f
      movs r3, #1
      pop {r0, r1, r2, pc}
1:@ Die gesuchte Konstante ist nicht in r1.

  @ Die Konstante muss generiert werden. Springe also zurück:
  pushda r3
  bx lr

@ -----------------------------------------------------------------------------
put_element_in_register: @ Element, welches bearbeitet werden soll, in r3 ankündigen
@ -----------------------------------------------------------------------------
  push {r1, r2, lr}
  adds r3, r0
  @ r3: Adresse des Elements
  @ r2: Konstante

  ldr r1, [r3] @ Element holen

  cmp r1, #constant
  bne 3f
    @ Das Element ist eine Konstante. Prüfe, ob sie schon in r0 oder r1 bereitliegt:
    ldr r2, [r3, #4] @ Hole die Konstante
  
  @ Prüfe, ob die Konstante schon in r0 liegt. Dann bin ich fertig,
  ldr r1, [r0, #offset_state_r0]
  cmp r1, #unknown
  beq 1f
    ldr r1, [r0, #offset_constant_r0]
    cmp r1, r2
    bne 1f
      @ Konstante ist schon in r0:
      pushdaconstw 0x4600 @ mov r0, r0
      b 2f

1:@ Die gesuchte Konstante ist nicht in r0.


  @ Prüfe, ob die Konstante schon in r1 liegt. Dann bin ich fertig,
  ldr r1, [r0, #offset_state_r1]
  cmp r1, #unknown
  beq 1f
    ldr r1, [r0, #offset_constant_r1]
    cmp r1, r2
    bne 1f
      @ Konstante ist schon in r1:
      pushdaconstw 0x4600 | 1 << 3 @ mov r0, r1

2:    bl get_free_register
      str r3, [r2]
      orrs tos, r3
      bl hkomma
      pop {r1, r2, pc}

1:@ Die gesuchte Konstante ist nicht in r1.

  @ Dann generiere sie direkt in den gewünschten Register:
  pushda r2 @ Konstante
  
  movs r1, r3 @ r3 freiräumen - kann vielleicht später noch die Register umsortieren

  bl get_free_register
  str r3, [r1]
  pushda r3 @ Zielregister

  bl registerliteralkomma

3:pop {r1, r2, pc}

  .ltorg

@ -----------------------------------------------------------------------------
get_free_register: @ Gibt den Register in r3 zurück. Setzt noch keinen Zustand.
@ -----------------------------------------------------------------------------
  push {r0, r1, r2, lr}

  ldr r0, =allocator_base
  ldr r1, [r0, #offset_state_tos]
  ldr r2, [r0, #offset_state_nos]
  ldr r3, [r0, #offset_state_3os]

  @ Prüfe r6 auf Freiheit:
  cmp r1, #6
  beq 1f
  cmp r2, #6
  beq 1f
  cmp r3, #6
  beq 1f
    @ r6 ist frei :-)
    movs r3, #6
    pop {r0, r1, r2, pc}
1:

  @ r6 ist schon vergeben. r3 ?
  cmp r1, #3
  beq 2f
  cmp r2, #3
  beq 2f
  cmp r3, #3
  beq 2f

    @ r3 ist frei :-)
    movs r3, #3
    pop {r0, r1, r2, pc}
2:

  @ r6 und r3 sind vergeben, so bleibt nur noch r2 übrig.
  movs r3, #2
  pop {r0, r1, r2, pc}


@ -----------------------------------------------------------------------------
fill_element_from_stack: @ Füllt eins der Cacheelemente TOS, NOS oder 3OS vom Stack nach, falls darin Leere herrscht.
                         @ Erwartet Zustandsvariable in r0.
@ -----------------------------------------------------------------------------
  push {lr}
  @writeln "Fill-element aus dem Stack"

  @ Welcher Register ist frei ? Eventuelle Konstanten wären jetzt schon bearbeitet, muss also nur r0 behalten.
  bl get_free_register
  str r3, [r0] @ Element mit diesem Register als belegt markieren

  movs r1, #1
  lsls r1, r3 @ Registermaske für den LDM-Opcode generieren

  pushdaconstw 0xCF00 @ ldm r7!, { ... }
  orrs tos, r1
  bl hkomma
  pop {pc}


@ -----------------------------------------------------------------------------
expect_one_element: @ Sorgt dafür, dass mindestens ein Element bereitliegt.
@ -----------------------------------------------------------------------------
  push {r0, r1, r2, r3, lr}

  @ Kernfrage besteht darin: Ist TOS belegt oder nicht ?
  @ Wenn ja, fertig. Wenn nein, sind auch NOS und 3OS leer, also TOS direkt vom Stack nachfüllen.

  ldr r0, =allocator_base
  ldr r1, [r0, #offset_state_tos]
  cmp r1, #unknown
  bne 1f @ Wenn schon etwas in TOS enthalten ist, bin ich fertig.

    ldr r0, =state_tos
    bl fill_element_from_stack

1: pop {r0, r1, r2, r3, pc}


@ -----------------------------------------------------------------------------
expect_two_elements: @ Sorgt dafür, dass mindestens zwei Elemente bereitliegen.
@ -----------------------------------------------------------------------------
  push {r0, r1, r2, r3, lr}

  @ Ist NOS belegt ? Wenn ja --> Fertig.
  @ Wenn nein: Erstmal TOS belegen, falls nötig, dann NOS.

  ldr r0, =allocator_base
  ldr r1, [r0, #offset_state_nos]
  cmp r1, #unknown
  bne 1f @ Wenn schon etwas in NOS enthalten ist, bin ich fertig.

    @ NOS ist nicht belegt. Belege also TOS, falls noch nicht geschehen:
    bl expect_one_element

    @ Fülle NOS vom Stack nach:

    ldr r0, =state_nos
    bl fill_element_from_stack

1: pop {r0, r1, r2, r3, pc}

@ Hier lassen sich jetzt auch gemütlich ldm-Bündelungen einführen.

@ -----------------------------------------------------------------------------
expect_three_elements: @ Sorgt dafür, dass mindestens drei Elemente bereitliegen.
@ -----------------------------------------------------------------------------
  push {r0, r1, r2, r3, lr}

  @ Ist 3OS belegt ? Wenn ja --> Fertig.
  @ Wenn nein: Erstmal TOS und NOS belegen, falls nötig, dann 3OS.

  ldr r0, =allocator_base
  ldr r1, [r0, #offset_state_3os]
  cmp r1, #unknown
  bne 1f @ Wenn schon etwas in NOS enthalten ist, bin ich fertig.

    @ NOS ist nicht belegt. Belege also TOS, falls noch nicht geschehen:
    bl expect_two_elements

    @ Fülle 3OS vom Stack nach:

    ldr r0, =state_3os
    bl fill_element_from_stack

1: pop {r0, r1, r2, r3, pc}


 .ltorg

@ -----------------------------------------------------------------------------
expect_tos_in_register: @ Sorgt dafür, dass TOS auf jeden Fall einem Register liegt,
                        @ welcher in r1 zurückgegeben wird.
@ -----------------------------------------------------------------------------
  push {lr}

    @ Sollte jetzt TOS eine Konstante sein, so wird sie geladen.

    ldr r1, [r0, #offset_state_tos]
    cmp r1, #constant
    bne 4f
      ldr r3, [r0, #offset_constant_tos] @ Hole die Konstante ab
      bl generiere_konstante
      movs r1, r3

4:  @ Beide Argumente sind jetzt in Registern.
  pop {pc}


@ -----------------------------------------------------------------------------
expect_nos_in_register: @ Sorgt dafür, dass NOS auf jeden Fall einem Register liegt,
                        @ welcher in r1 zurückgegeben wird.
@ -----------------------------------------------------------------------------
  push {lr}

    @ Sollte jetzt NOS eine Konstante sein, so wird sie geladen.

    ldr r1, [r0, #offset_state_nos]
    cmp r1, #constant
    bne 4f
      ldr r3, [r0, #offset_constant_nos] @ Hole die Konstante ab
      bl generiere_konstante
      movs r1, r3

4:  @ Beide Argumente sind jetzt in Registern.
  pop {pc}

@ -----------------------------------------------------------------------------
nos_change_tos_away_later: @ NOS wird jetzt verändert, TOS danach freigegeben.
@ -----------------------------------------------------------------------------
  @ Agenda:
  @ Zwei Elemente bereithalten (vorher schon passiert)
  @ Prüfen, ob die Register für NOS und 3OS zufällig identisch sind
  @   --> Registerkopie anfertigen

  @ r0 soll die allocator_base enthalten !
  push {r1, r2, r3, lr}

  ldr r2, [r0, #offset_state_nos]
  ldr r3, [r0, #offset_state_3os]
  cmp r2, r3
  bne.n 1f

    @ Identisch. Sind es Register ?
    cmp r2, #7
    bhi 1f

      @ Ja, es sind beides Register. Mache für NOS einen Registerwechsel, möglichst in r6 hinein.
      pushdatos
      lsls tos, r2, #3 @ Quellregister
      bl get_free_register
      orrs tos, r3 @ Zielregister
      str r3, [r0, #offset_state_nos]
      bl hkomma

1:pop {r1, r2, r3, pc}

@ -----------------------------------------------------------------------------
make_tos_changeable: @ Lege eine Elementkopie an, falls TOS woanders schon belegt ist.
@ -----------------------------------------------------------------------------
  @ r0 soll die allocator_base enthalten !
  push {r1, r2, r3, lr}

  ldr r1, [r0, #offset_state_tos]
  ldr r2, [r0, #offset_state_nos]
  ldr r3, [r0, #offset_state_3os]

  cmp r1, r2
  beq 1f
  cmp r1, r3
  beq 1f
    pop {r1, r2, r3, pc}

1: @ Registerwechsel mit Elementkopie für TOS.

      pushdatos
      lsls tos, r1, #3 @ Quellregister
      bl get_free_register
      orrs tos, r3 @ Zielregister
      str r3, [r0, #offset_state_tos]
      bl hkomma

    pop {r1, r2, r3, pc}

@ -----------------------------------------------------------------------------
tos_registerwechsel: @ Wechselt den TOS-Register, gibt diesen in r3 zurück
@ -----------------------------------------------------------------------------
  push {lr}
  @ Registerwechsel direkt im Opcode. Nutze das natürlich aus :-) Spare mir damit eventuelle Elementkopien.
  bl eliminiere_tos
  bl befreie_tos
  bl get_free_register
  str r3, [r0, #offset_state_tos]
  pop {pc}

