; u5388374 - Vincent Au 2014
; COMP2300 Assignment 2


; MAIN

0x0100: load #0 R0
        push R0 ;fill status
        ;0 empty, -1 filled, 1 contains drawing
        
main:   load 0xfff1 R0
        jumpz R0 main
        load 0xfff0 R0 ;input character

        ; HALT
        ;case input = h
        load #0x68 R1
        sub R0 R1 R1
        jumpz R1 done

        ; FILL
        ;case input = f
        load #0x66 R1
        sub R0 R1 R1
        jumpnz R1 casec

        load SP #0 R1 ;check fill status
        jumpn R1 main
        load #-1 R1 ; -1 = 0xffffffff
        store R1 #0 SP ;change fill status
        push R1 ;push bit pattern
        call fill
        pop R1 ;pop bit pattern
        jump main

        ; CLEAR
casec:  ;case input = c
        load #0x63 R1
        sub R0 R1 R1
        jumpnz R1 casep

        load SP #0 R1 ;check fill status
        jumpz R1 main
        load #0 R1
        push R1
        call fill
        pop R1
        load #0 R1
        store R1 #0 SP
        jump main

        ; PIXEL
casep:  ;case input = p
        load #0x70 R1
        sub R0 R1 R1
        jumpnz R1 casel
        push R1 ;placeholder for x coord
        call gdi
        push R1 ;placeholder for y coord
        call gdi
        call draw
        pop R0 ;pop y coord
        pop R0 ;pop x coord

        load #1 R1 ;change fill status
        store R1 #0 SP
        jump main

        ; LINE
casel:  ;case input = l
        load #0x6c R1
        sub R0 R1 R1
        jumpnz R1 main
        push R1 ;placeholder for x1
        call gdi
        push R1 ;placeholder for y1
        call gdi
        push R1 ;placeholder result for x2
        call gdi
        push R1 ;placeholder result for y2
        call gdi
        call line
        pop R0 ;y2
        pop R0 ;x2
        pop R0 ;y1
        pop R0 ;x1

        load #1 R1 ;change fill status
        store R1 #0 SP
        jump main

done:   pop R7 ;remove fill status
        halt


; FUNCTIONS

;draws a point at position (xpos, ypos)
;void draw(int xpos, int ypos)
;stack frame:
;#0 : return address
;#-1: ypos
;#-2: xpos

draw:   load SP #-1 R0
        load #6 R1
        mult R0 R1 R0 ;R0 = 6 * y

        load SP #-2 R1
        load #32 R2
        div R1 R2 R3
        add R0 R3 R0 ;R0 += x / 32

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
;#-1: input character code e.g. 0x61
;#-2: return value e.g. 0xa

ctx:    load SP #-1 R0
        load #0x60 R1
        sub R1 R0 R1
        jumpn R1 ctxlet
        load #48 R1 ;if char <= 0x60
        jump ctxend
ctxlet: load #87 R1 ;if char > 0x60
ctxend: sub R0 R1 R0
        store R0 #-2 SP
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
;-- : input char 1/return val for ctx on input char 2
;-- : return value for ctx on input char 1
;-- : return value for hj (write to return value)
;#0 : return address
;#-1: return value

gdi:    load #0 R1
        push R1 ;return value for hj
        push R1 ;return value for ctx
gdi1:   load 0xfff1 R1
        jumpz R1 gdi1
        load 0xfff0 R1 ;input character
        push R1
        call ctx
        ;(pop, push) let input character be return value spot
gdi2:   load 0xfff1 R1
        jumpz R1 gdi2
        load 0xfff0 R1 ;next input character
        push R1
        call ctx
        pop R1 ;input char 2
        call hj
        pop R1 ;ctx char 2
        pop R1 ;ctx char 1
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

line:   load #0 R0
        push R0 ;dx
        push R0 ;dy
        push R0 ;sx
        push R0 ;sy
        push R0 ;err
        load SP #-9 R0 ;R0 = x0
        push R0 ;x0
        load SP #-9 R1 ;R0 = y0
        push R0 ;y0

        ;dx = abs(x1-x0)
        load SP #-1 R0 ;R0 = x0
        load SP #-9 R1 ;R1 = x1
        sub R1 R0 R0 ;R0 = x1 - x0
        jumpn R0 line0
        jumpz R0 line0
        ; if x0 < x1
        load #1 R7
        jump line1
        ; else
line0:  load #-1 R7
line1:  store R7 #-4 SP ; update sx
        push R0 ; pushed dx
        call abs
        pop R0 ; pop abs(dx)
        store R0 #-6 SP ;update dx
       
        ;dy = abs(y1 - y0)
        load SP #0 R0 ;R0 = y0
        load SP #-8 R1 ;R1 = y1
        sub R1 R0 R0 ;R0 = y1 - y0
        jumpn R0 line2
        jumpz R0 line2
        ; if y0 < y1
        load #1 R7
        jump line3
        ; else
line2:  load #-1 R7
line3:  store R7 #-3 SP ; update sy
        push R0 ; pushed dy
        call abs
        pop R0 ;pop abs(dy) into R0
        store R0 #-5 SP
       
        load SP #-6 R1 ;R1 = dx
        sub R1 R0 R0 ;R0 = dx - dy
        store R0 #-2 SP; update err

        ;start loop
        jump line6

        ;if e2 > - dy
line4:  load SP #-2 R0 ;R0 = err
        add R0 R0 R1 ;(e2) R1 = 2 * err
        load SP #-5 R2 ;R2 = dy
        add R1 R2 R3 ;R3 = dy + e2
        jumpn R3 line5
        jumpz R3 line5
        ;err := err - dy
        sub R0 R2 R2 ;R2 = err - dy
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
        sub R2 R1 R3 ;R3 = dx - e2
        jumpn R3 line6 ;go back to loop
        jumpz R3 line6
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
        sub R1 R0 R0 ;R0 = x1 - x0
        jumpnz R0 line4 ;if x1 != x0
        
        ;if x1 == x0
        load SP #0 R0  ;R0 = y0
        load SP #-8 R1 ;R1 = y1
        sub R1 R0 R0 ;R0 = x1 - x0
        jumpnz R0 line4 ;loop if y1 != y0
        ; exit loop
        pop R0 ;y0
        pop R0 ;x0
        pop R0 ;pop err
        pop R0 ;pop sy
        pop R0 ;pop sx
        pop R0 ;pop dy
        pop R0 ;pop dx
        return

;bit pattern maker (bpm): takes an integer x and generates a 32 bit pattern of x 1s left aligned.
;e.g. 4 becomes 111100000000...
;stack frame:
;#0 : return address
;#-1: input integer e.g. 4
;#-2: return value e.g. 11110000000...

bpm:    load SP #-1 R0
        load #31 R7
        sub R7 R0 R7
        load #0 R1
        jump bpm1
bpm0:   load #1 R2
        sub R0 ONE R0
        rotate R0 R2 R2
        or R1 R2 R1
        jumpn R1 bpm2
bpm1:   jumpnz R0 bpm0
        rotate R7 R1 R2
bpm2:   store R2 #-2 SP
        return
