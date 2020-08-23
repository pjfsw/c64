#importonce
.encoding "screencode_upper"

.const TITLE_ROW = 10;

start:
{
    sei
    ldx #0
!:
    lda message,x
    sta $0400+TITLE_ROW*40+(40-message_length)/2,x
    inx
    cpx #message_length
    bne !-

    lda #<irq
    sta $fffe
    lda #>irq
    sta $ffff
    cli

!:
    lda $dc01
    and #$10
    beq !-
!:
    lda $dc01
    and #$10
    bne !-

    rts

irq: {
    sta a_temp
    stx x_temp
    sty y_temp

    inc color_index
    lda color_index
    lsr
    lsr
    and #7
    tax
    lda color_table,x
    ldx #40
!:
    sta $d800+TITLE_ROW*40,x
    dex
    bpl !-

    lda #$ff
    sta $d019

    lda a_temp:#0
    ldx x_temp:#0
    ldy y_temp:#0
    rti
}

message: .text "UNC64RTED. PRESS FIRE TO PLAY"
.label message_length=*-message
color_index: .byte 0
color_table: .byte BLACK, BLUE, PURPLE, LIGHT_RED, WHITE, LIGHT_RED, PURPLE, BLUE
}