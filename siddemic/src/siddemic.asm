.var music = LoadSid("siddemic_house.sid")
.var dj = LoadPicture("dj.png", List().add($ffffff,$000000))
.var djgear = LoadPicture("djgear.png", List().add($ffffff, $000000))

.const SCREEN = $400
.const SPRITEPTR = SCREEN+$3f8


BasicUpstart2(programStart)
    *=$080e

programStart:
    lda #0
    sta $d020
    lda #11
    sta $d021
    sei
    jsr initMemory
    lda #0
    jsr music.init
    jsr spriteOn
    lda #<irq
    sta $fffe
    lda #>irq
    sta $ffff
    cli
    jmp *

spriteOn:
    ldx #11
!:
    lda spritePos,x
    sta $d000,x
    dex
    bpl !-

    lda #0
    sta $d010
    sta $d017
    sta $d01c
    sta $d01d

    lda #0
    ldx #5
!:
    sta $d027,x
    dex
    bpl !-

    ldx #spriteData/64
    stx SPRITEPTR
    inx
    stx SPRITEPTR+1
    inx
    stx SPRITEPTR+2
    inx
    stx SPRITEPTR+3
    ldx #boothSpriteData/64
    stx SPRITEPTR+4
    inx
    stx SPRITEPTR+5

    lda #$3f
    sta $d015

    rts
initMemory:
    sei

    lda #$35    // RAM $0000-$CFFF, IO $D000-$DFFF, RAM $E000-$FFFF
    sta $01

    lda #$7f    // Clear CIA interrupts
    sta $dc0d
    sta $dd0d
    lda $dc0d   // Clear pending interrupts by reading it
    lda $dd0d

    lda #$01
    sta $d01a   // Raster IRQ enable

    lda #$fe // Raster Y position
    sta $d012

    lda #$1b    // 25 rows
    sta $d011

    lda #$c8    // 40 cols, two color
    sta $d016

    lda #<SCREEN
    sta screen_ptr
    lda #>SCREEN
    sta screen_ptr+1

    ldx #0
!:
    {
        lda row_characters,x
        ldy #39
    !:
        sta (screen_ptr),y
        dey
        bpl !-

        clc
        lda screen_ptr
        adc #40
        sta screen_ptr
        bcc !+
        inc screen_ptr+1
    !:
    }
    inx
    cpx #25
    bne !-

    ldx #0
    lda #0
!:
    sta $d800,x
    sta $d900,x
    sta $da00,x
    sta $db00,x
    dex
    bne !-

    rts


irq: {
    sta a_temp
    stx x_temp
    sty y_temp

    jsr music.play

    dec anim_frame
    bne !+
    lda anim
    and #1
    eor #1
    sta anim
    tay
    lda anim_offset,y
    clc
    ldx #0
    {
    !:
        sta SPRITEPTR,x
        adc #1
        inx
        cpx #4
        bne !-
    }
    lda #12
    sta anim_frame
!:
    ldx lighting_frame
    dex
    bne !+
    ldx #48
!:
    stx lighting_frame
    lda background_color,x
    sta $d021

    asl $d019
    lda a_temp:#0
    ldx x_temp:#0
    ldy y_temp:#0
    rti
}

spritePos:
    .const baseX = 160
    .const baseY = 106
    .byte baseX, baseY, baseX+24, baseY
    .byte baseX, baseY+21, baseX+24, baseY+21
    .byte baseX-8, baseY+27, baseX+24-8, baseY+27

lighting_frame:
    .byte 3
anim_frame:
    .byte 1
anim:
    .byte 1
anim_offset:
    .byte spriteData/64, (spriteData/64)+4
background_color:
    .byte $1,$0,$0,$0,$0,$0
    .byte $b,$b,$b,$b,$b,$b
    .byte $b,$b,$b,$b,$b,$b
    .byte $b,$b,$6,$6,$e,$e

    .byte $f,$0,$0,$0,$0,$0
    .byte $b,$b,$b,$b,$b,$b
    .byte $b,$b,$b,$b,$b,$b
    .byte $c,$c,$5,$f,$f,$f

row_characters:
    .fill 6,128+32
    .fill 7,32
    .fill 12,128+32

*=music.location "Music"
    .fill music.size, music.getData(i)


.align $40
spriteData:
    .for (var i = 0; i < 8; i++) {
        .for (var y = 0; y < 21; y++) {
            .for (var x = 0; x < 3; x++) {
                .byte dj.getSinglecolorByte((i&1)*3+x, (i>>1)*21+y)
            }
        }
        .byte 0
    }
boothSpriteData:
    .for (var i = 0; i < 2; i++) {
        .for (var y = 0; y < 21; y++) {
            .for (var x = 0; x < 3; x++) {
                .byte djgear.getSinglecolorByte(i*3+x, y);
            }
        }
        .byte 0
    }

*=$02 "Zeropage" virtual
.zp {
screen_ptr:
    .word 0
}