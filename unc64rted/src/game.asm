#importonce

game:
{
    sei
    jsr init

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

init:
    lda #0
    sta gameover

    lda #32
    ldx #0
!:
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x
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

    lda #50
    sta $d001
    lda spritex
    sta $d000
    inc spritex
    inc spritex
    bne !+
    lda #1
    sta gameover
!:
    lda #$ff
    sta $d019

    lda a_temp:#0
    ldx x_temp:#0
    ldy y_temp:#0
    rti
}

gameover:
    .byte 0
spritex:
    .byte 0
.align $40
spritedata:
    .byte $ff,$ff,$ff
    .for (var i = 1; i < 20; i++) {
        .byte $80,$00,$01
    }
    .byte $ff, $ff, $ff
}