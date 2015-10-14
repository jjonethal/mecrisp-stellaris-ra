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

@ Register allocator infrastructure. Maintain stack model.

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
eliminiere_tos: @ Wert ist verbraucht, kann weg !
@ -----------------------------------------------------------------------------
  push {r1, lr}

  ldr r1, [r0, #offset_state_nos]
  str r1, [r0, #offset_state_tos]
  ldr r1, [r0, #offset_constant_nos]
  str r1, [r0, #offset_constant_tos]
  b 1f

@ -----------------------------------------------------------------------------
eliminiere_nos: @ Wert ist verbraucht, kann weg !
@ -----------------------------------------------------------------------------
  push {r1, lr}

1:ldr r1, [r0, #offset_state_3os]
  str r1, [r0, #offset_state_nos]
  ldr r1, [r0, #offset_constant_3os]
  str r1, [r0, #offset_constant_nos]

  movs r1, #unknown
  str r1, [r0, #offset_state_3os]

  pop {r1, pc}

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
@ Wortbirne Flag_visible, "tidyup-ra"
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
        pushdaconstw 0x4606 @ mov r6, r0
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
        pushdaconstw 0x460E @ mov r6, r1
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
    pushdaconstw 0x4600|0 << 3|6  @ mov r6, r0
    lsls r1, #3
    orrs tos, r1 @ Quellregister hinzuverodern
    bl hkomma

3:


tidyup_finish:
  bl init_register_allocator
  pop {r0, r1, r2, r3, pc}


@ -----------------------------------------------------------------------------
@ Wortbirne Flag_visible, "initregisterallocator"
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
