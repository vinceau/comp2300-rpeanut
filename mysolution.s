; u5388374 - Vincent Au 2014
; COMP2300 Assignment 2


; MAIN

0x0100: load #0 R0
	push R0 ;fill status
	
main:	jump pixel
	halt
	load 0xfff1 R0
	jumpz R0 main
	load 0xfff0 R0 ;input character

	;case input = h
	load #0x68 R1
	sub R0 R1 R1
	jumpz R1 done

	;case input = f
	load #0x66 R1
	sub R0 R1 R1
	jumpnz R1 casec

	load SP #0 R1 ;check fill status
	jumpnz R1 main
	load #0xffffffff R1
	push R1
	call fill
	pop R1
	load #1 R1
	store R1 #0 SP
	jump main

casec:	;case input = c
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

casep:	;case input =p
	load #0x70 R1
	sub R0 R1 R1
	jumpz R1 pixel
	jump main
pixel:	load #0 R1
	push R1 ;result input 1 (x coord)
	call gdi
	pop R5
	jump main

done:	pop R7 ;remove fill status
	halt


; FUNCTIONS

;draws a point at position (xpos, ypos)
;void draw(int xpos, int ypos)
;stack frame:
;#0 : return address
;#-1: ypos
;#-2: xpos

draw:	load SP #-1 R0
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

fill:	load SP #-1 R0
	load #0x3bf R1 ;distance between 0x7c40 and 0x7fff
paint:	store R0 #0x7c40 R1
	jumpz R1 fille ;if displacement is 0
	sub R1 ONE R1
	jump paint
fille: 	return


;character to hex (ctx): converts the character code into its
;correct hex code. e.g. converts 0x61 (letter a), into 0xa.
;function assumes correct input, no error checking occurs
;stack frame:
;#0 : return address
;#-1: input character code e.g. 0x61
;#-2: return value e.g. 0xa

ctx:	load SP #-1 R0
	load #0x60 R1
	sub R1 R0 R1
	jumpn R1 ctxlet
	load #48 R1 ;if char <= 0x60
	jump ctxend
ctxlet:	load #87 R1 ;if char > 0x60
ctxend:	sub R0 R1 R0
	store R0 #-2 SP
	return

;hex join (hj): joins two hex digits together
;e.g. 3 and b becomes 3b
;stack frame:
;#0 : return address
;#-1: input digit 2 (ones) e.g. b
;#-2: input digit 1 (sixteens) e.g. 3
;#-3: return value e.g. 3b

hj:	load SP #-2 R0
	load #16 R1
	mult R0 R1 R0
	load SP #-1 R1
	add R0 R1 R0
	store R0 #-3 SP
	return

;get double input (gdi): listens for two character inputs
;as hex and joins them together into the return value
;stack frame:
;#0    : input char 2
;#-1   : input char 1/return val for ctx on input char 2
;#-2   : return value for ctx on input char 1
;#-3/0 : return value for hj (write to return value)
;#-4/-1: return address
;#-5/-2: return value

gdi:	load #0 R1
	push R1 ;return value for hj
	push R1 ;return value for ctx
	load 0xfff1 R1
	jumpz R1 gdi
	load 0xfff0 R1 ;input character
	push R1
	call ctx
	;(pop, push) let input character be return value spot
gdi2:	load 0xfff1 R1
	jumpz R1 gdi2
	load 0xfff0 R1 ;next input character
	push R1
	call ctx
	pop R1 ;pop input char
	call hj
	pop R1 ;pop char
	pop R1 ;pop char
	load SP #0 R1 ;R1 = hj return
	store R1 #-2 SP
	pop R1 ;pop hj return value
	return