#importonce

.macro add8(src,immediate,dest) {
    clc
    lda src
    adc #immediate
    sta dest
    bcc !+
    inc dest+1
!:
}

.macro sub8(src,immediate,dest) {
    sec
    lda src
    sbc #immediate
    sta dest
    bcs !+
    dec dest+1
!:
}

.macro add16(src,immediate,dest) {
    clc
    lda src
    adc #<immediate
    sta dest
    lda src+1
    adc #>immediate
    sta dest+1
}

.macro sub16(src,immediate,dest) {
    sec
    lda src
    sbc #<immediate
    sta dest
    lda src+1
    sbc #>immediate
    sta dest+1
}
