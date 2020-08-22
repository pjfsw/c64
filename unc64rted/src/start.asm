#importonce
.encoding "screencode_upper"

start:
{
    lda #0
    sta $d020
    sta $d021

    ldx #0
!:
    lda message,x
    sta $0400,x
    inx
    cpx #message_length
    bne !-

    rts

message: .text "UNC64RTED. PRESS FIRE TO PLAY"
.label message_length=*-message
}