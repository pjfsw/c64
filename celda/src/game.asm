#importonce

#import "vic.asm"
#import "macros.asm"

.const SPRITE_MIN_X = 2
.const SPRITE_MAX_X = 254
.const ROOM_WIDTH = 34
.const ROOM_HEIGHT = 25
.const X_OFFSET = 3
.const SPRITE_X_OFFSET = X_OFFSET * 8 - 4
.const Y_OFFSET = 0
.const SPRITE_Y_OFFSET = Y_OFFSET * 8 - 5
.const SPRITE_MIN_Y = 0
.const SPRITE_MAX_Y = SPRITE_MIN_Y + ROOM_HEIGHT*8-21

game:
{
    sei
    ptr($fffe, irq)

    jsr init_game
    jsr load_room
    cli

    jmp *

    lda #0
    sta SPRITE_ENABLE // Disable sprites
    rts

clearScreen:
    ptr(screenPtr, SCREEN_MEM)
    ptr(tmpPtr, COLOR_RAM)

    ldx #24
!:  {
        ldy #39
    !:
        lda backgroundData,y
        sta (screenPtr),y
        lda colorData,y
        sta (tmpPtr),y
        dey
        bpl !-

        clc
        lda screenPtr
        adc #40
        sta screenPtr
        sta tmpPtr
        bcc !+
        inc screenPtr+1
        inc tmpPtr+1
    !:
    }
    dex
    bpl !-

    rts

init_game:
    jsr clearScreen

// Initialize coords
    lda #SPRITE_MIN_X+8
    sta spriteX
    lda #SPRITE_MIN_Y+8
    sta spriteY

// Enable sprite 0
    lda #1
    sta SPRITE_MULTI_COLOR
    lda #$0f // sprite multicolor 1
    sta SPRITE_EXTRA_COLOR1
    lda #$09 // sprite multicolor 2
    sta SPRITE_EXTRA_COLOR2
    lda #$0a
    sta SPRITE0_COLOR
    lda #1
    sta SPRITE_ENABLE

// Initialize animations
    lda #0
    sta animFrame
    rts

//
// Load current room
//
load_room:
    ptr(screenPtr, SCREEN_MEM+X_OFFSET+40*Y_OFFSET)
    ptr(roomPtr, room)

    ldx #ROOM_HEIGHT // rows
!:
    {
        ldy #0  // cols
    !:
        lda (roomPtr),y
        sta (screenPtr),y
        iny
        cpy #ROOM_WIDTH
        bne !-

        clc
        lda screenPtr
        adc #40
        sta screenPtr
        bcc !+
        inc screenPtr+1
    !:
        clc
        lda roomPtr
        adc #ROOM_WIDTH
        sta roomPtr
        bcc !+
        inc roomPtr+1
    !:
    }
    dex
    bne !-

    rts

//
// IRQ handler
//
irq:
{
    sta a_temp
    stx x_temp
    sty y_temp

    asl $d019

    lda #BLUE
    sta $d020
// IRQ CODE START

    jsr readInput
    jsr checkCollision
    jsr movePlayer
    jsr animate
    jsr drawSprites

// IRQ CODE END
    lda #BLACK
    sta $d020
    lda a_temp:#0
    ldx x_temp:#0
    ldy y_temp:#0
    rti
}

readInput:
    lda #0
    sta moveX
    sta moveY
    ldx #1
    ldy #-1
    lda JOYSTICK_PORT_2
    and JOYSTICK_PORT_1
    // 0 - up, 1 - down, 2 - left, 3 - right, 4 - fire
    ror
    bcs !+
    sty moveY
!:
    ror
    bcs !+
    stx moveY
!:
    ror
    bcs !+
    sty moveX
    rts
!:
    ror
    bcs !+
    stx moveX
!:
    rts

movePlayer:
    clc
    lda moveY
    beq !+
    adc spriteY
    cmp #SPRITE_MIN_Y
    bcc !+
    cmp #SPRITE_MAX_Y
    bcs !+
    sta spriteY
    rts
!:
    clc
    lda moveX
    adc spriteX
    cmp #SPRITE_MIN_X
    bcc !+
    cmp #SPRITE_MAX_X
    bcs !+
    sta spriteX
!:
    rts

checkCollision:
    clc
    lda moveY
    beq !checkX+
    bmi !checkUp+

//check down
    adc spriteY
    adc #15 // Colliders are 16x16
    jmp checkVerticalCollision

!checkUp:
    adc spriteY
    jmp checkVerticalCollision

!checkX:
    lda moveX
    bmi !checkLeft+
    bne !checkRight+
    rts
!checkLeft:
    adc spriteX
    jmp checkHorizontalCollision

!checkRight:
    adc spriteX
    adc #15
    jmp checkHorizontalCollision
    rts

// Forward y coordinate in A!
checkVerticalCollision:
    tay
    lda rowLoTable,y
    sta tmpPtr
    lda rowHiTable,y
    sta tmpPtr+1
    ldy spriteX
    lda colTable,y
    clc
    adc tmpPtr
    sta tmpPtr
    bcc !+
    inc tmpPtr+1
!:
    tya
    ldy #2
    and #7
    bne !+
    // We are aligned perfectly on a char so only need to check two columns
    ldy #1
!:
    lda (tmpPtr),y
    cmp #32
    bne !collision+
    dey
    bpl !-
    rts

!collision:
    lda #0
    sta moveX
    sta moveY
    rts

// Forward x coordinate in A!
checkHorizontalCollision:
    tax
    ldy spriteY
    lda rowLoTable,y
    sta tmpPtr
    lda rowHiTable,y
    sta tmpPtr+1
    ldy spriteX
    lda colTable,x
    clc
    adc tmpPtr
    sta tmpPtr
    bcc !+
    inc tmpPtr+1
!:
    ldy #0
    lda spriteY
    ldx #2
    and #7
    bne !+
    // We are aligned perfectly on a char so only need to check two rows
    ldx #1
!:
    lda (tmpPtr),y
    cmp #32
    bne !collision-
    {
        clc
        lda tmpPtr
        adc #40
        sta tmpPtr
        bcc !+
        inc tmpPtr+1
    !:
    }
    dex
    bpl !-
    rts


animate: {
    //lda #debugSprite/64
    //sta SPRITE_PTR
    //rts

    ldy #0  // Direction
    lda moveY
    bmi !animateDown+
    bne !updateAnimation+
    ldy #6
    lda moveX
    bmi !animateLeft+
    bne !updateAnimation+
    clc
    lda #playerSpritePtr
    adc animDirection
    sta SPRITE_PTR
    rts
!animateLeft:
    ldy #9
    jmp !updateAnimation+
!animateDown:
    ldy #3
!updateAnimation:
    sty animDirection

    lda animFrame
    and #1

    ldx frameCount
    inx
    cpx #5
    bcc !+
    ldx #0
    eor #1
    sta animFrame
!:
    stx frameCount
    clc
    adc #playerSpritePtr+1
    adc animDirection

    sta SPRITE_PTR
    rts
}

drawSprites:
    lda #0
    .for (var sprite = 7; sprite >= 0; sprite--) {
        tay
        ldx spriteY + sprite
        lda spriteYTable, x
        sta SPRITE0_Y + sprite*2

        ldx spriteX + sprite
        lda spriteXTable, x
        sta SPRITE0_X + sprite*2

        tya
        asl
        ora spriteHiTable, x
    }
    sta SPRITE_X_HI
    rts

//=================================================================================================
// Graphics
//=================================================================================================
.align $40
debugSprite:
.fill 16,[255,255,0]
.fill 5, [0,0,0]
.align $40
spriteData:
#import "../resources/mysprites.txt"

.label playerSpritePtr = spriteData >> 6

animDirection:
    .byte 0

//=================================================================================================
// LUT
//=================================================================================================
spriteXTable:
    .fill 256,<(i + 24 + SPRITE_X_OFFSET)
spriteHiTable:
    .fill 256,>(i + 24 + SPRITE_X_OFFSET)
spriteYTable:
    .fill 256,<(i+50 + SPRITE_Y_OFFSET)

rowLoTable:
    .fill 256,<(SCREEN_MEM + (i>>3)*40)
rowHiTable:
    .fill 256,>(SCREEN_MEM + (i>>3)*40)
colTable:
    .fill 256,(i>>3)+X_OFFSET

.label TILE = $a0
room:
    .fill ROOM_WIDTH, TILE
    .for (var y = 0; y < ROOM_HEIGHT-2; y++) {
        .byte TILE
        .if (y==12 || y==13) {
        .fill 10, TILE
        .fill ROOM_WIDTH-22, 32
        .fill 10, TILE
        } else {
        .byte TILE
        .fill ROOM_WIDTH-4, 32
        .byte TILE
        }
        .byte TILE
    }
    .fill ROOM_WIDTH, TILE

colorData:
    .fill X_OFFSET, 0
    .fill ROOM_WIDTH, GRAY
    .fill 40 - ROOM_WIDTH - X_OFFSET, 0
backgroundData:
    .fill X_OFFSET, 128+32
    .fill ROOM_WIDTH, 32
    .fill 40 - ROOM_WIDTH - X_OFFSET, 128+32

.label CODE=*
*=$02 "Zeropage" virtual
.zp {
    .byte 0
roomPtr:
    .byte 0,0
screenPtr:
    .byte 0,0
tmpPtr:
    .byte 0,0
}
*=$E000 "Temp variables" virtual
spriteX:
    .fill 8,0
spriteY:
    .fill 8,0
animFrame:
    .byte 0
frameCount:
    .byte 0
gameover:
    .byte 0
moveX:
    .byte 0
moveY:
    .byte 0
* = CODE
}