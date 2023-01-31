#importonce


.const SFX_VOICE=$d400
.const GUN_LENGTH = 4
.const EXPLOSION_LENGTH = 8

sfx: {
    .segment Default

play:
    lda sound_on
    bne !play_sound+

    lda timer
    beq !+

    dec timer

    // Continue sound
    jmp modulate_ptr:nil // Modulate sound
!:
    // Sound finished
    jmp sound_off_ptr:nil // Sound off

    // New sound
!play_sound:
    sta save_a_to_x

    jsr sound_off_ptr2:nil // Sound off

    ldx save_a_to_x:#0

    lda sound_on_lo,x
    sta sound_on_ptr
    lda sound_on_hi,x
    sta sound_on_ptr+1

    lda sound_mod_lo,x
    sta modulate_ptr
    lda sound_mod_hi,x
    sta modulate_ptr+1

    lda sound_off_lo,x
    sta sound_off_ptr
    sta sound_off_ptr2

    lda sound_off_hi,x
    sta sound_off_ptr+1
    sta sound_off_ptr2+1

    jmp sound_on_ptr:nil

nil:
    rts

player_gun_off:
    lda #30
    sta SFX_VOICE+1
    lda #$80
    sta SFX_VOICE+4
    rts

player_gun_mod:
    lda freq
    sec
    sbc #4
    sta freq
    sta SFX_VOICE+1
    rts

player_gun:
    lda #GUN_LENGTH
    sta timer

    sound_on(5000, 2048, $02, $38, $41)

    rts

explosion_on:
    lda #EXPLOSION_LENGTH
    sta timer
    sound_on(4000, 0, $13, $48, $81)
    rts

explosion_mod:
    sec
    sbc #1
    sta freq
    sta SFX_VOICE+1
    rts


explosion_off:
    lda #$80
    sta SFX_VOICE + 4
    rts


sound_on:
    .byte 0


sound_on_lo:
     .byte <nil, <player_gun, <explosion_on
sound_on_hi:
     .byte >nil, >player_gun, >explosion_on
sound_off_lo:
    .byte <nil, <player_gun_off, <explosion_off
sound_off_hi:
    .byte >nil, >player_gun_off, >explosion_off
sound_mod_lo:
    .byte <nil, <player_gun_mod, <explosion_mod
sound_mod_hi:
    .byte >nil, >player_gun_mod, >explosion_mod

    .segment DATA

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
