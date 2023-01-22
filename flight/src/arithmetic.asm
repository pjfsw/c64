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

// C=0,Z=0: value < immediate, C=1,Z=1: value = immediate, C=1,Z=0, value > immediate
.macro cmp16(low_byte,high_byte,immediate) {
//16-bit number comparison...
    lda high_byte     // MSB of 1st number
    cmp #>immediate   // MSB of 2nd number
    bcc !+            // value < immediate
    bne !+            // value > immediate

    lda low_byte      // LSB of 1st number
    cmp #<immediate   // LSB of 2nd number
!:
}