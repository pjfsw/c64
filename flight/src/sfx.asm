#importonce


.const SFX_VOICE=$d400
.const GUN_LENGTH = 2
.const EXPLOSION_LENGTH = 8

sfx: {
    .segment Default

play:
    lda sound_on
    bne !play_sound+

    lda timer
    beq !+

    dec timer

    // Continue and modulate
    ldx current_sound
    clc
    lda freq
    adc pitch_mod,x
    sta freq
    sta SFX_VOICE+1
    rts
!:
    // Sound finished
    jmp sound_off

    // New sound
!play_sound:
    sta save_a_to_x

    jsr sound_off

    ldx save_a_to_x:#0
    dex

    // Set frequency
    lda pitch_lo,x
    sta SFX_VOICE
    lda pitch_hi,x
    sta sfx.freq
    sta SFX_VOICE+1

    // PW
    lda #0
    sta SFX_VOICE+2
    lda pulse_hi,x
    sta SFX_VOICE+3

    // Attack/Decay
    lda attack_decay,x
    sta SFX_VOICE+5

    // Sustain/Release
    lda sustain_release,x
    sta SFX_VOICE+6

    // Waveform
    lda voice_control,x
    sta SFX_VOICE+4

    stx current_sound
    lda length,x
    sta timer

    rts

sound_off:
    ldx current_sound
    lda pitch_end_hi,x
    sta SFX_VOICE+1
    lda voice_control_off,x
    sta SFX_VOICE+4
    rts

sound_on:
    .byte 0

attack_decay:
    .byte $02, $15
sustain_release:
    .byte $38, $58
voice_control:
    .byte $41, $81
voice_control_off:
    .byte $80, $80
pulse_hi:
    .byte $08, $08
pitch_lo:
    .byte <5000, <3000
pitch_hi:
    .byte >5000, >3000
pitch_end_hi:
    .byte >3000, >1000

pitch_mod:
    .byte $fb, $ff
length:
    .byte GUN_LENGTH, EXPLOSION_LENGTH

    .segment DATA

current_sound:
    .byte 0
timer:
    .byte 0
freq:
    .byte 0
}

.macro sound_on(f, pw, ad, sr, wav) {
    // Set frequency
    lda #<f
    sta SFX_VOICE
    lda #>f
    sta sfx.freq
    sta SFX_VOICE+1

    // PW
    lda #<pw
    sta SFX_VOICE+2
    lda #>pw
    sta SFX_VOICE+3

    // Attack/Decay
    lda #ad
    sta SFX_VOICE+5

    // Sustain/Release
    lda #sr
    sta SFX_VOICE+6

    // Waveform
    lda #wav
    sta SFX_VOICE+4
}
