// SPRITE DATA
    .align 64
//hud_sprite:
    .fill 64,255
//player_sprite:
    .for (var i = 0; i < 2; i++) {
        .byte %00000000
         .if (i == 0) {
            .byte %11111000
        } else {
            .byte %00011111
        }
        .byte %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00111100, %00000000
        .byte %01111111,%11111111, %11111110
        .byte %11111111,%11111111, %11111111
        .byte %01111111,%11111111, %11111110
        .byte %00011111,%11111111, %11111000
        .byte %00000000,%00111100, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00111100, %00000000
        .byte %00000000,%01111110, %00000000
        .byte 0
    }
//shadow_sprite: