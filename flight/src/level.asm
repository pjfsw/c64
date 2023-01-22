#importonce

// LEVEL DATA. 4x4 tiles = 10 tiles per row
tiledata:
  .fill 16,$20

  .byte $20,$66,$66,$20
  .byte $66,$dc,$a0,$5c
  .byte $66,$a0,$a0,$5c
  .byte $20,$68,$68,$20

  .fill 16,$20
  .fill 16,$20

  .fill 4,[$a0,$5c,$20,$20]
  .fill 4,[$a0,$66,$20,$20]
  .fill 4,[$20,$20,$66,$a0]
  .fill 4,[$20,$66,$a0,$a0]

  .byte $4a,$40,$40,$4b
  .byte $42,$20,$20,$42
  .byte $42,$20,$20,$42
  .byte $55,$40,$40,$49

  .byte $6d,$40,$40,$7d
  .byte $42,$20,$20,$42
  .byte $42,$20,$20,$42
  .byte $70,$40,$40,$6e

  .byte $20,$20,$20,$5f
  .byte $20,$20,$5f,$a0
  .byte $20,$5f,$a0,$a0
  .byte $5f,$a0,$a0,$a0
tiledata_manual_end:
 .fill 256-(tiledata_manual_end-tiledata),i/16
tile_no_to_tile_offset: .fill 16,i*16

levelmap:
    .for (var n = 0; n < MAP_LENGTH; n++) {
        .byte 4+(n&1) // left Shore
        .for (var n = 1; n < 9; n++) {
            .var r = floor(8 * random())
            .if (r == 0) {
                .byte $1
            } else {
                .byte $0
            }
        }
        .byte 6+(n&1)
    }
