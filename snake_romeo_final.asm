#Author: Romeo Barrientos
#Date: 12/09/21
#Project: Snake Final Project

## The colors of the snake, dot and background were made vibrant colors for testing purposes since I am red/green colorblind.
##Altering the colors seemed more congruent with the snake being green but other colors made it difficult for me to distinguish the snake from the background. 
# This game uses the Keyboard and MMIO Simulator as well as the Bitmap display to function. Ensure that both tools are opened and connected to MIPS before running. 
# Within the Bitmap display set Display Width and Height to 512, set Unit Width and Height to 8. 

## The controls of the game are as follows: 
# J-key moves you left
# I-key moves you up
# K-key moves you down
# L-key moves you right
# If at any point you cross a line or your own tail, you die!

.data

bufferSpace: 	.space 	0x80000		# 512W X 512H
dotX:		.word	32		# red dot x position
dotY:		.word	16		# red dot y position
xSpeed:		.word	0		# Start x speed at zeor
speedY:		.word	0		# Start y speed at zero
xConvert:	.word	64		# Value to convert x-position to bitmap
yConvert:	.word	4		# Value to convert y-position to bitmap
goUp:		.word	0x0000ff00	# up for snake head
goDown:		.word	0x0100ff00	# down for snake head
goLeft:		.word	0x0200ff00	# left for snake head
goRight:	.word	0x0300ff00	# rightfor snake head
xPos:		.word	50		# x position
yPos:		.word	27		# y position
tail:		.word	7624		# tail location on bitmap 

.text
main:

# Background color
## Made the colors a bit more vibrant since I am red/green colorblind.

	la 	$t0, bufferSpace	# load fb address
	li 	$t1, 8192		# load immediate pixel space
	li 	$t2, 0x00808080		# load gray into pixel space for snake map
l1:
	sw   	$t2, 0($t0)
	addi 	$t0, $t0, 4 		# change to next pixel position in bitmap
	addi 	$t1, $t1, -1		# decrement number of pixels
	bnez 	$t1, l1			# while pixels != zero , repeat
	
#	Border color and size
	
	# border top color and size
	la	$t0, bufferSpace	# load fb address
	addi	$t1, $zero, 64		# make length of row 64
	li 	$t2, 0x0006600		# load dark green color
borderTop:
	sw	$t2, 0($t0)		# color pixel dark green
	addi	$t0, $t0, 4		# move onto next pixel
	addi	$t1, $t1, -1		# decrement pixel count
	bnez	$t1, borderTop		# repeat until pixel count == 0
	
	# Bottom border area
	la	$t0, bufferSpace	# load fb address
	addi	$t0, $t0, 9724		# Made this as close to bottom of bitmap as possible
	addi	$t1, $zero, 64		# length of row = 64

borderBottom:
	sw	$t2, 0($t0)		# color dark green
	addi	$t0, $t0, 4		# mvoe to next pixel
	addi	$t1, $t1, -1		# decrement pixel count
	bnez	$t1, borderBottom	# repeat unitl pixel count == 0
	
	# left wall 
	la	$t0, bufferSpace	# load fb address
	addi	$t1, $zero, 512		# length of column = 512

borderLeft:
	sw	$t2, 0($t0)		# color pixel dark green
	addi	$t0, $t0, 256		# go to next pixel
	addi	$t1, $t1, -1		# decrement pixel count
	bnez	$t1, borderLeft		# repeat unitl pixel count == 0
	
	# Right wall 
	la	$t0, bufferSpace	# load fb address
	addi	$t0, $t0, 508		# make starting pixel top right
	addi	$t1, $zero, 255		# column length = 25

borderRight:
	sw	$t2, 0($t0)		# color pixel dark green
	addi	$t0, $t0, 256		# go to next pixel
	addi	$t1, $t1, -1		# decrement pixel count
	bnez	$t1, borderRight	# repeat unitl pixel count == 0
	
	### draw initial snake
	la	$t0, bufferSpace	# load fb address
	lw	$s2, tail		# s2 = tail of snake
	lw	$s3, goUp		# snake direction
	
	add	$t1, $s2, $t0		# t1 = tail start on bit map display
	sw	$s3, 0($t1)		# draw pixel where snake is
	addi	$t1, $t1, -256		# set t1 to pixel above
	sw	$s3, 0($t1)		# draw pixel where snake currently is
	
	### draw initial dot
	jal 	drawDot

# t3 = key press input
# s3 = direction of the snake
updateLoop:

	lw	$t3, 0xffff0004		# Receiver Data Register
	
	# Sleep for 80 ms, changed from original 500
	addi	$v0, $zero, 32		# syscall sleep
	addi	$a0, $zero, 80		# 80 ms
	syscall
	
	beq	$t3, 105, pointUp	# ascii chart i, moves up
	beq	$t3, 106, pointLeft	# ascii chart j, move left
	beq	$t3, 107, pointDown	# ascii chart k, move down
	beq	$t3, 108, pointRight	# ascii chart l, move right
	beq	$t3, 0, pointLeft	# start game moving up
	
pointUp:
	lw	$s3, goUp		# s3 = snake direction
	add	$a0, $s3, $zero		# place snake direction into $a0
	jal	updateSnake
	
	# Snake moves
	jal 	headPositionUpdate
	
	j	exitMoves 	

pointDown:
	lw	$s3, goDown		# snake direction
	add	$a0, $s3, $zero		# place snake direction into $a0
	jal	updateSnake
	
	#Snake moves
	jal 	headPositionUpdate
	j	exitMoves
pointLeft:
	lw	$s3, goLeft		# snake direction
	add	$a0, $s3, $zero		# place snake direction into $a0
	jal	updateSnake
	
	# Snake moves
	jal 	headPositionUpdate
	j	exitMoves
pointRight:
	lw	$s3, goRight	# snake direction
	add	$a0, $s3, $zero	# place snake direction into $a0
	jal	updateSnake
	
	# Snake moves
	jal 	headPositionUpdate
	j	exitMoves
exitMoves:
	j 	updateLoop		#loop to start
	
# Change snake speed and size
updateSnake:
	addiu 	$sp, $sp, -24	# allocate 24 bytes for stack
	sw 	$fp, 0($sp)	# store caller's frame pointer
	sw 	$ra, 4($sp)	# store caller's return address
	addiu 	$fp, $sp, 20	# setup updateSnake frame pointer
	
	# draw snake head
	lw	$t0, xPos		# t0 = xPos of snake
	lw	$t1, yPos		# t1 = yPos of snake
	lw	$t2, xConvert		# t2 = 64
	mult	$t1, $t2		# multiply y position by 64
	mflo	$t3			# place previous value into t3
	add	$t3, $t3, $t0		# Take value in t3 and add x position then place back into t3
	lw	$t2, yConvert		# Set t2 = 4
	mult	$t3, $t2		# Take value in t3 and multiply it by 4
	mflo	$t0			# Set previous value equal to t0 in LO register
	la 	$t1, bufferSpace	# load frasme buffer address
	add	$t0, $t1, $t0		# add frame address to value in t0
	lw	$t4, 0($t0)		# load original pixel vlaue into t4
	sw	$a0, 0($t0)		# Store direction and color onto bitmap
	
	# Set Velocity
	lw	$t2, goUp			# load word snake up = 0x0000ff00
	beq	$a0, $t2, setSpeedUp		# if head direction and color == snake up branch to setSpeedUp
	
	lw	$t2, goDown			# load word snake up = 0x0100ff00
	beq	$a0, $t2, setSpeedDown	# if head direction and color == snake down branch to setSpeedUp
	
	lw	$t2, goLeft			# load word snake up = 0x0200ff00
	beq	$a0, $t2, setSpeedLeft	# if head direction and color == snake left branch to setSpeedUp
	
	lw	$t2, goRight			# load word snake up = 0x0300ff00
	beq	$a0, $t2, setSpeedRight	# if head direction and color == snake right branch to setSpeedUp
	
setSpeedUp:
	addi	$t5, $zero, 0		# set x speed to zero
	addi	$t6, $zero, -1	 	# set y speed to -1
	sw	$t5, xSpeed		# update xSpeed in memory
	sw	$t6, speedY		# update speedY in memory
	j exitSetSpeed
	
setSpeedDown:
	addi	$t5, $zero, 0		# set x speed to zero
	addi	$t6, $zero, 1 		# set y speed to 1
	sw	$t5, xSpeed		# update xSpeed in memory
	sw	$t6, speedY		# update speedY in memory
	j exitSetSpeed
	
setSpeedLeft:
	addi	$t5, $zero, -1		# set x speed to -1
	addi	$t6, $zero, 0 		# set y speed to zero
	sw	$t5, xSpeed		# update xSpeed in memory
	sw	$t6, speedY		# update speedY in memory
	j exitSetSpeed
	
setSpeedRight:
	addi	$t5, $zero, 1		# set x speed to 1
	addi	$t6, $zero, 0 		# set y speed to zero
	sw	$t5, xSpeed		# update xSpeed in memory
	sw	$t6, speedY		# update speedY in memory
	j exitSetSpeed
	
exitSetSpeed:
	# location check
	li 	$t2, 0x00ff0000		# load red color
	bne	$t2, $t4, headNoDot	# if head location is not the dot branch away
	
	jal 	newDotLocation
	jal	drawDot
	j	exitUpdateSnake
	
headNoDot:

	li	$t2, 0x00808080		# load gray color
	beq	$t2, $t4, validHeadSquare	# if head location is background branch away
	
	addi 	$v0, $zero, 10		# exit the program
	syscall
	
validHeadSquare:

	### Remove Tail
	lw	$t0, tail		# t0 = tail
	la 	$t1, bufferSpace	# load fb address
	add	$t2, $t0, $t1		# t2 = tail location on the bitmap display
	li 	$t3, 0x00808080		# load gray color
	lw	$t4, 0($t2)		# t4 = tail direction and color
	sw	$t3, 0($t2)		# replace tail with background color
	
	# update tail
	lw	$t5, goUp			# load word snake up = 0x0000ff00
	beq	$t5, $t4, setNextTailUp		# if tail direction and color == snake up branch to setNextTailUp
	
	lw	$t5, goDown			# load word snake up = 0x0100ff00
	beq	$t5, $t4, setNextTailDown	# if tail direction and color == snake down branch to setNextTailDown
	
	lw	$t5, goLeft			# load word snake up = 0x0200ff00
	beq	$t5, $t4, setNextTailLeft	# if tail direction and color == snake left branch to setNextTailLeft
	
	lw	$t5, goRight			# load word snake up = 0x0300ff00
	beq	$t5, $t4, setNextTailRight	# if tail direction and color == snake right branch to setNextTailRight
	
setNextTailUp:
	addi	$t0, $t0, -256		# tail = tail - 256
	sw	$t0, tail		# store  tail in memory
	j exitUpdateSnake
	
setNextTailDown:
	addi	$t0, $t0, 256		# tail = tail + 256
	sw	$t0, tail		# store  tail in memory
	j exitUpdateSnake
	
setNextTailLeft:
	addi	$t0, $t0, -4		# tail = tail - 4
	sw	$t0, tail		# store  tail in memory
	j exitUpdateSnake
	
setNextTailRight:
	addi	$t0, $t0, 4		# tail = tail + 4
	sw	$t0, tail		# store  tail in memory
	j exitUpdateSnake
	
exitUpdateSnake:
	
	lw 	$ra, 4($sp)	# load caller's return address
	lw 	$fp, 0($sp)	# restores caller's frame pointer
	addiu 	$sp, $sp, 24	# restores caller's stack pointer
	jr 	$ra		# return to caller's code
	
headPositionUpdate:
	addiu 	$sp, $sp, -24	# allocate 24 bytes for stack
	sw 	$fp, 0($sp)	# store caller's frame pointer
	sw 	$ra, 4($sp)	# store caller's return address
	addiu 	$fp, $sp, 20	# setup updateSnake frame pointer	
	
	lw	$t3, xSpeed	# load xSpeed from memory
	lw	$t4, speedY	# load speedY from memory
	lw	$t5, xPos	# load xPos from memory
	lw	$t6, yPos	# load yPos from memory
	add	$t5, $t5, $t3	# update x pos
	add	$t6, $t6, $t4	# update y pos
	sw	$t5, xPos	# store updated xpos back to memory
	sw	$t6, yPos	# store updated ypos back to memory
	
	lw 	$ra, 4($sp)	# load caller's return address
	lw 	$fp, 0($sp)	# restores caller's frame pointer
	addiu 	$sp, $sp, 24	# restores caller's stack pointer
	jr 	$ra		# return to caller's code

# this function draws the dot base upon x and y coordintes
drawDot:
	addiu 	$sp, $sp, -24	# allocate 24 bytes for stack
	sw 	$fp, 0($sp)	# store caller's frame pointer
	sw 	$ra, 4($sp)	# store caller's return address
	addiu 	$fp, $sp, 20	# setup updateSnake frame pointer
	
	lw	$t0, dotX		# t0 = xPos of dot
	lw	$t1, dotY		# t1 = yPos of dot
	lw	$t2, xConvert	# t2 = 64
	mult	$t1, $t2		# dotY * 64
	mflo	$t3			# t3 = dotY * 64
	add	$t3, $t3, $t0		# t3 = dotY * 64 + dotX
	lw	$t2, yConvert	# t2 = 4
	mult	$t3, $t2		# (yPos * 64 + dotX) * 4
	mflo	$t0			# t0 = (dotY * 64 + dotX) * 4
	
	la 	$t1, bufferSpace	# load fb address
	add	$t0, $t1, $t0		# t0 = (dotY * 64 + dotX) * 4 + frame address
	li	$t4, 0x00ff0000
	sw	$t4, 0($t0)		# store direction plus color on the bitmap display
	
	lw 	$ra, 4($sp)	# load caller's return address
	lw 	$fp, 0($sp)	# restores caller's frame pointer
	addiu 	$sp, $sp, 24	# restores caller's stack pointer
	jr 	$ra		# return to caller's code	

# New dot location
newDotLocation:
	addiu 	$sp, $sp, -24	# allocate 24 bytes for stack
	sw 	$fp, 0($sp)	# store caller's frame pointer
	sw 	$ra, 4($sp)	# store caller's return address
	addiu 	$fp, $sp, 20	# setup updateSnake frame pointer

redoRandom:		
	addi	$v0, $zero, 42	# random int 
	addi	$a1, $zero, 63	# upper bound
	syscall
	add	$t1, $zero, $a0	# random dotX
	
	addi	$v0, $zero, 42	# random int 
	addi	$a1, $zero, 31	# upper bound
	syscall
	add	$t2, $zero, $a0	# random dotY
	
	lw	$t3, xConvert		# t3 = 64
	mult	$t2, $t3		# random dotY * 64
	mflo	$t4			# t4 = random dotY * 64
	add	$t4, $t4, $t1		# t4 = random dotY * 64 + random dotX
	lw	$t3, yConvert		# t3 = 4
	mult	$t3, $t4		# (random dotY * 64 + random dotX) * 4
	mflo	$t4			# t1 = (random dotY * 64 + random dotX) * 4
	
	la 	$t0, bufferSpace	# load fb address
	add	$t0, $t4, $t0		# t0 = (dotY * 64 + dotX) * 4 + frame address
	lw	$t5, 0($t0)		# t5 = value of pixel at t0
	
	li	$t6, 0x00808080		# load gray color
	beq	$t5, $t6, niceDot	# if location is a good square branch to niceDot
	j redoRandom

niceDot:
	sw	$t1, dotX
	sw	$t2, dotY	

	lw 	$ra, 4($sp)	# load caller's return address
	lw 	$fp, 0($sp)	# restores caller's frame pointer
	addiu 	$sp, $sp, 24	# restores caller's stack pointer
	jr 	$ra		# return to caller's code
