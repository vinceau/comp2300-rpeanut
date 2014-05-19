; u5388374 - Vincent Au 2014
; COMP2300 Assignment 2


; MACROS
; Note: R7 is never guaranteed to hold what you expect it to

;jump if two registers are equal
macro
    jumpeq &reg1 &reg2 &label
    sub &reg1 &reg2 R7
    jumpz R7 &label
mend

;jump if two registers are not equal
macro
    jumpneq &reg1 &reg2 &label
    sub &reg1 &reg2 R7
    jumpnz R7 &label
mend

;jump if first register is less than second
macro
    jumplt &reg1 &reg2 &label
    sub &reg1 &reg2 R7
    jumpn R7 &label
mend

;jump if first register is less than or equal to the second
macro
    jumplte &reg1 &reg2 &label
    sub &reg1 &reg2 R7
    jumpn R7 &label
    jumpz R7 &label
mend

;jump if first register is greater than second
macro
    jumpgt &reg1 &reg2 &label
    jumplt &reg2 &reg1 &label
mend

;jump if first register is greater than or equal to the second
macro
    jumpgte &reg1 &reg2 &label
    jumplte &reg2 &reg1 &label
mend

0x0063: jump casec ;c
0x0066: jump casef ;f
0x0068: jump done  ;h
0x006c: jump casel ;l
0x0070: jump casep ;p
0x0072: jump caser ;r


; MAIN
0x0100: push ZERO ;fill status
        ;0 empty, -1 filled, 1 contains drawing
main:   load 0xfff0 R0
        jumpz R0 main
        move R0 PC
done:   pop MONE ;remove fill status
        halt


        ; FILL
casef:  load SP #0 R1 ;check fill status
        jumpn R1 main ;-1 = already filled
        store MONE #0 SP ;change fill status to -1

        load #0x3bf R1 ;distance between 0x7c40 and 0x7fff
fill:   store MONE #0x7c40 R1
        jumpz R1 main ;if displacement is 0
        sub R1 ONE R1
        jump fill


        ; CLEAR
casec:  load SP #0 R1 ;check fill status
        jumpz R1 main ;zero means already cleared
        store ZERO #0 SP ;change fill status to zero
        
        load #0x3bf R1 ;distance between 0x7c40 and 0x7fff
clear:  store ZERO #0x7c40 R1
        jumpz R1 main ;if displacement is 0
        sub R1 ONE R1
        jump clear


        ; PIXEL
casep:  load SP #0 R1 ;check fill status
        jumpn R1 main ;-1 = already filled, nothing to draw
        store ONE #0 SP ;change fill status
        
        push MONE ;placeholder for x coord
        call gdi
        push MONE ;placeholder for y coord
        call gdi
        call draw
        pop MONE ;pop y coord
        pop MONE ;pop x coord
        jump main

        ; LINE
casel:  load SP #0 R1 ;check fill status
        jumpn R1 main ;-1 = already filled, nothing to draw
        store ONE #0 SP ;change fill status
        
        push MONE ;placeholder for x1
        call gdi
        push MONE ;placeholder for y1
        call gdi
        push MONE ;placeholder result for x2
        call gdi
        push MONE ;placeholder result for y2
        call gdi
        call line
        pop MONE ;y2
        pop MONE ;x2
        pop MONE ;y1
        pop MONE ;x1
        jump main

        ; RECTANGLE
caser:  load SP #0 R1 ;check fill status
        jumpn R1 main ;-1 = already filled, nothing to draw
        store ONE #0 SP ;change fill status
        
        push MONE ;placeholder for x
        call gdi
        push MONE ;placeholder for y
        call gdi
        push MONE ;placeholder width
        call gdi
        push MONE ;placeholder height
        call gdi
        call rect
        pop MONE ;height
        pop MONE ;width
        pop MONE ;y
        pop MONE ;x
        jump main



; FUNCTIONS

;draws a point at position (xpos, ypos)
;void draw(int xpos, int ypos)
;stack frame:
;#0 : return address
;#-1: ypos
;#-2: xpos

draw:   load SP #-1 R0 ;ypos
        load #6 R1
        mult R0 R1 R0 ;R0 = 6 * y
        load SP #-2 R1 ;xpos
        load #32 R2
        div R1 R2 R2 ;R2 = x / 32
        add R0 R2 R0 ;R0 = (6 * y) + (x / 32)
        rotate R1 ONE R1
        load R0 #0x7c40 R2 ;R2 = original bit pattern
        or R2 R1 R1 ;R1 = new bit pattern
        store R1 #0x7c40 R0 ;R0 is displacement
        return


;get double input (gdi): listens for two character inputs
;as hex and joins them together into the return value
;stack frame:
;#0 : return address
;#-1: return value

gdi:    load #hextable R0
        load #16 R3
gdi1:   load 0xfff1 R1
        jumpz R1 gdi1
        load 0xfff0 R1 ;input character
        add R0 R1 R1 ;hextable + input char offset
        load R1 R1 ;get char value
        mult R3 R1 R1
gdi2:   load 0xfff1 R2
        jumpz R2 gdi2
        load 0xfff0 R2 ;next input character
        add R0 R2 R2 ;hextable + input char offset
        load R2 R2 ;get char value
        add R1 R2 R1
        store R1 #-1 SP
        return

hextable:
        block 48 ;padding
        block #0
        block #1
        block #2
        block #3
        block #4
        block #5
        block #6
        block #7
        block #8
        block #9 ;57
        block 39 ;padding
        block #0xa
        block #0xb
        block #0xc
        block #0xd
        block #0xe
        block #0xf


;line: draws a line
;stack frame:
;0 : return address
;-1: y1 (final y)
;-2: x1 (final x)
;-3: y0 (original)
;-4: x0 (original)

linedx:     block 1
linedy:     block 1
linesx:     block 1
linesy:     block 1
lineerr:    block 1

line:   load SP #-4 R0 ;R0 = x0
        load SP #-3 R1 ;R1 = y0
        load SP #-2 R2 ;R2 = x1
        load SP #-1 R3 ;R3 = y1

        ;dx = abs(x1-x0)
        ;if x0 < x1 then sx := 1 else sx := -1
        jumplt R0 R2 line0
        store MONE linesx
        jump line1
line0:  store ONE linesx
line1:  sub R2 R0 R6 ;R6 = x1 - x0
        ;abs(x1 - x0)
        sub ZERO R6 R5 ;-(x1 - x0)
        jumpn R5 linestoredx
        move R5 R6
linestoredx:
        store R6 linedx ;update dx
        ;dy = abs(y1 - y0)
        ;if y0 < y1 then sy := 1 else sy := -1
        jumplt R1 R3 line2
        store MONE linesy
        jump line3
line2:  store ONE linesy
line3:  sub R3 R1 R6 ;R6 = y1 - y0
        ;abs(y1 - y0)
        sub ZERO R6 R5
        jumpn R5 linestoredy
        move R5 R6
linestoredy:
        store R6 linedy ;update dy
        load linedx R5 ;R5 = dx
        sub R5 R6 R6 ;R6 = dx - dy
        store R6 lineerr; update err

        ;start loop
        jump line6

        ;if e2 > - dy
line4:  load lineerr R6 ;R6 = err
        add R6 R6 R5 ;(e2) R5 = 2 * err
        load linedy R4 ;R4 = dy
        mult MONE R4 R4 ;R4 = -dy
        jumplte R5 R4 line5
        ;err := err - dy
        add R6 R4 R4 ;R4 = err + (-dy)
        store R4 lineerr ;update err

        ;x0 := x0 + sx
        load linesx R6 ;R6 = sx
        add R0 R6 R0 ;R4 = x0 + sx
        
        ;if e2 < dx
line5:  load lineerr R6 ;R6 = err
        load linedx R4 ;R4 = dx
        jumplte R4 R5 line6 ;go back to loop
        ; err := err + dx
        add R6 R4 R4 ;R4 = err + dx
        store R4 lineerr ;update err
        
        ; y0 := y0 + sy
        load linesy R5 ;R5 = sy
        add R1 R5 R1 ;R1 = y0 + sy

        ;loop again
line6:  ;setPixel
        load #6 R6
        mult R6 R1 R6 ;R6 = 6 * y
        load #32 R5
        div R0 R5 R5 ;R5 = x / 32
        add R6 R5 R6 ;R6 = (6 * y) + (x / 32)
        rotate R0 ONE R5 ;R5 is bit pattern
        load R6 #0x7c40 R4 ;R6 = displacement
        or R4 R5 R5 ;R5 = new bit pattern
        store R5 #0x7c40 R6 ;R6 is displacement

        ;conditional
        jumpneq R0 R2 line4 ;if x1 != x0
        
        ;if x1 == x0
        jumpneq R1 R3 line4 ;loop if y1 != y0
        ; exit loop
        return


;draws a rectangle at x, y, with width and height
;stack frame
;#0 : return address
;#-1: height
;#-2: width
;#-3: ypos
;#-4: xpos
rectcurrblock:  block 1  ;(displacement from 0x7c40)

rect:   load SP #-3 R0 ;R0 = orig ypos
        load SP #-1 R1 ;R1 = height of rectangle
        add R0 R1 R0 ;R0 = ypos + height
        sub R0 ONE R0 ;height -= 1 so we can jumpz
        load #6 R1
        mult R0 R1 R0 ;R0 = 6 * y
        
        load SP #-4 R1 ;R1 = xpos
        load #32 R2 ;R2 = 32
        div R1 R2 R3 ;xpos / 32
        add R3 R0 R0 ;R0 = (y pos) + (x / 32)
        store R0 rectcurrblock ;R0 = currblock

        mod R1 R2 R3 ;R3 = xpos % 32 ; x starting point
        sub R2 R3 R1 ;R1 = 32 - x starting point = number of spots left over

        ;R0 = currblock, R1 = spots left over, R2 = 32, R3 = x % 32

        ;check if width is greater than spots left over
        load SP #-2 R4 ;R4 = width
        load #bpmtable R5 ;R5 = bpm table
        jumpgt R4 R1 rectdoesntfit ;width > spots
        move R4 R1 ;move width into spots left
rectdoesntfit:
        ;okay so width > spots
        sub R4 R1 R4 ;width -= spots left
        add R1 R5 R1 ;R1 = spots left + bpmtable address
        load R1 R1 ;R1 = bpm pattern
        rotate R3 R1 R1 ;R1 = rotated bit pattern
        load SP #-1 R3 ;R3 = height
        load #6 R6
        ;R0 = currblock, R1 = bit pattern, R2 = 32, R3 = height
        ;R4 = width, R6 = 6

rectfirstblock:
        load R0 #0x7c40 R5 ;R5 = original bit pattern
        or R1 R5 R5 ;R5 = new bit pattern
        store R5 #0x7c40 R0 ;R0 is displacement
        sub R0 R6 R0 ;displacement - 6
        sub R3 ONE R3 ;height -= 1
        jumpnz R3 rectfirstblock
        jumpz R4 rectend ;return if width is zero 

        ;okay so the first part has been drawn
        load rectcurrblock R0
        add R0 ONE R0
        store R0 rectcurrblock

        ;we need a while width > 32 loop
        jump rectcheck
rectfillmid:
        load SP #-1 R3 ;R3 = height
rectdothefill:
        store MONE #0x7c40 R0
        sub R0 R6 R0 ;displacement - 6
        sub R3 ONE R3 ;height -= 1
        jumpnz R3 rectdothefill
        
        ; okay so we drew a block
        sub R4 R2 R4 ;width -= 32
        load rectcurrblock R0
        add R0 ONE R0
        store R0 rectcurrblock

rectcheck:
        jumpgt R4 R2 rectfillmid ;jump if width > 32

        ;okay so now width is < 32
        load #bpmtable R1 ;R5 = bpm table
        add R4 R1 R1 ;R1 = spots left + bpmtable address
        load R1 R1 ;R1 = bpm pattern
        load SP #-1 R3 ;R3 = height
        ;R0 = currblock, R1 = bit pattern, R2 = 32, R3 = height
        ;R4 = width, R6 = 6
rectfinal:
        load R0 #0x7c40 R5 ;R5 = original bit pattern
        or R1 R5 R5 ;R5 = new bit pattern
        store R5 #0x7c40 R0 ;R0 is displacement
        sub R0 R6 R0 ;displacement - 6
        sub R3 ONE R3 ;height -= 1
        jumpnz R3 rectfinal
rectend:
        return

bpmtable:
        block #0
        block #0x1
        block #0x3
        block #0x7
        block #0xf
        block #0x1f
        block #0x3f
        block #0x7f
        block #0xff
        block #0x1ff
        block #0x3ff
        block #0x7ff
        block #0xfff
        block #0x1fff
        block #0x3fff
        block #0x7fff
        block #0xffff
        block #0x1ffff
        block #0x3ffff
        block #0x7ffff
        block #0xfffff
        block #0x1fffff
        block #0x3fffff
        block #0x7fffff
        block #0xffffff
        block #0x1ffffff
        block #0x3ffffff
        block #0x7ffffff
        block #0xfffffff
        block #0x1fffffff
        block #0x3fffffff
        block #0x7fffffff
        block #0xffffffff

