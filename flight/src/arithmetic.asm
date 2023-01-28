#importonce

.macro copy16(src,dest) {
    lda src
    sta dest
    lda src+1
    sta dest+1
}

.macro add8(src,immediate,dest) {
    clc
    lda src
    adc #immediate
    sta dest
    bcc !+
    inc dest+1
!:
}

.macro add_16_8_mem(a16,b8,dest) {
    clc
    lda a16+1
    sta dest+1
    lda a16
    adc b8
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

.macro sub16mem(a,b,dest) {
    sec
    lda a
    sbc b
    sta dest
    lda a+1
    sbc b+1
    sta dest+1
}

// C=0,Z=0: value < immediate, C=1,Z=1: value = immediate, C=1,Z=0, value > immediate
.macro cmp16lo_hi(low_byte,high_byte,immediate) {
//16-bit number comparison...
    lda high_byte     // MSB of 1st number
    cmp #>immediate   // MSB of 2nd number
    bcc !+            // value < immediate
    bne !+            // value > immediate

    lda low_byte      // LSB of 1st number
    cmp #<immediate   // LSB of 2nd number
!:
}

.macro cmp16(memory,immediate) {
    cmp16lo_hi(memory,memory+1,immediate)
}

// Compare with index in X
.macro cmp16x(low_byte,high_byte,immediate) {
//16-bit number comparison...
    lda high_byte,x    // MSB of 1st number
    cmp #>immediate   // MSB of 2nd number
    bcc !+            // value < immediate
    bne !+            // value > immediate

    lda low_byte,x      // LSB of 1st number
    cmp #<immediate   // LSB of 2nd number
!:
}

.macro cmp16x_mem(low_byte,high_byte,memory) {
//16-bit number comparison...
    lda high_byte,x    // MSB of 1st number
    cmp memory+1   // MSB of 2nd number
    bcc !+            // value < immediate
    bne !+            // value > immediate

    lda low_byte,x      // LSB of 1st number
    cmp memory   // LSB of 2nd number
!:
}

.macro cmp16mem(src, dest) {
    lda src+1     // MSB of 1st number
    cmp dest+1    // MSB of 2nd number
    bcc !+            // value < immediate
    bne !+            // value > immediate

    lda src      // LSB of 1st number
    cmp dest     // LSB of 2nd number
!:
}
