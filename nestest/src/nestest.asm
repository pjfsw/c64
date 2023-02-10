.macro wait_vbl() {
!:
    bit $2002
    bpl !-
}
    .const SPRITEOAM = $0200

    .encoding "ascii"

    *=$0 "Header"
    .text "NES"
    .byte $1a

    .byte $02 // Amount of PRG ROM in 16K units
    .byte $01 // Amount of CHR ROM in 8K units
    .byte $00 // Mapper and mirroring
    .byte $09 // NES 2.0
    .fill 8,0 // TODO Investigate later, 0 for now

    .print *

    *=$0010 "PRG-ROM"
.pseudopc $8000 {
reset:
    sei
    cld

    ldx #$40
    stx $4017   // Disable audio IRQ

    ldx #$00
    stx $4010   // Disable PCM

    ldx #$ff
    txs         // Initialise stack ptr

    // Clear PPU registers
    ldx #$00
    stx $2000
    stx $2001

    // Wait for VBL
    wait_vbl()

    // Clear mem
!:
    lda #0
    .for (var i = 0; i < 8; i++) {
        .if (i != (>SPRITEOAM)) {
            sta i * 256,x
        }
    }
    lda #$ff
    sta SPRITEOAM,x   // sprite data
    inx
    bne !-

    wait_vbl()

    // Transfer 256 bytes to Sprite OAM using DMA
    lda #>SPRITEOAM
    sta $4014

    lda #$3f
    sta $2006 // PPUADDR MSB
    lda #$00
    sta $2006 // PPUADDR LSB

    // Load palette
    ldx #0
!:
    lda palette_data,x
    sta $2007 // PPUDATA
    inx
    cpx #$20
    bne !-

    // Load sprites
    ldx #$0f
!:
    lda sprite_data,x
    sta $0200,x
    dex
    bpl !-

    cli
    lda #%10010000
    sta $2000   // Set NMI on VBLANK

    lda #%00011110
    sta $2001   // Show sprites and background


    jmp *

nmi:
    // Transfer 256 bytes to Sprite OAM using DMA
    lda #>SPRITEOAM
    sta $4014
    rti

irq:
    rti

palette_data:
    .fill 4,$3f
    .fill 16-(*-palette_data),0
    // sprite palette
    .fill 4,$01+i*$10
    .fill 4,$05+i*$10
    .fill 4,$09+i*$10
    .fill 4,$0c+i*$10
sprite_data:
    .byte $3c,$01,$00,$40
    .byte $40,$02,$01,$48
    .byte $48,$03,$02,$40
    .byte $48,$04,$03,$48
}
    *=$800a "VECTORS"
    .word nmi
    .word reset
    .word irq

    *=$8010 "CHR-ROM"
chr_rom_start:
    .fill 16,0
    .for (var i = 0; i < 4; i++) {
        .fill 4,[$0f,$0f]
        .fill 4,[$00,$ff]
    }
    .fill 2048-(*-chr_rom_start),0

*=$02 "Zeropage" virtual
.zp {
    copy_src_ptr: .word 0
    copy_dst_ptr: .word 0
    row_in_tile: .byte 0
}



