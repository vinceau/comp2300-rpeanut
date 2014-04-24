macro
draw &xpos &ypos

load &ypos R0
load #6 R1
mult R0 R1 R0 ;R0 = 6 * y
load R0 #0x7c40 R6 ;R6 now contains the original bit pattern

load &xpos R1
load #32 R2
mod R1 R2 R2 ;R2 = x % 32
rotate R2 ONE R2
or R6 R2 R6 ;R6 now contains new bit pattern

store R6 #0x7c40 R0
mend


0x0100: ;load #0x7c40 R0
	;store ONE R0
	draw #10 #10
	