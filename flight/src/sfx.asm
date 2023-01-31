#importonce


.const SFX_VOICE=$d400
.const FREQ = 5000
.const LENGTH = 4

sfx: {
    .segment Default

play:
    lda sound_on
    bne !+
    {
        lda timer
        bne !+
        jmp shutoff_voice
    !:
        lda freq
        sec
        sbc #4
        sta freq
        sta SFX_VOICE+1
        dec timer
        rts

    }
!:
    jsr shutoff_voice

    lda #LENGTH
    sta timer

    // Set frequency
    lda #<FREQ
    sta SFX_VOICE
    lda #>FREQ
    sta freq
    sta SFX_VOICE+1

    // PW
    lda #0
    sta SFX_VOICE+2
    lda #7
    sta SFX_VOICE+3

    // Attack/Decay
    lda #$02
    sta SFX_VOICE+5

    // Sustain/Release
    lda #$38
    sta SFX_VOICE+6

    // Waveform
    lda #$41
    sta SFX_VOICE+4

    rts

shutoff_voice:
    lda #40
    sta SFX_VOICE+1
    lda #$80
    sta SFX_VOICE+4
    rts

sound_on:
    .byte 0

    .segment DATA

timer:
    .byte 0
freq:
    .byte 0
}
