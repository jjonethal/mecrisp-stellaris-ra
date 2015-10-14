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

@ Register allocator main. Perform various optimisations.

@ -----------------------------------------------------------------------------
@ Wortbirne Flag_visible, "allocator" @ Beim Einsprung ist normales Falten bereits nicht mehr möglich.
register_allocator:                   @ Alle Konstanten sind in den RA-Cache geschoben.
@ -----------------------------------------------------------------------------

  @ Register enthalten nun:
  @ r1: Flagfeld
  @ r2: Einsprungadresse
  @ r3: Zahl der vorhandenen Faltkonstanten = 0

  @ Wenn ich hier ankomme, sind alle Faltmöglichkeiten ausgeschöpft.

  push {r0, r1, r2, r3, lr}

  @writeln "Allocator Einsprung"
  @bl view_register_allocator

  @ Alle Faltkonstanten sind jetzt im RA-Cache.

  @ Opcode oder der Allokatoreinsprung  ist am Ende der Definition
  movs r0, r2
  bl suchedefinitionsende
  movs r2, r0

  pushdatos @ Hole den Opcode
  ldrh tos, [r2]

  @ Maskiere jetzt den Allokator-Fall:
  lsrs r1, #12 @ Den Fall vergleichsfreundlich legen @ Achtung mit dem Sichtbar-Flag

  ldr r0, =allocator_base

  @ r0: allocator_base
  @ r1: Fall
  @ r2: Zeiger auf das Anhängsel, falls noch etwas anderes benötigt wird
  @ Auf dem Stack: Der erste Opcode des Anhängsels

  @ -----------------------------------------------------------------------------
  cmp r1, #3
  beq alloc_kommutativ_ohneregister
  @ -----------------------------------------------------------------------------
  cmp r1, #4
  beq alloc_unkommutativ_ohneregister
  @ -----------------------------------------------------------------------------
    drop @ Den schon geholten Opcode wieder vergessen - wir brauchen ihn hier nicht...
    adds r2, #1 @ One more for Thumb
    blx r2

    pop {r0, r1, r2, r3, pc}



@ Sondereinsprünge, die für Memory Read-Modify-Write und die Schiebebefehle gebraucht werden.

@ -----------------------------------------------------------------------------
alloc_kommutativ:
@ -----------------------------------------------------------------------------
  push {r0, r1, r2, r3, lr}
alloc_kommutativ_ohneregister:

      bl expect_two_elements

    @ Jetzt sind mindestens zwei Element in den Registern, also TOS und NOS gefüllt.
    @ Der Fall, dass beide Konstanten sind tritt nicht auf, weil er von der Faltung bereits erledigt wird.
    @ Entweder zwei Register, oder eine Konstante und einen Register.


    @ Sorge dafür, dass NOS (nachher das neue TOS) r6 bekommt, falls möglich.

    ldr r1, [r0, #offset_state_tos]
    cmp r1, #reg6         @ Falls das aktuelle TOS gerade r6 hat, gib es an NOS ab.
    bne 2f
      bl swap_allocator
2:


    @ Sorge jetzt einmal dafür, dass falls es eine Konstante gibt, im RA-Cache TOS die Konstante und NOS das Ziel ist.

    ldr r2, [r0, #offset_state_nos]
    cmp r2, #constant     @ NOS ist die Konstante ?
    bne 3f
      bl swap_allocator   @ Ab jetzt ist es TOS !
3:

    .ifndef m0core
      ldr r1, [r0, #offset_state_tos] @ Prüfe, ob TOS eine Konstante ist.
      cmp r1, #constant
      bne 6f
        @ TOS ist eine Konstante.
        pushdatos
        ldr tos, [r0, #offset_constant_tos]
        bl twelvebitencoding @ Hole sie und prüfe, ob sie als Imm12 darstellbar ist.
        ldmia psp!, {r1} @ Entweder die Bitmaske oder wieder die Konstante

        cmp tos, #0
        drop   @ Preserves Flags !
        beq 6f
          @ Die Konstante lässt sich als Imm12 darstellen - fein ! Bitmaske liegt in r1 bereit
          @ Prüfe nun den Opcode, und ersetze ihn, falls möglich.


          cmp tos, #0x4000 @ ands r0, r0 Opcode
          bne 5f
            ldr tos, =0xF0100000 @ ands r0, r0, #Imm12
            b.n m3_opcodieren
5:

          ldr r2, =0x4040 @ eors r0, r0      Opcode
          cmp tos, r2
          bne 5f
            ldr tos, =0xF0900000 @ eors r0, r0, #Imm12
            b.n m3_opcodieren
5:


          cmp tos, #0x4300 @ orrs r0, r0      Opcode
          bne 5f
            ldr tos, =0xF0500000 @ orrs r0, r0, #Imm12
            b.n m3_opcodieren
5:



6:    @ Sonderopcodierungen M3/M4 nicht möglich
    .endif

    @ Sorge dafür, dass NOS bereit zum Verändern wird.
    bl nos_change_tos_away_later

    bl expect_tos_in_register

    lsls r1, #3  @ Quellregister ist um 3 Stellen geschoben
    ldr r2, [r0, #offset_state_nos]

    @ Baue jetzt den Opcode zusammen:

    orrs tos, r1
    orrs tos, r2

    bl hkomma

    bl eliminiere_tos
    pop {r0, r1, r2, r3, pc}

.ifndef m0core

m3_opcodieren_anderswo:
  push {r0, r1, r2, r3, lr}
@ -----------------------------------------------------------------------------
m3_opcodieren:
@ -----------------------------------------------------------------------------
          @ Gemeinsamer Teil für alle Fälle:
          orrs tos, r1 @ Bitmaske für Imm12 hinzufügen

          ldr r1, [r0, offset_state_nos] @ NOS dann der Faltung wegen unbedingt ein Register.

          orrs tos, tos, r1, lsl #16 @ Quellregister hinzufügen

          @ Vergiß die Konstante
          bl eliminiere_tos

          @ Registerwechsel direkt im Opcode. Nutze das natürlich aus :-) Spare mir damit eventuelle Elementkopien.
          bl eliminiere_tos

          bl befreie_tos
          bl get_free_register
          str r3, [r0, #offset_state_tos]

          orrs tos, tos, r3, lsl #8  @ Den Zielregister hinzufügen

          bl reversekomma
          pop {r0, r1, r2, r3, pc}
.endif

@ -----------------------------------------------------------------------------
alloc_unkommutativ:
@ -----------------------------------------------------------------------------
  push {r0, r1, r2, r3, lr}
alloc_unkommutativ_ohneregister:
    bl expect_two_elements

    @ Jetzt sind mindestens zwei Element in den Registern, also TOS und NOS gefüllt.
    @ Der Fall, dass beide Konstanten sind tritt nicht auf, weil er von der Faltung bereits erledigt wird.
    @ Entweder zwei Register, oder eine Konstante und einen Register.

    .ifndef m0core
      ldr r1, [r0, #offset_state_tos] @ Prüfe, ob TOS eine Konstante ist.
      cmp r1, #constant
      bne 6f
        @ TOS ist eine Konstante.
        pushdatos
        ldr tos, [r0, #offset_constant_tos]
        bl twelvebitencoding @ Hole sie und prüfe, ob sie als Imm12 darstellbar ist.
        ldmia psp!, {r1} @ Entweder die Bitmaske oder wieder die Konstante

        cmp tos, #0
        drop   @ Preserves Flags !
        beq 6f
          @ Die Konstante lässt sich als Imm12 darstellen - fein ! Bitmaske liegt in r1 bereit
          @ Prüfe nun den Opcode, und ersetze ihn, falls möglich.

          ldr r2, =0x4380 @ bics r0, r0      Opcode
          cmp tos, r2
          bne 6f
            @ Ja, den Opcode kann ich verlängern und dann einfügen !
            ldr tos, =0xF0300000 @ bics r0, r0, #Imm12
            b.n m3_opcodieren

6:    @ Sonderopcodierungen M3/M4 nicht möglich
    .endif

    @ Sorge dafür, dass NOS bereit zum Verändern wird.
    bl nos_change_tos_away_later

    bl expect_tos_in_register

    @ Sollte jetzt NOS eine Konstante sein, so wird sie gleich in den richtigen Register geladen.
    @ Schließlich trägt NOS nachher das Ergebnis.

    ldr r2, [r0, #offset_state_nos]
    cmp r2, #constant
    bne 5f
      pushdatos
      ldr tos, [r0, #offset_constant_nos] @ Hole die Konstante ab
      bl get_free_register
      str r3, [r0, #offset_state_nos]
      pushda r3
      movs r2, r3
      bl registerliteralkomma

5:  @ Beide Argumente sind jetzt in Registern.

    lsls r1, #3  @ Quellregister ist um 3 Stellen geschoben

    @ Baue jetzt den Opcode zusammen:

    orrs tos, r1
    orrs tos, r2

    bl hkomma

    bl eliminiere_tos
    pop {r0, r1, r2, r3, pc}

  .ltorg
