; u5388374 - Vincent Au 2014
; COMP2300 Assignment 2
;
; Note: R7 is never guaranteed to hold what you want


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
0x0100: push MONE ;return value spot
        load #2 R0
        push R0
        call bpm
        pop MONE
        pop R0
        halt


        push ZERO ;fill status
        ;0 empty, -1 filled, 1 contains drawing
;        
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
        push MONE ;push bit pattern, -1 = 0xffffffff
        call fill
        pop MONE ;pop bit pattern
        jump main

        ; CLEAR
casec:  load SP #0 R1 ;check fill status
        jumpz R1 main
        push ZERO ;push empty bit pattern
        call fill
        pop MONE
        store ZERO #0 SP
        jump main

        ; PIXEL
casep:  load SP #0 R1 ;check fill status
        jumpn R1 main ;-1 = already filled, nothing to draw
        push MONE ;placeholder for x coord
        call gdi
        push MONE ;placeholder for y coord
        call gdi
        call draw
        pop MONE ;pop y coord
        pop MONE ;pop x coord
        store ONE #0 SP ;change fill status
        jump main

        ; LINE
casel:  load SP #0 R1 ;check fill status
        jumpn R1 main ;-1 = already filled, nothing to draw
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
        store ONE #0 SP ;change fill status
        jump main

        ; RECTANGLE
caser:  load SP #0 R1 ;check fill status
        jumpn R1 main ;-1 = already filled, nothing to draw
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
        store ONE #0 SP ;change fill status
        jump main

        ; HALT
done:   pop MONE ;remove fill status
        halt


; FUNCTIONS

;get the register of an xy coord
;#0 : return address
;#-1: ypos
;#-2: xpos
;#-3: return value
getreg: load SP #-1 R0
        load #6 R1
        mult R0 R1 R0 ;R0 = 6 * y

        load SP #-2 R1
        load #32 R2
        div R1 R2 R3
        add R0 R3 R0 ;R0 += x / 32
        store R0 #-3 SP
        return

;draws a point at position (xpos, ypos)
;void draw(int xpos, int ypos)
;stack frame:
;#0 : return address
;#-1: ypos
;#-2: xpos

draw:   load SP #-1 R0 ;ypos
        load SP #-2 R1 ;xpos
        push MONE ;return value for register
        push R1 ;xpos
        push R0 ;ypos
        call getreg
        pop MONE ;ypos
        pop R1 ;xpos
        pop R0 ;register

        load #32 R2
        mod R1 R2 R2 ;R2 = x % 32
        rotate R2 ONE R2

        load R0 #0x7c40 R6 ;R6 = original bit pattern
        or R6 R2 R6 ;R6 = new bit pattern

        store R6 #0x7c40 R0 ;R0 is displacement
        return


;fills in the entire frame buffer with the hex pattern
;void fill(hex pattern)
;stack frame:
;#0 : return address
;#-1: hex pattern

fill:   load SP #-1 R0
        load #0x3bf R1 ;distance between 0x7c40 and 0x7fff
paint:  store R0 #0x7c40 R1
        jumpz R1 fille ;if displacement is 0
        sub R1 ONE R1
        jump paint
fille:  return


;character to hex (ctx): converts the character code into its
;correct hex code. e.g. converts 0x61 (letter a), into 0xa.
;function assumes correct input, no error checking occurs
;stack frame:
;#0 : return address
;#-1: input character e.g. 0x61 / return value e.g. 0xa

ctx:    load SP #-1 R0 ;char
        load #0x60 R1
        jumplte R0 R1 ctxlte
        load #87 R1 ;if char > 0x60
        jump ctxend
ctxlte: load #48 R1 ;if char <= 0x60
ctxend: sub R0 R1 R0
        store R0 #-1 SP
        return

;hex join (hj): joins two hex digits together
;e.g. 3 and b becomes 3b
;stack frame:
;#0 : return address
;#-1: input digit 2 (ones) e.g. b
;#-2: input digit 1 (sixteens) e.g. 3
;#-3: return value e.g. 3b

hj:     load SP #-2 R0
        load #16 R1
        mult R0 R1 R0
        load SP #-1 R1
        add R0 R1 R0
        store R0 #-3 SP
        return

;get double input (gdi): listens for two character inputs
;as hex and joins them together into the return value
;stack frame:
;-- : input char 2
;-- : input char 1
;-- : return value for hj
;#0 : return address
;#-1: return value

gdi:    push MONE ;return value for hj
gdi1:   load 0xfff1 R1
        jumpz R1 gdi1
        load 0xfff0 R1 ;input character
        push R1
        call ctx
gdi2:   load 0xfff1 R1
        jumpz R1 gdi2
        load 0xfff0 R1 ;next input character
        push R1
        call ctx
        call hj
        pop MONE ;ctx char 2
        pop MONE ;ctx char 1
        pop R5 ;R5 = hj return value
        store R5 #-1 SP
        return

;absolute (abs): turns a number on the stack into its absolute value
;stack pane:
;#0 : return address
;#-1: number
abs:    load SP #-1 R0
        sub ZERO R0 R0
        jumpn R0 absend
        store R0 #-1 SP
absend: return


;line: draws a line
;stack frame:
;-- |--|-- |0  : y0 (modified)
;-- |--|0  |-1 : x0 (modified)
;-- |0 |-1 |-2 : err
;-- |-1|-2 |-3 : sy
;-- |-2|-3 |-4 : sx
;-- |-3|-4 |-5 : dy
;-- |-4|-5 |-6 : dx
;#0 |-5|-6 |-7 : return address
;#-1|-6|-7 |-8 : y1
;#-2|-7|-8 |-9 : x1
;#-3|-8|-9 |-10: y0 (original)
;#-4|-9|-10|-11: x0 (original)

line:   push MONE ;dx
        push MONE ;dy
        push MONE ;sx
        push MONE ;sy
        push MONE ;err
        load SP #-9 R0 ;R0 = x0
        push R0 ;x0
        load SP #-9 R1 ;R1 = y0
        push R1 ;y0

        ;dx = abs(x1-x0)
        load SP #-9 R1 ;R1 = x1
        jumplt R0 R1 line0
        store MONE #-4 SP
        jump line1
line0:  store ONE #-4 SP
line1:  sub R1 R0 R0 ;R0 = x1 - x0
        push R0 ; pushed dx
        call abs
        pop R0 ; pop abs(dx)
        store R0 #-6 SP ;update dx
       
        ;dy = abs(y1 - y0)
        load SP #0 R0 ;R0 = y0
        load SP #-8 R1 ;R1 = y1
        jumplt R0 R1 line2
        store MONE #-3 SP
        jump line3
line2:  store ONE #-3 SP
line3:  sub R1 R0 R0 ;R0 = y1 - y0
        push R0 ; pushed dy
        call abs
        pop R0 ;pop abs(dy) into R0
        store R0 #-5 SP ;update dy
       
        load SP #-6 R1 ;R1 = dx
        sub R1 R0 R0 ;R0 = dx - dy
        store R0 #-2 SP; update err

        ;start loop
        jump line6

        ;if e2 > - dy
line4:  load SP #-2 R0 ;R0 = err
        add R0 R0 R1 ;(e2) R1 = 2 * err
        load SP #-5 R2 ;R2 = dy
        mult MONE R2 R2 ;R2 = -dy
        jumplte R1 R2 line5
        ;err := err - dy
        add R0 R2 R2 ;R2 = err + (-dy)
        store R2 #-2 SP ;update err

        ;x0 := x0 + sx
        load SP #-1 R2 ;R2 = x0
        load SP #-4 R3 ;R3 = sx
        add R2 R3 R2 ;R2 = x0 + sx
        store R2 #-1 SP ;update x0
        
        ;if e2 < dx
line5:  load SP #-2 R0 ;R0 = err
        add R0 R0 R1 ;(e2) R1 = 2 * err
        load SP #-6 R2 ;R2 = dx
        jumplte R2 R1 line6 ;go back to loop
        ; err := err + dx
        add R0 R2 R2 ;R2 = err + dx
        store R2 #-2 SP ;update err
        
        ; y0 := y0 + sy
        load SP #0 R0 ;R0 = y0
        load SP #-3 R1 ;R1 = sy
        add R0 R1 R1 ;R1 = y0 + sy
        store R1 #0 SP ;update y0

        ;loop again
line6:  call draw ;setPixel

        ;conditional
        load SP #-1 R0  ;R0 = x0
        load SP #-9 R1 ;R1 = x1
        jumpneq R0 R1 line4 ;if x1 != x0
        
        ;if x1 == x0
        load SP #0 R0  ;R0 = y0
        load SP #-8 R1 ;R1 = y1
        jumpneq R0 R1 line4 ;loop if y1 != y0
        ; exit loop
        pop MONE ;y0
        pop MONE ;x0
        pop MONE ;pop err
        pop MONE ;pop sy
        pop MONE ;pop sx
        pop MONE ;pop dy
        pop MONE ;pop dx
        return


;draws a rectangle at x, y, with width and height
rect:   return


;horiz(ontal line): draws a horizontal line starting at (x, y) with a length
;of lenght
;stack frame:
;#0 : return address
;#-1: length
;#-2: ypos
;#-3: xpos
horiz:  load #-2 R0; ypos
        load #32 R1 ;32
        mod R0 R1 R2 ;y % 32
        div R0 R1 R3 ;y / 32



        load #-1 R0 ;length of line
horiz0: jumplt R0 R1 horiz1

horiz1: ;do the rest
        return

;bit pattern maker (bpm): takes an integer x and generates a 32 bit pattern of x 1s right aligned.
;stack frame:
;#0 : return address
;#-1: input integer e.g. 4
;#-2: return value e.g. 0000000...1111

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
bpm3:   jumplt ZERO R0 bpm4 ;zero so don't negate
        not R3 R3
        load SP #-1 R1
        rotate R1 R3 R3
bpm4:   store R3 #-2 SP
        return
