// SPRITE DATA
    .align 64
//hud_sprite:
    .fill 3, %10101010
    .fill 3, %11111111
    .fill 3, %01010101
    .fill 3, %01010101
    .fill 3, %01010101
    .fill 3, %01010101
    .fill 3, %11111111
    .fill 3, %10101010
    .fill 3*13, %11111111
    .byte 0
//player_sprite:
    .for (var i = 0; i < 2; i++) {
         .if (i == 0) {
            .byte %00000001
            .byte %11100000
            .byte %00000000
        } else {
            .byte %00000000
            .byte %00000111
            .byte %10000000
        }
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00010000,%00111100, %00001000
        .byte %11111111,%11111111, %11111111
        .byte %11111111,%11111111, %11111111
        .byte %00111111,%11111111, %11111100
        .byte %00000001,%11111111, %10000000
        .byte %00000000,%00111100, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00111100, %00000000
        .byte %00000000,%01111110, %00000000
        .byte 0,0,0
        .byte 0,0,0
        .byte 0,0,0
        .byte 0
    }
// gun
gun_orig:
    .fill 3*5,0
    .byte %10010100,%00000000,%00101001
    .byte %00111000,%00000000,%00011100
    .byte %10110100,%00000000,%00101101
    .byte %00111000,%00000000,%00011100
    .byte %00010000,%00000000,%00001000
    .fill 64-(*-gun_orig),0
//shadow_sprite:
