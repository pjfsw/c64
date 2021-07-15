.label bottomPos = $fe
.const SCREEN = $0400
.const SPRITEPTR = SCREEN+$03f8

BasicUpstart2(programStart)
    *=$080e

programStart:
    lda #0
    sta $d020
    sta $d021
    jsr initMemory
    jsr initSpriteData
    sei
    lda #<bottom_irq
    sta $fffe
    lda #>bottom_irq
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
    lda #sprite/64
    ldx #7
!:
    sta SPRITEPTR,x
    dex
    bpl !-

    lda #255
    sta $d015

    lda #YELLOW
    sta $d027

    lda #$ff   // double width & height
    sta $d01d
    sta $d017

    rts

bottom_irq: {
    sta a_temp
    stx x_temp
    sty y_temp


    sec
    lda irqPos
    sbc #40
    .for (var i = 0; i < 8; i++) {
        sta $d001 + i*2
    }

    ldy #0
    .for (var i = 0; i < 8; i++) {
        ldx spriteX + i
        dex
        cpx #$FF
        bne !+
        ldx #191
    !:
        stx spriteX + i
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

/*    lda #$f7
    sta $d00e
    lda #100
    sta $d00f*/


    lda irqPos
    sta $d012
    lda #<irq
    sta $fffe
    lda #>irq
    sta $ffff

    asl $d019
    lda a_temp:#0
    ldx x_temp:#0
    ldy y_temp:#0
    rti
}

.macro nopc(count) {
    .for (var i = 0; i < count; i++) {
      nop
    }
}

irq: {
    sta a_temp
    stx x_temp
    sty y_temp

    lda #BLUE
    sta $d021

    ldx barPos
    inc barPos
    lda barTable,x    // Raster Y position
    sta irqPos
    nopc(16)

    lda #LIGHT_BLUE
    sta $d021
    nopc(60)

    lda #WHITE
    sta $d021
    nopc(64)

    lda #LIGHT_BLUE
    sta $d021
    nopc(64)

    lda #BLUE
    sta $d021
    nopc(64)

    lda #0
    sta $d021

    lda #bottomPos    // Raster Y position
    sta $d012
    lda #<bottom_irq
    sta $fffe
    lda #>bottom_irq
    sta $ffff

    asl $d019
    lda a_temp:#0
    ldx x_temp:#0
    ldy y_temp:#0
    rti
}

barTable:
    .fill 256, 244+150*sin((64+mod(i,64))*PI/64)
barPos:
    .byte 0
irqPos:
    .byte 0

    .align 64
sprite:
    .fill 64,i
spriteX:
    .fill 8,<i*24
spriteXLo:
    .fill 192, (i < 12 ? i*2 + $e0 : <(i*2-24))
spriteXHi:
    .fill 192, (i < 12 ? 1 : >(i*2-24))
spriteHiMask:
    .fill 8,1<<i