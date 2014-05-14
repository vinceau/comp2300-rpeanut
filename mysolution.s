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

; MAIN
0x0100: push ZERO ;fill status
        ;0 empty, -1 filled, 1 contains drawing
main:   load 0xfff1 R0
        jumpz R0 main
        load 0xfff0 R0 ;input character

        ;case input = h
        load #0x68 R1
        jumpeq R0 R1 done

        ;case input = f
        load #0x66 R1
        jumpeq R0 R1 casef

        ;case input = c
        load #0x63 R1
        jumpeq R0 R1 casec

        ;case input = p
        load #0x70 R1
        jumpeq R0 R1 casep

        ;case input = l
        load #0x6c R1
        jumpeq R0 R1 casel

        ;case input = r
        load #0x72 R1
        jumpeq R0 R1 caser

        ;else
        jump main

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

        ; HALT
done:   pop MONE ;remove fill status
        halt


; FUNCTIONS

;draws a point at position (xpos, ypos)
;void draw(int xpos, int ypos)
;stack frame:
;#0 : return address
;#-1: ypos
;#-2: xpos

draw:   load SP #-1 R0 ;ypos
        load SP #-2 R1 ;xpos
        load #6 R2
        mult R0 R2 R0 ;R0 = 6 * y
        load #32 R2
        div R1 R2 R3 ;R3 = x / 32
        add R0 R3 R0 ;R0 = (6 * y) + (x / 32)
        mod R1 R2 R2 ;R2 = x % 32
        rotate R2 ONE R2
        load R0 #0x7c40 R6 ;R6 = original bit pattern
        or R6 R2 R6 ;R6 = new bit pattern
        store R6 #0x7c40 R0 ;R0 is displacement
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
;--|--|0 : y0 (modified)
;--|0 |-1: x0 (modified)
;0 |-1|-2: return address
;-1|-2|-3: y1
;-2|-3|-4: x1
;-3|-4|-5: y0 (original)
;-4|-5|-6: x0 (original)

linedx:     block 1
linedy:     block 1
linesx:     block 1
linesy:     block 1
lineerr:    block 1

line:   load SP #-4 R0 ;R0 = x0
        push R0 ;x0
        load SP #-4 R1
        push R1 ;y0

        ;dx = abs(x1-x0)
        load SP #-4 R1 ;R1 = x1
        jumplt R0 R1 line0
        store MONE linesx
        jump line1
line0:  store ONE linesx
line1:  sub R1 R0 R0 ;R0 = x1 - x0
        ;abs(x1 - x0)
        sub ZERO R0 R1 ;-(x1 - x0)
        jumpn R1 linestoredx
        move R1 R0
linestoredx:
        store R0 linedx ;update dx
        ;dy = abs(y1 - y0)
        load SP #0 R0 ;R0 = y0
        load SP #-3 R1 ;R1 = y1
        jumplt R0 R1 line2
        store MONE linesy
        jump line3
line2:  store ONE linesy
line3:  sub R1 R0 R0 ;R0 = y1 - y0
        ;abs(y1 - y0)
        sub ZERO R0 R1
        jumpn R1 linestoredy
        move R1 R0
linestoredy:
        store R0 linedy ;update dy
        load linedx R1 ;R1 = dx
        sub R1 R0 R0 ;R0 = dx - dy
        store R0 lineerr; update err

        ;start loop
        jump line6

        ;if e2 > - dy
line4:  load lineerr R0 ;R0 = err
        add R0 R0 R1 ;(e2) R1 = 2 * err
        load linedy R2 ;R2 = dy
        mult MONE R2 R2 ;R2 = -dy
        jumplte R1 R2 line5
        ;err := err - dy
        add R0 R2 R2 ;R2 = err + (-dy)
        store R2 lineerr ;update err

        ;x0 := x0 + sx
        load SP #-1 R2 ;R2 = x0
        load linesx R3 ;R3 = sx
        add R2 R3 R2 ;R2 = x0 + sx
        store R2 #-1 SP ;update x0
        
        ;if e2 < dx
line5:  load lineerr R0 ;R0 = err
        load linedx R2 ;R2 = dx
        jumplte R2 R1 line6 ;go back to loop
        ; err := err + dx
        add R0 R2 R2 ;R2 = err + dx
        store R2 lineerr ;update err
        
        ; y0 := y0 + sy
        load SP #0 R0 ;R0 = y0
        load linesy R1 ;R1 = sy
        add R0 R1 R1 ;R1 = y0 + sy
        store R1 #0 SP ;update y0

        ;loop again
line6:  call draw ;setPixel

        ;conditional
        load SP #-1 R0  ;R0 = x0
        load SP #-4 R1 ;R1 = x1
        jumpneq R0 R1 line4 ;if x1 != x0
        
        ;if x1 == x0
        load SP #0 R0  ;R0 = y0
        load SP #-3 R1 ;R1 = y1
        jumpneq R0 R1 line4 ;loop if y1 != y0
        ; exit loop
        pop MONE ;y0
        pop MONE ;x0
        return


;draws a rectangle at x, y, with width and height
;stack frame
;#0 : return address
;#-1: height
;#-2: width
;#-3: ypos
;#-4: xpos
rectxpos:       block 1
rectwidth:      block 1
rectcurrblock:  block 1  ;(displacement from 0x7c40)
rectxposblock:  block 1  ;xpos relative to block
rectspotsleft:  block 1  ;32 - xpos block pos

rect:   load SP #-4 R0
        store R0 rectxpos
        load SP #-2 R0
        store R0 rectwidth
rectloop:
        load SP #-3 R0 ;R0 = orig ypos
        load #6 R2
        mult R0 R2 R2 ;R2 = 6 * y

        load rectxpos R1 ;R1 = xpos
        load #32 R3 ;R3 = 32
        div R1 R3 R4 ;R4 = xpos / 32
        add R2 R4 R4 ;R4 = (6 * y) + (x / 32) 
        store R4 rectcurrblock

        mod R1 R3 R5 ;R5 = xpos % 32
        store R5 rectxposblock
        sub R3 R5 R5 ;R5 = number of spots left over
        store R5 rectspotsleft
        ;check if width is greater than spots left over
        load rectwidth R6 ;R6 = width
        jumplte R6 ZERO rectend;jump if width is less zero
        ;width is non zero
        jumplte R6 R5 rectstartdraw ;width < spots left
        ;width is greater than spots left
        move R5 R6 ;replace width with spots left
rectstartdraw:
        push R6 ;push width
        call bpm
        pop R6 ;bit pattern of size width
        load rectxposblock R0
        rotate R0 R6 R6 ;shifted bit pattern
        load SP #-1 R0
        load rectcurrblock R1
        load #6 R2
        move ONE R3 ;R3 = 1
        load SP #-1 R0 ;orig height
rectdrawheight:
        store R6 #0x7c40 R1
        jumpeq R3 R0 rectnextloop
        add R3 ONE R3
        add R1 R2 R1 ;current block + 6
        jump rectdrawheight
rectnextloop:
        load rectwidth R0
        load rectspotsleft R1
        sub R0 R1 R0
        store R0 rectwidth ;width -= spotsleft
        load rectxpos R0
        add R0 R1 R0 ;xpos += spotsleft
        store R0 rectxpos
        jump rectloop
rectend:
        return


;bit pattern maker (bpm): takes an integer x and turns it into a 32 bit pattern of x 1s right aligned.
;stack frame:
;#0 : return address
;#-1: input integer e.g. 4 -> return value e.g. 0000000...1111

bpm:    load #16 R0
        load SP #-1 R1 ;n
        jumplt R1 R0 bpm0
        ; n > 16
        load #32 R0
        sub R0 R1 R1 ;n = 32 - n
        move MONE R0 ;R0 = -1 so negate it at the end

bpm0:   load #2 R2 ;2
        load #2 R3 ;R3 = answer
        jumpnz R1 bpm2
        move ZERO R3
        jump bpm3
       
bpm1:   mult R2 R3 R3
bpm2:   sub R1 ONE R1 ;index -= 1
        jumpnz R1 bpm1
        ;R3 = 2 ** n
        sub R3 ONE R3 ;R3 = (2 ** n) - 1
bpm3:   jumplt ZERO R0 bpm4 ;continue if negative
        not R3 R3
        load SP #-1 R1
        rotate R1 R3 R3
bpm4:   store R3 #-1 SP
        return
