#importonce

#import "vic.asm"

.const SPRITE_MIN_X = 8
.const SPRITE_MAX_X = 222
.const SPRITE_MIN_Y = 8
.const SPRITE_MAX_Y = 164
game:
{
    sei
    lda #<irq
    sta $fffe
    lda #>irq
    sta $ffff

    jsr init_game
    jsr load_room
    cli

    jmp *

    lda #0
    sta SPRITE_ENABLE // Disable sprites
    rts

init_game:
// Clear screen memory
    lda #32
    ldx #0
!:
    sta SCREEN_MEM,x
    sta SCREEN_MEM+$100,x
    sta SCREEN_MEM+$200,x
    sta SCREEN_MEM+$300,x
    inx
    bne !-

    lda #DARK_GRAY
    ldx #0
!:
    sta COLOR_RAM,x
    sta COLOR_RAM+$100,x
    sta COLOR_RAM+$200,x
    sta COLOR_RAM+$300,x
    inx
    bne !-

// Initialize coords
    lda #SPRITE_MIN_X
    sta spriteX
    lda #SPRITE_MIN_Y
    sta spriteY

// Enable sprite 0
    lda #WHITE
    sta SPRITE0_COLOR
    sta SPRITE0_COLOR + 1
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
    lda #<SCREEN_MEM
    sta.z screenPtr
    lda #>SCREEN_MEM
    sta.z screenPtr+1

    lda #<room
    sta.z roomPtr
    lda #>room
    sta.z roomPtr+1

    ldx #24 // rows
!:
    {
        ldy #0  // cols
    !:
        lda (roomPtr),y
        sta (screenPtr),y
        iny
        cpy #32
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
        adc #32
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

animate:
    lda moveX
    ora moveY
    bne !+
    lda playerAnim
    sta SPRITE_PTR
    rts
!:
    lda animFrame
    adc #1
    sta animFrame
    lsr
    lsr
    and #1
    tax
    lda playerAnim+1,x
    sta SPRITE_PTR
    rts

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
spriteData:
#import "../resources/mysprites.txt"

//=================================================================================================
// LUT
//=================================================================================================
spriteXTable:
    .fill 256,<(i+24+8)
spriteHiTable:
    .fill 256,>(i+24+8)
spriteYTable:
    .fill 256,<(i+50+8)
playerAnim:
    .byte spriteData>>6                         // idle
    .byte (spriteData>>6)+1, (spriteData>>6)+2  // move

.label TILE = $a0
room:
    .fill 32, TILE
    .for (var y = 0; y < 22; y++) {
        .byte TILE
        .fill 30, 32
        .byte TILE
    }
    .fill 32, TILE



.label CODE=*
*=$02 "Zeropage" virtual
.zp {
    .byte 0
roomPtr:
    .byte 0,0
screenPtr:
    .byte 0,0
}
*=$E000 "Temp variables" virtual
spriteX:
    .fill 8,0
spriteY:
    .fill 8,0
animFrame:
    .byte 0
gameover:
    .byte 0
moveX:
    .byte 0
moveY:
    .byte 0

* = CODE
}