.const SCREEN = $0400
.const SPRITEPTR = $07f8

BasicUpstart2(programStart)
    *=$080e

programStart:
    lda #GRAY
    sta $d020
    lda #BLACK
    sta $d021

    jsr initMemory
    jsr clearScreen
    jsr initSpriteData

    sei
    lda #<irq
    sta $fffe
    lda #>irq
    sta $ffff
    cli

!:
    jmp !-

initSpriteData:
    lda #1
    sta $d015
    lda #shipSprite/64
    sta SPRITEPTR
    lda #bulletSprite/64
    sta SPRITEPTR+1
    sta SPRITEPTR+2
    sta SPRITEPTR+3
    lda #0
    sta spriteX
    rts

clearScreen:
    lda #32
    ldx #0
!:
    sta SCREEN,x
    sta SCREEN+$100,x
    sta SCREEN+$200,x
    sta SCREEN+$300,x
    inx
    bne !-
    rts

initMemory:
    sei

    lda #$35    // RAM $0000-$CFFF, IO $D000-$DFFF, RAM $E000-$FFFF
    sta $01

    lda #$7f    // Clear CIA interrupts
    sta $dc0d
    sta $dd0d
    lda $dc0d   // Clear pending interrupts by reading it
    lda $dd0d

    lda #$01
    sta $d01a   // Raster IRQ enable

    lda #$f8    // Raster Y position
    sta $d012

    lda #$1b    // 25 rows
    sta $d011

    lda #$c8    // 40 cols, two color
    sta $d016

    rts

irq: {
    sta a_temp
    stx x_temp
    sty y_temp

    lda #BLACK
    sta $d020
    readInput()
    movePlayer()
    drawSprites()
    lda #GRAY
    sta $d020

    asl $d019
    lda a_temp:#0
    ldx x_temp:#0
    ldy y_temp:#0
    rti
}

.macro drawSprites() {
    lda #0
    .for (var sprite = 7; sprite >= 0; sprite--) {
        tay
        ldx spriteY + sprite
        lda spriteYTable, x
        sta $d001 + sprite*2

        ldx spriteX + sprite
        lda spriteXTable, x
        sta $d000 + sprite*2

        tya
        asl
        ora spriteHiTable, x
    }
    sta $d010
}

.macro readInput() {
    lda #0
    sta moveX
    sta moveY
    sta fire
    ldx #1
    ldy #-1
    lda $dc00
    and $dc01
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
!:
    ror
    bcs !+
    stx moveX
!:
    ror
    bcs !+
    stx fire
!:
}

.macro movePlayer() {
    ldx playerX
    lda moveX
    beq !+
    {
        bmi !+
        lda moveRight,x
        sta playerX
        jmp done
    !:
        lda moveLeft,x
        sta playerX
    done:
    }
!:
}

//--------------------------------------------------------------------------------------------------
// DATA
//--------------------------------------------------------------------------------------------------

playerX:
spriteX:
    .fill 8,0
spriteHi:
    .fill 8,0
spriteY:
    .fill 8,179

moveX:
    .byte 0
moveY:
    .byte 0

//--------------------------------------------------------------------------------------------------
// SPRITE DEFINITIONS
//--------------------------------------------------------------------------------------------------
    .align $40
shipSprite:
    .byte %00000000, %00011000, %00000000
    .byte %00000000, %00011000, %00000000
    .byte %00000000, %00011000, %00000000
    .byte %00000000, %00011000, %00000000
    .byte %00000000, %00111100, %00000000
    .byte %00000000, %00111100, %00000000
    .byte %00000000, %01111110, %00000000

    .byte %11000000, %01111110, %00000011
    .byte %11000000, %11111111, %00000011
    .byte %11000000, %11111111, %00000011
    .byte %11000001, %11111111, %10000011
    .byte %11000011, %11111111, %11000011
    .byte %11110111, %11111111, %11101111
    .byte %11111111, %11111111, %11111111

    .byte %11111111, %11111111, %11111111
    .byte %11111111, %11111111, %11111111
    .byte %11111111, %11111111, %11111111
    .byte %11011111, %11111111, %11111011
    .byte %01101111, %11111111, %11110110
    .byte %01100011, %11111111, %11000110
    .byte %01100000, %11111111, %00000110

    .align $40
bulletSprite:
    .byte %00000000, %00000000, %00000000
    .byte %00000000, %00011000, %00000000
    .byte %00000000, %00011000, %00000000
    .byte %00000000, %00011000, %00000000
    .byte %00000000, %00011000, %00000000
    .byte %00000000, %00011000, %00000000

    .byte %00000000, %00000000, %00000000
    .byte %00000000, %00011000, %00000000
    .byte %00000000, %00011000, %00000000
    .byte %00000000, %00011000, %00000000
    .byte %00000000, %00011000, %00000000
    .byte %00000000, %00011000, %00000000

    .byte %00000000, %00000000, %00000000
    .byte %00000000, %00011000, %00000000
    .byte %00000000, %00011000, %00000000
    .byte %00000000, %00011000, %00000000
    .byte %00000000, %00011000, %00000000
    .byte %00000000, %00011000, %00000000


.const SPRITE_X_OFFSET = 16
spriteXTable:
    .fill 256,<(SPRITE_X_OFFSET + i + 24)
spriteHiTable:
    .fill 256,>(SPRITE_X_OFFSET + i + 24)
spriteYTable:
    .fill 256,<(i+50)

.const MOVE_SPEED = 4
moveLeft:
    .for (var i = 0; i < 256 ; i++) {
        .if (i > MOVE_SPEED) {
            .byte i-MOVE_SPEED
        } else {
            .byte 0
        }
    }
moveRight:
    .for (var i = 0; i < 256 ; i++) {
        .if (i < 256-MOVE_SPEED) {
            .byte i+MOVE_SPEED
        } else {
            .byte 255
        }
    }

