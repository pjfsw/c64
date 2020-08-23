#importonce

.const BLOCK=$E0
.const SPACE=$20

game:
{
    sei
    lda #0
    sta gameover

    jsr init_screen
    jsr draw_map

    lda #<irq
    sta $fffe
    lda #>irq
    sta $ffff
    cli
!:
    lda gameover
    beq !-

    lda #0
    sta $d015


    rts

draw_map:
    lda #BLOCK
    ldx #34
!:
    sta $0400,x
    sta $0400+40*24,x
    dex
    bpl !-

.for (var i = 1; i < 24; i++) {
    sta $0400+i*40
    sta $0400+i*40+34
}

    rts

init_screen:
    lda #0
    sta playerx

// Clear screen
    lda #32
    ldx #0
!:
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x
    inx
    bne !-
// Clear colors
    lda #LIGHT_GRAY
    ldx #0
!:
    sta $d800,x
    sta $d900,x
    sta $da00,x
    sta $db00,x
    inx
    bne !-

    lda #spritedata/64
    sta $07f8

    lda #255
    sta $d015

    lda #WHITE
    sta $d027

    rts

irq:
{
    sta a_temp
    stx x_temp
    sty y_temp

    lda #$ff
    sta $d019

    lda #BLUE
    sta $d020

    clc
    lda playerx
    adc #24
    sta spritex_lo
    rol
    and #1
    sta spritex_hi

    clc
    lda playery
    adc #50
    sta spritey

    ldx #7
    ldy #14
!:
    lda spritex_lo,x
    sta $d000,y
    lda spritey,x
    sta $d001,y
    dey
    dey
    dex
    bpl !-

    ldx #7
    lda #0
!:
    asl
    ora spritex_hi,x
    dex
    bpl !-

    sta $d010

    lda #BLACK
    sta $d020
    lda a_temp:#0
    ldx x_temp:#0
    ldy y_temp:#0
    rti
}

gameover:
    .byte 0
playerx:
    .byte 0
playery:
    .byte 0

ypos_lo:
    .fill 25, <($400+i*40)
ypos_hi:
    .fill 25, >($400+i*40)

.align $40
spritedata:
    .byte $ff,$ff,$ff
    .for (var i = 1; i < 20; i++) {
        .byte $80,$00,$01
    }
    .byte $ff, $ff, $ff

map:
    .byte %11111111, %11111111, %11111111, %11111111, %11111111
    .byte %10000000, %00000000, %00000000, %00000000, %00000111
    .byte %10000000, %00000000, %00000000, %00000000, %00000111
    .byte %10000000, %00000000, %00000000, %00000000, %00000111

    .byte %10000000, %00000000, %00000000, %00000000, %00000111
    .byte %10000000, %00000000, %00000000, %00000000, %00000111
    .byte %10000000, %00000000, %00000000, %00000000, %00000111
    .byte %10000000, %00000000, %00000000, %00000000, %00000111

    .byte %10000000, %00000000, %00000000, %00000000, %00000111
    .byte %11111100, %00000000, %11111100, %00000000, %00000111
    .byte %10000000, %00000000, %00000000, %00000000, %00000111
    .byte %10000000, %00000000, %00000000, %00000000, %00000111

    .byte %10000000, %00000000, %00000000, %00000000, %00000111
    .byte %10000000, %00000000, %00000000, %00000000, %00000111
    .byte %10000000, %00000000, %00000000, %00000000, %00000111
    .byte %10000000, %00000000, %00000000, %00000000, %00000111

    .byte %10000000, %00000000, %00000000, %00000000, %00000111
    .byte %10000000, %00000000, %00000000, %00000000, %00000111
    .byte %10000000, %00000000, %00000000, %00000000, %00000111
    .byte %10000000, %00000000, %00000000, %00000000, %00000111

    .byte %10000000, %00000000, %00000000, %00000000, %00000111
    .byte %10000000, %00000000, %00000000, %00000000, %00000111
    .byte %10000000, %00000000, %00000000, %00000000, %00000111
    .byte %10000000, %00000000, %00000000, %00000000, %00000111

    .byte %11111111, %11111111, %11111111, %11111111, %11111111

.label CODE=*
*=$02 "Zeropage" virtual
.zp {
    .byte 0
}
*=$F000 "Temp variables" virtual
spritex_lo:
    .byte 0,0,0,0,0,0,0,0
spritex_hi:
    .byte 0,0,0,0,0,0,0,0
spritey:
    .byte 0,0,0,0,0,0,0,0
* = CODE
}