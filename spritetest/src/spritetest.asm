.const IRQ_LINE = $f9
.const ANIMATION_SPEED = 40
.const PLAYER_SPEED = 80

BasicUpstart2(programStart)
    *=$080e

programStart:
    sei
    lda #$35    // RAM $0000-$CFFF, IO $D000-$DFFF, RAM $E000-$FFFF
    sta $01

    lda #$7f    // Clear CIA interrupts
    sta $dc0d
    sta $dd0d
    lda $dd0d

    lda #$01
    sta $d01a   // Raster IRQ enable

    lda #$f9   // Raster Y position
    sta $d012

    lda #$1b    // 25 rows
    sta $d011

    lda #$c8    // 40 cols, two color
    sta $d016

    lda #11
    sta $d021

    jsr cls
    jsr init_sprites

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

init_sprites:
    .for (var i = 0; i < 4 ; i++) {
        lda #animationDown/64+i
        sta $07f8+i
        sta $07fc+i
    }
    lda #$ff
    sta $d015
    sta $d027
    sta $d028
    sta $d029
    sta $d02a
    lda #PURPLE
    sta $d02b
    lda #BLACK
    sta $d02c
    lda #WHITE
    sta $d02d
    lda #LIGHT_RED
    sta $d02e
    lda #90
    sta $d008
    sta $d00a
    sta $d00c
    sta $d00e
    lda #100
    sta $d009
    lda #103
    sta $d00b
    sta $d00d
    sta $d00f
    rts

cls:
    ldx #0
    lda #32
!:
    sta $400,x
    sta $500,x
    sta $600,x
    sta $700,x
    dex
    bne !-
    rts

.macro set_irq(irq) {
    lda #<irq
    sta $fffe
    lda #>irq
    sta $ffff
    asl $d019
}

.macro updateMultiplexedRegs() {
    ldx #0
    ldy multiplexOffset
!:
    lda multiplexedSprites,y
    sta $d000,x
    iny
    inx
    cpx #8
    bne !-
    sty multiplexOffset
}

irq: {
    sta save_a
    sta save_x
    sta save_y

    lda #15
    sta $d020
    lda #0
    sta multiplexOffset
    jsr animate
    jsr movePlayer

    updateMultiplexedRegs()

    ldx #1
    stx multiplexPos
    lda multiplexY
    sta $d012

    inc $d020

    set_irq(spriteIrq)
    lda save_a:#0
    ldy save_y:#0
    ldx save_x:#0
    rti
}

spriteIrq: {
    sta save_a
    stx save_x
    sty save_y

    inc $d020

    updateMultiplexedRegs()

    ldx multiplexPos
    lda multiplexY,x
    sta $d012
    lda irqLo,x
    sta $fffe
    lda irqHi,x
    sta $ffff
    inx
    stx multiplexPos
    asl $d019

    lda save_a:#0
    ldx save_x:#0
    ldy save_y:#0
    rti
}

movePlayer:
    lda #0
    ldy moveDown
    beq !+
    lda #PLAYER_SPEED
    ldy #0
!:
    ldy moveUp
    beq !+
    lda #-PLAYER_SPEED
    ldy #$ff
!:
    clc
    adc playerY
    sta playerY

    tya
    adc playerY+1
    sta playerY+1

    lda playerY+1
    sta $d009
    clc
    adc #3
    sta $d00b
    sta $d00d
    sta $d00f

    inc moveCounter
    bne !+
    lda moveUp
    sta moveDown
    eor #1
    sta moveUp
!:
    rts

animate:
    ldy #0
    lda moveUp
    beq !+
    ldy #1
!:
    sty animation

    lda animationTime
    clc
    adc #ANIMATION_SPEED
    sta animationTime
    bcc !+
    inc animationTime+1
!:
    lda animationTime+1
    and #3
    ldx animation
    clc
    adc animationOffsets,x
    tax
    lda animations,x
    tax
    stx $7fc
    inx
    stx $7fd
    inx
    stx $7fe
    inx
    stx $7ff

    rts

nmi:
    rti

multiplexPos:
    .byte 0

.const ZONES = 5
.const ZONE_HEIGHT = 40

multiplexY:
    .fill ZONES, (i+1)*ZONE_HEIGHT+48

irqLo:
    .fill ZONES-1, <spriteIrq
    .byte <irq
irqHi:
    .fill ZONES-1, >spriteIrq
    .byte >irq

multiplexOffset:
    .byte 0

multiplexedSprites:
    .for (var y = 0; y < ZONES; y++) {
        .fill 4, [48+i*64,50+y*ZONE_HEIGHT+i]
    }


// RED = TOP
// BLACK, WHITE, YELLOW = BOTTOM

.const c_red = $ff0000
.const c_white = $ffffff
.const c_yellow = $ffff00
.const c_black = $000000

.var img = LoadPicture("spr24x24x4.png")

.macro load_24x24(spr,xofs,yofs) {
    .var c_list = List().add(c_red, c_black, c_white, c_yellow)
    .var offset = List().add(0, 3, 3, 3)
    .var c = 0

    .for (var i = 0; i < 4; i++) {
        .for (var y = 0; y < 21; y++) {
            .for (var b = 0; b < 3; b++) {
                .var a_byte = 0
                .for (var x = 0; x < 8; x++) {
                    .eval c = spr.getPixel(b*8+x+xofs,y + offset.get(i)+yofs)
                    .if (c == c_list.get(i)) {
                        .eval a_byte = a_byte | (1<<(7-x))
                    }
                }
                .byte a_byte
            }
        }
        .byte 0
    }
}

moveDown:
    .byte 1
moveUp:
    .byte 0
playerY:
    .word $3200
moveCounter:
    .byte 0
animation:
    .byte 0
animationOffsets:
    .fill 4,i*4
animationTime:
    .word 0
animations:
    .fill 4,animationDown/64+4*i
    .fill 4,animationUp/64+4*i

.align $40
* = * "Sprite data"
animationDown:
    .for (var i = 0; i < 4; i++) {
        load_24x24(img,0,i*24)
    }
* = $2000
* = * "Sprite data II "
animationUp:
    .for (var i = 0; i < 4; i++) {
        load_24x24(img,0,(i+4)*24)
    }

