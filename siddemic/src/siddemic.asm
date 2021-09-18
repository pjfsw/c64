.var music = LoadSid("siddemic_house.sid")
.var dj = LoadPicture("dj.png", List().add($ffffff,$000000))
.var djgear = LoadPicture("djgear.png", List().add($ffffff, $000000))
.var pjfsw = LoadPicture("pjfsw.png", List().add($ffffff, $000000));
.var siddemic = LoadPicture("siddemic.png", List().add($ffffff, $000000));
.var house = LoadPicture("house.png", List().add($ffffff, $000000));

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
    lda #0
    sta $d01c
    sta $d010
    lda #$c0
    sta $d01d
    sta $d017

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
    ldx #pjfswSpriteData/64
    stx SPRITEPTR+6
    inx
    stx SPRITEPTR+7

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


irq:
    sta a_temp
    stx x_temp
    sty y_temp

    jsr music.play
    jsr active_sequence:scene_intro

    dec anim_frame
    bne !+
    lda anim
    and #1
    eor #1
    sta anim
    lda #12
    sta anim_frame
!:
    ldx lighting_frame
    dex
    bne !+
    inc scene_frame
    ldx scene_frame
    lda scene_table_lo,x
    sta active_sequence
    lda scene_table_hi,x
    sta active_sequence+1

    ldx #48
!:
    stx lighting_frame

    asl $d019
    lda a_temp:#0
    ldx x_temp:#0
    ldy y_temp:#0
    rti

.const message_row = 12
scene_intro:
    rts

scene_dj:
    lda #0
    ldx #5
!:
    sta $d027,x
    dex
    bpl !-

    ldy anim
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

    ldx #11
!:
    lda spritePos,x
    sta $d000,x
    dex
    bpl !-

    ldx lighting_frame
    lda background_color,x
    sta $d021

    lda #$3f
    sta $d015
    rts

scene_pjfsw:
    ldx sinpos
    inx
    stx sinpos
    lda sintable,x
    sta $d00c
    clc
    adc #48
    sta $d00e
    lda #$50
    sta $d00d
    sta $d00f
    lda #0
    sta $d021
    ldx lighting_frame
    lda background_color,x
    sta $d02d
    sta $d02e
    lda #$c0
    sta $d015
    rts

scene_siddemic:
    ldx #siddemicSpriteData/64
    stx SPRITEPTR
    inx
    stx SPRITEPTR+1
    inx
    stx SPRITEPTR+2
    inx
    stx SPRITEPTR+3
    lda #6
    sta $d027
    sta $d028
    sta $d029
    sta $d02a
.const siddemic_x = 136
    lda #100
    sta $d001
    sta $d003
    sta $d005
    sta $d007
    lda #siddemic_x
    sta $d000
    lda #siddemic_x+24
    sta $d002
    lda #siddemic_x+48
    sta $d004
    lda #siddemic_x+72
    sta $d006
    lda #$0f
    sta $d015
    rts

scene_house:
    ldx #houseSpriteData/64
    stx SPRITEPTR
    inx
    stx SPRITEPTR+1
    inx
    stx SPRITEPTR+2
    inx
    stx SPRITEPTR+3
    lda #4
    sta $d027
    sta $d028
    sta $d029
    sta $d02a
.const house_x = 144
    lda #100
    sta $d001
    sta $d003
    lda #121
    sta $d005
    sta $d007
    lda #house_x
    sta $d000
    sta $d004
    lda #house_x+24
    sta $d002
    sta $d006
    lda #$0f
    sta $d015
    rts

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

scene_frame:
    .byte 0

.function scenetable(x) {
    .if (x < 17) {
        .return scene_intro
    }

    .if (((x-1)&$e) == $c) {
        .return scene_pjfsw
    } else .if (((x-1)&$f) == $e) {
        .return scene_siddemic
    } else .if (((x-1)&$f) == $f) {
        .return scene_house
    } else {
        .return scene_dj
    }
}

scene_table_lo:
    .fill 256,<scenetable(i)
scene_table_hi:
    .fill 256,>scenetable(i)

sinpos:
    .byte 0
sintable:
    .fill 256,130+32*sin(i*PI/32)

*=music.location "Music"
    .fill music.size, music.getData(i)

.macro fill_sprite(img, w, yofs) {
    .for (var i = 0; i < w; i++) {
        .for (var y = 0; y < 21; y++) {
            .for (var x = 0; x < 3; x++) {
                .byte img.getSinglecolorByte(i*3+x, (yofs*21)+y);
            }
        }
        .byte 0
    }
}

.align $40
spriteData:
    .for (var i = 0; i < 4; i++) {
        fill_sprite(dj, 2, i);
    }


boothSpriteData:
    fill_sprite(djgear, 2, 0)

pjfswSpriteData:
    fill_sprite(pjfsw, 2, 0)

siddemicSpriteData:
    fill_sprite(siddemic, 4, 0)

houseSpriteData:
    fill_sprite(house, 2, 0)
    fill_sprite(house, 2, 1)

*=$02 "Zeropage" virtual
.zp {
screen_ptr:
    .word 0
}