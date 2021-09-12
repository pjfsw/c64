.label bottomPos = $fe
.const SCREEN = $0400
.const SPRITEPTR = SCREEN+$03f8

.var music = LoadSid("testo.sid")


BasicUpstart2(programStart)
    *=$080e

programStart:
    lda #0
    sta $d020
    sta $d021
    jsr initMemory
    jsr initSpriteData
    sei
    lda #0
    jsr music.init
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
    lda $dc0d   // Clear pending interrupts by reading it
    lda $dd0d

    lda #$01
    sta $d01a   // Raster IRQ enable

    lda #bottomPos // Raster Y position
    sta $d012

    lda #$1b    // 25 rows
    sta $d011

    lda #$c8    // 40 cols, two color
    sta $d016

    lda #32
    ldx #0
!:
    sta SCREEN,x
    sta SCREEN+$100,x
    sta SCREEN+$200,x
    sta SCREEN+$300,x
    inx
    bne !-

    rts

initSpriteData:
    ldx #0
!:
    lda letters,x
    sta SPRITEPTR,x
    inx
    cpx #8
    bne !-

    lda #255
    sta $d015

    lda #YELLOW
    sta $d027

    lda #$00   // double width & height
    sta $d01d
    sta $d017

    rts

irq:
    sta a_temp
    stx x_temp
    sty y_temp

//    lda #1
//    sta $d020
    jsr currentScene:sceneWelcome

    inc frame
    bne !+
    inc frame+1
!:
//    lda #0
//    sta $d020
    asl $d019
    lda a_temp:#0
    ldx x_temp:#0
    ldy y_temp:#0
    rti

.macro nextScene(nextFrame, nextScene) {
    lda #<nextFrame
    cmp frame
    bne !+
    lda #>nextFrame
    cmp frame+1
    bne !+
    lda #<nextScene
    sta currentScene
    lda #>nextScene
    sta currentScene+1
!:
}

.const SCENE_WELCOME_FADE_FRAME = 383
.const SCENE_TESTO_FRAME = 386
.const SCENE_GOODBYE_FRAME = 5810
.const SCENE_NOP_FRAME = 7000


sceneWelcome:
    lda #$0
    sta $d021
    ldx messageCount+1
    ldx messageCount+1
    lda messageLo,x
    sta messagePlaceHolder
    lda messageHi,x
    sta messagePlaceHolder+1

    lda messageCount
    lsr
    lsr
    lsr
    tax
    lda messageColor,x
    tay
    ldx #messageLength-1
!:
    lda messagePlaceHolder:$400,x
    .const textY = 10
    .const textX = 5
    sta $400+textY*40+textX,x
    tya
    sta $d800+textY*40+textX,x
    dex
    bpl !-

    lda messageCount
    clc
    adc #1
    cmp #193
    bne !+
    inc messageCount+1
    lda #0
!:
    sta messageCount

    nextScene(SCENE_WELCOME_FADE_FRAME, sceneWelcomeFade)
    rts

sceneWelcomeFade:
    ldx #messageLength-1
    lda #0
!:
    sta $d800+textY*40+textX,x
    dex
    bpl !-

    nextScene(SCENE_TESTO_FRAME, sceneTesto)
    rts

sceneTesto:
    jsr music.play
    sec
    ldx barPos
    inx
    stx barPos
    txa
    and #63
    tax
    lda sinTable,x
    ldy #14
!:
    sta $d001,y
    dey
    dey
    bpl !-

    lda cosTable,x
    clc
    .for (var i = 0; i < 8; i++) {
        sta spriteX+i
        adc #25
    }

    ldy #0
    .for (var i = 0; i < 8; i++) {

        ldx spriteX + i
        lda spriteXLo,x
        sta $d000 + i * 2
        lda spriteXHi,x
        beq !+
        tya
        ora spriteHiMask + i
        tay
    !:
    }
    tya
    sta $d010
    lda spriteColorDelay
    clc
    adc #1
.const spriteColorSpeed = 12
    cmp #spriteColorSpeed
    bne !+
    lda spriteColorPos
    clc
    adc #1
    and #3
    sta spriteColorPos
    lda #0
!:
    sta spriteColorDelay
    ldx spriteColorPos
    lda spriteColor,x
    ldx #7
!:
    sta $d027,x
    dex
    bpl !-


    nextScene(SCENE_GOODBYE_FRAME, sceneGoodbye)

    rts


sceneGoodbye:
    jsr music.play

    .for (var i = 0; i < 8; i++) {
        lda $d001+i*2
        beq !+
        clc
        adc #1
        sta $d001+i*2
    !:
    }
    nextScene(SCENE_NOP_FRAME, sceneNop)
    rts

sceneNop:
    jsr music.play
    rts


frame:
    .word 0
sinTable:
    .fill 64, 128+30*sin(i*PI/32)
cosTable:
    .fill 64, 40+40*cos(i*PI/32)
barPos:
    .byte 0

messageColor:
    .byte 0,11,12,15,1,1
    .byte 1,1,1,1,1,1
    .byte 1,1,1,1,1,1
    .byte 1,1,15,12,11,0

messageCount:
    .byte 0,0
messageLo:
    .byte <message1, <message2
messageHi:
    .byte >message1, >message2

.encoding "screencode_upper"
message1:
    .text "PJFSW/JOHAN FRANSSON PRESENTS"
message2:
    .text "  A TERRIBLE CODING ATTEMPT  "
.label messageLength=*-message2

letters:
    .byte spritePtr,spritePtr+1,spritePtr+2,spritePtr,spritePtr+3,spritePtr+4,spritePtr+4,spritePtr+4
    .align 64
.label spritePtr = sprite/64
sprite:
    #import "alphabet.asm"
spriteX:
    .fill 9,30+<i*16
spriteXLo:
    .fill 256,<(i+50)
spriteXHi:
    .fill 256,>(i+50)
spriteHiMask:
    .fill 8,1<<i
spriteColorDelay:
    .byte spriteColorSpeed-5
spriteColorPos:
    .byte 0
spriteColor:
    .byte 4,13,11,0

*=music.location "Music"
    .fill music.size, music.getData(i)
