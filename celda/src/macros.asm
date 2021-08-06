#importonce

.macro ptr(target, source) {
    lda #<source
    sta target
    lda #>source
    sta target+1
}