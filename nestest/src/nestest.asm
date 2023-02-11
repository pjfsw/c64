    .const imgwidth=14
    .const imgheight=18
    .var imgfile = LoadBinary("homer.data")

    .var donutfile = LoadBinary("donut.data")


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

.macro store_image(img, width, height, gimpscale) {
    .var width_px = width * 8

    .var c=0
    .for (var ch = 0; ch < width*height; ch++) { // Tile number
        .for (var plane = 0; plane < 2; plane++) { // Bitplane 0 or 1

            .for (var y = 0; y < 8; y++) {  // Row in tile
                .eval c = 0
                .for (var x = 0; x < 8; x++) { // Bit in tile
                    .var imgy = (floor(ch/width) * 8) + y
                    .var imgx = (mod(ch,width) * 8) + x
                    .var pixel = img.uget(((imgy * width_px) + imgx) * gimpscale)
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
    ldx #sprite_data_end-sprite_data-1
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

    lda donutsintable,x
    .for (var y = 0; y < 5; y++) {
        .for (var x = 0; x < 5; x++) {
            sta SPRITEOAM+16+y*(5*4)+x*4
        }
        clc
        adc #8
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
    .byte 0,$23,$12,$33
    .byte 0,$24,$13,$34
    .byte 0,$27,$37,$17

sprite_data:
    .byte $40,$01,$00,$40
    .byte $48,$01,$01,$48
    .byte $50,$01,$02,$40
    .byte $58,$01,$01,$48

    .const donut_x = $18

.macro donutrow(y,tile) {
    .for (var i = 0; i < 5; i++) {
        .byte y,tile+i,$03,donut_x+i*8
    }
}
    // donut
    .for (var i = 0; i < 5; i++) {
        donutrow($20+i*8,2+i*5)
    }
sprite_data_end:

    .const offcenterx=4
    .const offcentery=3

sintable:
    .fill 256,round(44+8*offcentery+32*sin(toRadians(i*360/256)))
costable:
    .fill 256,round(124+8*(1+offcenterx)+80*cos(toRadians(i*360/256)))
donutsintable:
    .fill 256,round(44+8*sin(toRadians(i*360/32)))

background_data:
    .const pad_top = (30-imgheight)/2+offcentery
    .const pad_left = (32-imgwidth)/2+offcenterx
    .const pad_right = 32-imgwidth-pad_left

    .fill 32*pad_top,255
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

    store_image(donutfile, 5, 5, 2)
    .fill 16,$aa
    .fill $1000-(*-chr_rom_start),0

bg_rom:
    store_image(imgfile, imgwidth, imgheight, 2)
    .print (*-bg_rom)/16

    .fill 4096-(*-bg_rom),0


*=$02 "Zeropage" virtual
.zp {
    copy_src_ptr: .word 0
    copy_dst_ptr: .word 0
    row_in_tile: .byte 0
}



