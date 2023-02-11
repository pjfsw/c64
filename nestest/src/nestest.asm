    .const imgwidth=14
    .const imgwidth_px = imgwidth * 8
    .const imgheight=18
    .const imgheight_px = imgheight * 8
    .var imgfile = LoadBinary("homer.data")

.macro wait_vbl() {
!:
    bit $2002
    bpl !-
}

.macro ppu_addr(addr) {
    lda $2002   // Reset latch
    lda #>addr
    sta $2006
    lda #<addr
    sta $2006
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
    nop

    ppu_addr($3f00)

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

    wait_vbl()
    // Load nametables
    ppu_addr($2000)
    ldx #0
    .for (var i = 0; i < 4; i++) {
    !:
        lda background_data+i*256,x
        sta $2007
        inx
        bne !-
    }

    // Reset scroll
    lda #$00
    sta $2005
    sta $2005


    cli
    lda #%10010000
    sta $2000   // Set NMI on VBLANK

    lda #%00011110
    sta $2001   // Show sprites and background


    jmp *

nmi:
    ldx sinpos
    inx
    stx sinpos
    clc
    .for (var i = 0; i < 4; i++) {
        lda costable,x
        sta SPRITEOAM+3+i*4
        lda sintable,x
        sta SPRITEOAM+i*4
        txa
        adc #$40
        tax
    }

    // Transfer 256 bytes to Sprite OAM using DMA
    lda #>SPRITEOAM
    sta $4014

    lda #0
    sta $2003 // OAM target memory address

    rti

irq:
    rti

palette_data:
    // background palette
    .fill 4,[0,$18,$38,$3f]
    // sprite palette
    .byte $30 // This sucker overwrites the background in $3f00 so might as well set the bg here
    .byte $25,$14,$35
    .fill 4,$05+i*$10
    .fill 4,$09+i*$10
    .fill 4,$0c+i*$10

sprite_data:
    .byte $40,$01,$00,$40
    .byte $48,$01,$01,$48
    .byte $50,$01,$02,$40
    .byte $58,$01,$03,$48

    .const offcenter=2

sintable:
    .fill 256,round(44+32*sin(toRadians(i*360/256)))
costable:
    .fill 256,round(124+8*offcenter+90*cos(toRadians(i*360/256)))

background_data:
    .fill 32*(30-imgheight)/2,255
    .const pad_left = (32-imgwidth)/2+offcenter
    .const pad_right = 32-imgwidth-pad_left

    .for (var y = 0; y < imgheight; y++) {
        .fill pad_left,255
        .for (var x = 0; x < imgwidth; x++) {
            .byte y*imgwidth+x
        }
        .fill pad_right,255
    }
    .fill 1024-(*-background_data),255
}
    *=$0300 "Variables" virtual
sinpos:
    .byte 0

    *=$800a "VECTORS"
    .word nmi
    .word reset
    .word irq

    *=$8010 "CHR-ROM"
chr_rom_start:
    .fill 16,0

    .byte %01000100
    .byte %11111110
    .byte %11111110
    .byte %11111110
    .byte %11111110
    .byte %01111100
    .byte %00111000
    .byte %00010000

    .byte %01100110
    .byte %10011001
    .byte %10000001
    .byte %10000001
    .byte %10000001
    .byte %01000010
    .byte %00100100
    .byte %00011000

    .byte %

    .for (var i = 1; i < 4; i++) {
        .fill 4,[$0f,$0f]
        .fill 4,[$00,$ff]
    }
    .fill $1000-(*-chr_rom_start),0
bg_rom:
    .const gimpscale=2 // Sometimes gimp adds ff after each pixel :-(
    .var c=0
    .var mask=0
    .for (var ch = 0; ch < imgwidth*imgheight; ch++) { // Tile number
        .for (var plane = 0; plane < 2; plane++) { // Bitplane 0 or 1

            .for (var y = 0; y < 8; y++) {  // Row in tile
                .eval c = 0
                .for (var x = 0; x < 8; x++) { // Bit in tile
                    .var imgy = (floor(ch/imgwidth) * 8) + y
                    .var imgx = (mod(ch,imgwidth) * 8) + x
                    .var pixel = imgfile.uget(((imgy * imgwidth_px) + imgx) * gimpscale)
                    .var bpldata = pixel & (1 << (1-plane))
                    .eval c = c*2
                    .if (bpldata == 0) {
                        .eval c = (c | 1)
                    }
                }
                .byte c
            }
        }
    }
    .fill 4096-(*-bg_rom),0


*=$02 "Zeropage" virtual
.zp {
    copy_src_ptr: .word 0
    copy_dst_ptr: .word 0
    row_in_tile: .byte 0
}



