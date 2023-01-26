#importonce

.label DEBUG_COLOR1 = 11
.label DEBUG_COLOR2 = 12

.macro debug1() {
    lda #DEBUG_COLOR1
    sta $d020
}

.macro debug2() {
    lda #DEBUG_COLOR2
    sta $d020
}

.macro debugoff(color) {
    lda #color
    sta $d020
}