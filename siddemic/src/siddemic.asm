.var music = LoadSid("siddemic_house.sid")
.const PAL = List().add($ffffff,$000000)

.var dj = LoadPicture("dj.png", PAL)
.var djgear = LoadPicture("djgear.png", PAL)
.var pjfsw = LoadPicture("pjfsw.png", PAL)
.var siddemic = LoadPicture("siddemic.png", PAL)
.var house = LoadPicture("house.png", PAL);
.var syringe = LoadPicture("syringe.png", PAL)
.var cv = LoadPicture("cv.png", PAL)
.var walk = LoadPicture("walk.png", PAL)
.var face = LoadPicture("face.png", PAL)
.var flying = LoadPicture("flying.png", PAL)

.const SCREEN = $400
.const SPRITEPTR = SCREEN+$3f8

.const IRQ1_LINE = $63
.const IRQ2_LINE = $89
.const IRQ_LINE = $f9

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
    lda #0
    sta $d01c
    lda #<nmi
    sta $fffa
    lda #>nmi
    sta $fffb
    lda #<irq
    sta $fffe
    lda #>irq
    sta $ffff
    cli
    jmp *

initMemory:
    sei

    lda #$35    // RAM $0000-$CFFF, IO $D000-$DFFF, RAM $E000-$FFFF
    sta $01

    lda #$7f    // Clear CIA interrupts
    sta $dc0d
    sta $dd0d
    lda $dd0d

    lda #$01
    sta $d01a   // Raster IRQ enable

    lda #IRQ_LINE // Raster Y position
    sta $d012

    lda #$1b    // 25 rows
    sta $d011

    lda #$c8    // 40 cols, two color
    sta $d016

    ldx #0
    lda #128+32
!:
    sta SCREEN,x
    sta SCREEN+$100,x
    sta SCREEN+$200,x
    sta SCREEN+$300,x
    dex
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

    lda #0
    sta $d010

    jsr active_sequence:scene_intro

    ldx scene_ptr
    lda scene_index,x
    beq !+  // Final scene, don't change anything
    dec scene_frame
    bne !+

    inc scene_ptr
    ldx scene_ptr
    lda scene_duration,x
    sta scene_frame
    lda scene_index,x
    tax
    lda scene_table_lo,x
    sta active_sequence
    lda scene_table_hi,x
    sta active_sequence+1
!:

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

    ldx #48
!:
    stx lighting_frame

    asl $d019

    lda a_temp:#0
    ldx x_temp:#0
    ldy y_temp:#0
    rti

scene_end:
    lda #0
    sta $d015
    sta $d021
    rts

.function getRow(row) {
    .return SCREEN+row*40
}

.const row = 6
fillscreen_lo:
    .fill 7, <getRow(row+i)
fillscreen_hi:
    .fill 7, >getRow(row+i)
fillscreen_pos:
    .byte 7

scene_fillscreen:
    lda #0
    sta $d015
    lda #11
    sta $d021
    ldy fillscreen_pos
    bne !+
    rts
!:
    dey
    sty fillscreen_pos
    lda fillscreen_lo,y
    sta screen_ptr
    lda fillscreen_hi,y
    sta screen_ptr+1
    ldy #39
    lda #32
!:
    sta (screen_ptr),y
    dey
    bpl !-

    rts

.var msg0 = "                                "
.var msg1 = "        PJFSW PRESENTS          "
.var msg2 = "MUSIC AND CODE BY JOHAN FRANSSON"
.const message_row = 12
    .encoding "screencode_upper"
message0:
    .fill msg0.size(), msg0.charAt(i)+128
message1:
    .fill msg1.size(), msg1.charAt(i)+128
message2:
    .fill msg2.size(), msg2.charAt(i)+128

msg_ptr:
    .byte 0
message_table_lo:
    .byte <message0, <message1, <message2, <message0
message_table_hi:
    .byte >message0, >message1, >message2, >message0

msg_color_ptr:
    .byte 0
msg_color_table:
    .byte 0,9,8,7
    .fill 40,1
    .byte 15,12,11,0

scene_intro:
    lda msg_color_ptr
    lsr
    lsr
    tax
    lda msg_color_table,x
    sta $d021
    ldx msg_color_ptr
    inx
    cpx #192
    bne !+

    ldy msg_ptr
    iny
    tya
    and #3
    sta msg_ptr
    ldx #0
!:
    stx msg_color_ptr

    lda #0
    sta $d015

    ldx msg_ptr
    lda message_table_lo,x
    sta screen_ptr
    lda message_table_hi,x
    sta screen_ptr+1
    ldy #msg1.size()-1
!:
    lda (screen_ptr),y
    sta $0400+40*message_row+(40-msg1.size())/2,y
    dey
    bpl !-

    rts

scene_dj:
    ldx #boothSpriteData/64
    stx SPRITEPTR+4
    inx
    stx SPRITEPTR+5

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
    ldx #pjfswSpriteData/64
    stx SPRITEPTR+6
    inx
    stx SPRITEPTR+7

    ldx sinpos
    inx
    stx sinpos
    lda sintable,x
    sta $d00c
    clc
    adc #48
    sta $d00e
    lda #$60
    sta $d00d
    sta $d00f
    lda #0
    sta $d021
    ldx lighting_frame
    lda background_color,x
    sta $d02d
    sta $d02e
    lda #$c0
    sta $d01d
    sta $d017

    lda #$c0
    sta $d015
    rts

scene_siddemic:
    lda #0
    sta $d021

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
    lda #0
    sta $d021

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
.const house_x = 164
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

scene_syringe:
    ldx #syringeSpriteData/64
    stx SPRITEPTR
    lda #15
    sta $d027
    lda #172-16
    sta $d000
    lda #100
    sta $d001
    lda #0
    sta $d021
    lda #1
    sta $d015
    rts

scene_cv:
    ldx #cvSpriteData/64
    stx SPRITEPTR
    lda #7
    sta $d027
    lda #172+16
    sta $d000
    lda #100
    sta $d001
    lda #0
    sta $d021
    lda #1
    sta $d015
    rts

.const walkSpeed=8
walkOffset:
    .byte 0
walkFrame:
    .byte walkSpeed-2
walkPos:
    .word $0400

scene_walk:
    ldx walkPos+1
    lda walkBackgroundTable,x
    sta $d021
    ldx #houseSpriteData/64
    stx SPRITEPTR+1
    inx
    stx SPRITEPTR+2
    inx
    stx SPRITEPTR+3
    inx
    stx SPRITEPTR+4

    lda #walkSpriteData/64
    clc
    adc walkOffset
    sta SPRITEPTR
    ldx walkFrame
    dex
    bne !+
    {
        ldx walkOffset
        inx
        cpx #3
        bne !+
        ldx #0
    !:
        stx walkOffset
        ldx #walkSpeed
    }
!:
    stx walkFrame
    lda #0
    sta $d027
    sta $d028
    sta $d029
    sta $d02a
    sta $d02b
    lda #$1e
    ldx walkPos+1
    bpl !+
    ora #$01
!:
    sta $d010
    txa
    asl
    sta $d000
    lda walkPos
    rol
    rol
    and #1
    ora $d000
    sta $d000
    lda walkPos
    clc
    adc #42
    sta walkPos
    bcc !+
    inc walkPos+1
!:
    lda #133
    sta $d001
.const housexpos2 = 40
.const houseypos2 = 118
    lda #housexpos2
    sta $d002
    sta $d006
    lda #housexpos2+24
    sta $d004
    sta $d008
    lda #houseypos2
    sta $d003
    sta $d005
    lda #houseypos2+21
    sta $d007
    sta $d009
    lda #$1f
    sta $d015
    rts

stareColorPtr:
    .word 0
scene_stare:
    .for (var i = 0; i < 6; i++) {
        ldx #(faceSpriteData/64)+i
        stx SPRITEPTR+i
    }
    ldx #faceSpriteData/64+7
    stx SPRITEPTR+6

    lda #0
    sta $d017
    sta $d01d

    ldx stareColorPtr+1
    lda stareBackgroundTable,x
    sta $d021
    lda stareColorPtr
    clc
    adc #$80
    sta stareColorPtr
    bcc !+
    inc stareColorPtr+1
!:
    lda #0
    sta $d027
    sta $d028
    sta $d029
    sta $d02a
    sta $d02b
    sta $d02c
    sta $d02d
.const facex = 148
.const facey = 100
    lda #facex
    sta $d000
    sta $d006
    lda #facex+24
    sta $d002
    sta $d008
    sta $d00c
    lda #facex+48
    sta $d004
    sta $d00a
    lda #facey
    sta $d001
    sta $d003
    sta $d005
    lda #facey+21
    sta $d007
    sta $d009
    sta $d00b
    lda #facey+42
    sta $d00d
    lda #$7f
    sta $d015

    rts

scene_flying:
    lda flying_anim+1
    and #3
    clc
    adc #flyingSpriteData/64
    sta SPRITEPTR
    lda flying_x+1
    bpl !+
    ldx #1
    stx $d010
!:
    asl
    sta $d000
    lda flying_x
    rol
    rol
    and #1
    ora $d000
    sta $d000

    lda #100
    sta $d001
    lda #4
    sta $d021
    lda #0
    sta $d027

    clc
    lda flying_x
    adc #$1c
    sta flying_x
    bcc !+
    inc flying_x+1
!:

    clc
    lda flying_anim
    adc #$30
    sta flying_anim
    bcc !+
    inc flying_anim+1
!:

    lda #$01
    sta $d015

    rts

nmi:
    rti

flying_x:
    .word 0
flying_anim:
    .word 0

spritePos:
    .const baseX = 160
    .const baseY = 106
    .byte baseX, baseY, baseX+24, baseY
    .byte baseX, baseY+21, baseX+24, baseY+21
    .byte baseX-8, baseY+27, baseX+24-8, baseY+27

lighting_frame:
    .byte 6
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

scene_frame:
    .byte 191
scene_ptr:
    .byte 0
.const HP = 192
.const QP = 96
.const BT = 12

scene_index:
    .byte 1,1,1,1,3,4,6
    .fill 11, [5,5,2,3,4]
    .byte 5
    .fill 12, [3,4]
    .fill 4, 10 // BREAK
    .fill 2, 11 // Stare
    .fill 3, 5  // BREAK
    .fill 1, 5 // BREAK
    .fill 4, [3,4]
    .fill 4, [7,8] // propaganda 2
    .fill 15, [3,9] // buildup1
    .fill 1, [4]   // buildup2

    // BLIRPA
    .fill 4, [3,4,5,3,4,2,5]

    .fill 8, 5
    .fill 8, 12
    .byte 0
scene_duration:
    .byte HP,HP,HP,HP-8*BT,4*BT, 3*BT, BT
    .fill 11, [HP, HP - 8*BT,4*BT,2*BT, 2*BT]
    .byte HP
    .fill 4, [BT, BT]
    .fill 8, [BT/2, BT/2]
    .fill 9, HP // BREAK
    .fill 1, QP
    .fill 4, [BT/2, BT/2]
    .fill 4, [BT/2,BT/2] // propaganda 2
    .fill 15, [BT/4, BT/4] // buildup1
    .fill 1, [BT]    // buildup2

    // BLIRPA
    .fill 4, [BT/2, BT/2, BT/2, BT/2, 2*BT, 4*BT, QP]

    .fill 8, HP
    .fill 8, HP
    .byte 0
.print "Scene table length" + (*-scene_duration)

scene_table_lo:
    .byte <scene_end, <scene_intro, <scene_pjfsw, <scene_siddemic, <scene_house, <scene_dj, <scene_fillscreen
    .byte <scene_syringe, <scene_cv, <scene_end, <scene_walk, <scene_stare, <scene_flying
scene_table_hi:
    .byte >scene_end, >scene_intro, >scene_pjfsw, >scene_siddemic, >scene_house, >scene_dj, >scene_fillscreen
    .byte >scene_syringe, >scene_cv, >scene_end, >scene_walk, >scene_stare, >scene_flying

*=music.location "Music"
    .fill music.size, music.getData(i)

sinpos:
    .byte 0
sintable:
    .fill 256,130+32*sin(i*PI/32)


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
* = * "Sprite data"
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
syringeSpriteData:
    fill_sprite(syringe, 1, 0)
cvSpriteData:
    fill_sprite(cv, 1, 0)
walkSpriteData:
    fill_sprite(walk, 3, 0)
faceSpriteData:
    fill_sprite(face, 3, 0)
    fill_sprite(face, 3, 1)
    fill_sprite(face, 2, 2)
flyingSpriteData:
    fill_sprite(flying, 4, 0)

.print "End of sprites at " + *
walkBackgroundTable:
    .byte 0,0,0,0,0,$0,$b,$9
    .fill 118,$c
    .byte 4,2,9
    .fill 20,0
    // 3 e 4 b 6
stareBackgroundTable:
    .byte 0,$6,$b,$4,$c
    .for (var i = 0; i < 7; i++) {
        .fill 8,$3
        .byte $e,4,$b
        .fill 9,$6
        .byte $b,$4,$e,$3
    }
    .for (var i = 0; i < 3; i++) {
        .byte 6,6
        .byte 3,3
    }
    .byte 4,$c,$3,$d
    .fill 16,1

*=$02 "Zeropage" virtual
.zp {
screen_ptr:
    .word 0
}