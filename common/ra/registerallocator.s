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

@ Register allocator

.equ reg2, 2
.equ reg3, 3
.equ reg6, 6

.equ unknown, 30
.equ constant, 40

@ Mögliche Konfigurationen der Stack-Cache-Register:

@ ( Stack |             | Faltkonstanten )
@ ( Stack |         TOS | Faltkonstanten )  Normalzustand, Anfang und Ende
@ ( Stack |     NOS TOS | Faltkonstanten )
@ ( Stack | 3OS NOS TOS | Faltkonstanten )

@ Im Prinzip kann ich nachrutschen lassen, um Füllung anzustreben. Lässt sich vielleicht später noch optimieren.
@ Am Anfang werden Faltkonstanten eingelesen, erst wenn diese Option leer ist, geht es direkt an den Stack.


@ -----------------------------------------------------------------------------
nflush_faltkonstanten: @ Schiebe alle vorhandenen Faltkonstanten in den RA-Cache.
@ -----------------------------------------------------------------------------
  push {r0, r1, r2, lr}
  ldr r0, =allocator_base

  @ Frage Nummer eins: Haben wir noch Faltkonstanten ? Die müssen unbedingt zwischengeschoben werden.
1:cmp r3, #0
  beq 2f
    @ writeln "Flush Konstante in RA-Cache"
    @ Ja, es ist noch mindestens eine Faltkonstante da.
    @ Die wird nun in den Stack eingefügt:

    bl free_3os_element @ Als erstes hinten Platz schaffen.
    bl elemente_einen_weiterrutschen_lassen
    bl nget_faltkonstante @ Gibt diese in r2 zurück, erniedrigt r3 von selbst

    str r2, [r0, #offset_constant_tos]
    movs r1, #constant
    str r1, [r0, #offset_state_tos]
    b 1b

2:@ Alle Faltkonstanten sind abgearbeitet.
  pop {r0, r1, r2, pc}


@ -----------------------------------------------------------------------------
nfaltkonstanten_aufschwimmen: @ Sollten an der Oberfläche des RA-Cache Konstanten aufschwimmen
                             @ werden diese am Ende wieder als Faltkonstanten zur Verfügung gestellt.
@ -----------------------------------------------------------------------------

  push {r0, r1, r2, lr}
  ldr r0, =allocator_base

1:ldr r1, [r0, #offset_state_tos]
  cmp r1, #constant
  bne 2f
    @ writeln "Eine Konstante schwimmt auf"
    @ Es ist eine Faltkonstante da, lasse sie aufschwimmen !
    ldr r2, [r0, #offset_constant_tos]
    bl npush_faltkonstante
    bl eliminiere_tos
    b 1b

2:@ Fertig, oben auf dem RA-Cache sind keine Konstanten mehr.
  pop {r0, r1, r2, pc}


@ -----------------------------------------------------------------------------
npush_faltkonstante: @ Füge von unten (!) eine Faltkonstante ein !
                    @ Dies ist nötig, falls Stackjongleure eine Konstante wieder an die Oberfläche strudeln lassen.
                    @ Annahme in r2.
@ -----------------------------------------------------------------------------
  push {r0, r1, lr}

  pushda r2
  pushda r3
  push {r3}
  bl minusroll
  pop {r3}
  adds r3, #1

  pop {r0, r1, pc}


@ -----------------------------------------------------------------------------
nget_faltkonstante: @ Hole von unten (!) eine Faltkonstante ab !
                   @ Anzahl der vorhandenen Konstanten (noch) in r3.
                   @ Rückgabe in r2.
@ -----------------------------------------------------------------------------
  push {r0, r1, lr}

  subs r3, #1
  pushda r3
  push {r3}
  bl roll
  pop {r3}
  popda r2

  pop {r0, r1, pc}

@ -----------------------------------------------------------------------------
free_3os_element: @ Sorgt dafür, dass zumindest 3OS geleert ist.
@ -----------------------------------------------------------------------------
  push {r0, r1, lr}
  ldr r0, =state_3os

  ldr r1, [r0]
  cmp r1, #unknown
  beq 1f @ Wenn das 3OS-RA-Element gerade leer ist, brauche ich nichts mehr zu tun.
    bl element_to_stack

1:pop {r0, r1, pc}


@ -----------------------------------------------------------------------------
elemente_einen_weiterrutschen_lassen:
@ -----------------------------------------------------------------------------
    @ NOS --> 3OS
    @ TOS --> NOS
    @ TOS "leeren"

    ldr r1, [r0, #offset_state_nos]
    str r1, [r0, #offset_state_3os]
    ldr r1, [r0, #offset_state_tos]
    str r1, [r0, #offset_state_nos]

    ldr r1, [r0, #offset_constant_nos]
    str r1, [r0, #offset_constant_3os]
    ldr r1, [r0, #offset_constant_tos]
    str r1, [r0, #offset_constant_nos]

    movs r1, #unknown
    str r1, [r0, #offset_state_tos]

  bx lr

@ -----------------------------------------------------------------------------
befreie_tos: @ Sorgt dafür, dass zumindest TOS frei wird zum Neubelegen.
@ -----------------------------------------------------------------------------
  push {r0, r1, r2, r3, lr}

  @ Jetzt frage ich mich: Ist TOS gerade leer und unbelegt ?
  ldr r0, =allocator_base
  ldr r1, [r0, #offset_state_tos]
  cmp r1, #unknown
  beq 3f @ Wenn das TOS-RA-Element gerade leer ist, brauche ich nichts mehr zu tun.

    @ Ansonsten muss ich nochmal dafür sorgen, dass TOS frei wird.
    bl free_3os_element @ Als erstes hinten Platz schaffen.
    bl elemente_einen_weiterrutschen_lassen

3:@ Fertig. TOS ist bereit für neue Taten.
  pop {r0, r1, r2, r3, pc}


@ -----------------------------------------------------------------------------
element_to_stack: @ Erwartet Zustandsvariable in r0
@ -----------------------------------------------------------------------------
  push {r3, lr} @ r3 muss für flush_faltkonstanten gesichert werden

  ldr r1, [r0] @ Zustand des Elementes holen

  @ Elementbelegung löschen, es wird hier ja restlos abgearbeitet
  movs r2, #unknown
  str  r2, [r0]

  @ Register in den Speicher schreiben:
  cmp r1, #8 @ Register 0-7 lassen sich direkt opcodieren.
  bhs 1f

    @ Platz auf dem Stack schaffen   ACHTUNG M3/M4: Das lässt sich in einen Opcode zusammenfassen !
    pushdaconstw 0x3f04  @ subs psp, #4
    bl hkomma

    @ Element = Register    --> Register in Speicher
    @write "ets r"
    @pushda r1
    @bl hexdot

    pushdaconstw 0x6000|0 << 6|7 << 3|0  @ str r0, [psp, #0]
    orrs tos, r1 @ Zielregister hinzuverodern
    bl hkomma
    pop {r3, pc}

1:@ Element = Konstante --> Konstante in Speicher
  cmp r1, #constant
  bne 1f @ Für den Fall eines unbekannten Elementes nichts tun

    @writeln "ets const"

    @ Platz auf dem Stack schaffen
    pushdaconstw 0x3f04  @ subs psp, #4
    bl hkomma

    @ Hole die Konstante, und prüfe, ob sie zur Laufzeit bereits in r0 oder r1 sein wird.
    ldr r3, [r0, #4] @ Konstante holen, stets 4 Bytes nach dem Zustand
    bl generiere_konstante
    @ Passender Register für die Konstante in r3. Lade den Register auf den Stack !

    pushdaconstw 0x6000|0 << 6|7 << 3|0  @ str r0, [psp, #0]
    orrs tos, r3 @ Passenden Register hinzuverodern
    bl hkomma

1: pop {r3, pc}


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



@ Optimierung für später: LDM-Sammelabholung !
@ Erstmal aber einfach einen funktionierenden, simplen Fall implementieren.

@ Am Ende der Operationen ist stets einer der Fälle da: x x x | x x TOS | x NOS TOS | 3OS NOS TOS
@ Sorge dafür, dass es ordentlich bleibt. So wird es hier ziemlich einfach.

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
eliminiere_tos: @ Wert ist verbraucht, kann weg !
@ -----------------------------------------------------------------------------
  push {r0, r1, lr}
  ldr r0, =allocator_base

  ldr r1, [r0, #offset_state_nos]
  str r1, [r0, #offset_state_tos]
  ldr r1, [r0, #offset_constant_nos]
  str r1, [r0, #offset_constant_tos]
  b 1f

@ -----------------------------------------------------------------------------
eliminiere_nos: @ Wert ist verbraucht, kann weg !
@ -----------------------------------------------------------------------------
  push {r0, r1, lr}
  ldr r0, =allocator_base

1:ldr r1, [r0, #offset_state_3os]
  str r1, [r0, #offset_state_nos]
  ldr r1, [r0, #offset_constant_3os]
  str r1, [r0, #offset_constant_nos]

  movs r1, #unknown
  str r1, [r0, #offset_state_3os]

  pop {r0, r1, pc}

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
  Wortbirne Flag_visible, "allocator" @ Beim Einsprung ist normales Falten bereits nicht mehr möglich.
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

@ -----------------------------------------------------------------------------
  Wortbirne Flag_visible, "tidyup-ra"
tidyup_register_allocator: @ Generiert all die Opcodes, um den Stack wieder in Ordnung zu bringen
@ -----------------------------------------------------------------------------
  push {lr}
  bl tidyup_register_allocator_3os
  bl tidyup_register_allocator_nos
  bl tidyup_register_allocator_tos
  pop {pc}


@ -----------------------------------------------------------------------------
tidyup_register_allocator_3os:
@ -----------------------------------------------------------------------------
  push {r0, r1, r2, r3, lr}
  ldr r0, =state_3os
  bl element_to_stack @ Idee: Hier gleich zwei Stackplätze reservieren, denn schließlich ist NOS auch belegt, wenn 3OS belegt ist.
  pop {r0, r1, r2, r3, pc}

@ -----------------------------------------------------------------------------
tidyup_register_allocator_nos:
@ -----------------------------------------------------------------------------
  push {r0, r1, r2, r3, lr}
  ldr r0, =state_nos
  bl element_to_stack @ Idee: Hier gleich zwei Stackplätze reservieren, denn schließlich ist NOS auch belegt, wenn 3OS belegt ist.
  pop {r0, r1, r2, r3, pc}


@ -----------------------------------------------------------------------------
tidyup_register_allocator_tos:
@ -----------------------------------------------------------------------------
  push {r0, r1, r2, r3, lr}
  @ -----------------------------------------------------------------------------
  @ Schließe mit TOS ab:
@  writeln "Tidyup TOS"
  @ Nachher die Sintflut ! Nichts mehr sichern oder schön bereitlegen. Nur noch TOS in Ordnung bringen.

  ldr r0, =allocator_base
  ldr r1, [r0, #offset_state_tos]

  movs r2, #6 @ Das ist der Endzustand, der hier auf jeden Fall erreicht wird !
  str r2, [r0, #offset_state_tos]

  @ Diese Fälle gibt es:
  @ r2 und r3: movs Opcode generieren (Zerstört momentan noch die Flags)
  @ r6: Nichts tun (Erhält die Flags)
  @ Konstante: registerliteral direkt in r6 (oder notfalls aus r0/r1 generieren) (Zerstört die Flags, falls die Konstante neu generiert wird)
  @ unknown: Nachladen (Erhält die Flags)

  cmp r1, #unknown
  bne 1f
    @ TOS = unknown    --> Register vom Stack nachladen
    pushdaconstw 0xCF00 | 1 << 6 @ ldm r7!, {r6}
    bl hkomma
    b.n tidyup_finish
1:


  cmp r1, #constant
  bne 2f
@    writeln "Tidyup TOS Konstante"
    @ TOS = Konstante --> Entweder Konstantenregister benutzen oder direkt laden.
    @ Hier mal vereinfachen, später mit r0/r1-Berücksichtigung:
    ldr r3, [r0, #offset_constant_tos]

    @ Finde heraus, ob diese Konstante schon in r0 oder r1 gerade enthalten ist.
    ldr r1, [r0, #offset_state_r0]
    cmp r1, #unknown
    beq 4f @ Ist die Konstante gesetzt ?
      ldr r1, [r0, #offset_constant_r0]
      cmp r3, r1 @ Stimmt sie ?
      bne 4f
        pushdaconstw 0x4606 @ movs r6, r0
        bl hkomma
        b.n tidyup_finish
4:

    @ In r0 war die Konstante nicht, versuche es nochmal mit r1:
    ldr r1, [r0, #offset_state_r1]
    cmp r1, #unknown
    beq 5f @ Ist die Konstante gesetzt ?
      ldr r1, [r0, #offset_constant_r1]
      cmp r3, r1 @ Stimmt sie ?
      bne 5f
        pushdaconstw 0x460E @ movs r6, r1
        bl hkomma
        b.n tidyup_finish
5:

    @ Die Konstantenregister helfen gerade auch nicht weiter, muss den Wert direkt generieren.
    pushda r3
    pushdaconst 6
    bl registerliteralkomma @ Dies ist der Fall, in dem die Flags immer noch zerstört werden. ACHTUNG.
    b.n tidyup_finish
2:


  @ Jetzt bleiben nur noch die Register übrig.
  cmp r1, #6  @ r6 ist wunderbar, dann ist nichts mehr zu tun.
  beq 3f
@    writeln "Tidyup TOS anderer Register"
    pushdaconstw 0x4600|0 << 3|6  @ movs r6, r0
    lsls r1, #3
    orrs tos, r1 @ Quellregister hinzuverodern
    bl hkomma

3:


tidyup_finish:
  bl init_register_allocator
  pop {r0, r1, r2, r3, pc}


@ -----------------------------------------------------------------------------
  Wortbirne Flag_visible, "initregisterallocator"
init_register_allocator:
@ -----------------------------------------------------------------------------

  ldr r0, =allocator_base

  movs r1, #unknown
  str r1, [r0, #offset_state_r0]
  str r1, [r0, #offset_state_r1]
  str r1, [r0, #offset_state_3os]
  str r1, [r0, #offset_state_nos]

  movs r1, #reg6
  str r1, [r0, #offset_state_tos]

  movs r1, #0
  str r1, [r0, #offset_sprungtrampolin]

  bx lr

 @ .include "../common/ra-debug.s"
