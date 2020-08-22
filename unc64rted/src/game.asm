#importonce

game:
{
    lda #<irq
    sta $fffe
    lda #>irq
    sta $ffff

    rts

irq:
{
    sta a_temp
    stx x_temp
    sty y_temp

    lda #$ff
    sta $d019

    lda a_temp:#0
    ldx x_temp:#0
    ldy y_temp:#0
    rti
}
}