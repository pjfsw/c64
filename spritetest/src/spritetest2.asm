.const SCREEN = $4000
.const SCREEN2 = $4400
.const FONT = $7800
.const SPRITEDATA = $7c00
.const DIVISIONS = 30

BasicUpstart2(programStart)
    *=$080e

programStart:
    sei
    jsr clearScreen
    jsr initSprites
    jsr initIrq
    cli
    jmp *

irq:
    sta save_a
    stx save_x
    sty save_y


    lda #12
    sta $d020

    ldx irqPos
    lda d018,x
    sta $d018
    inx
    cpx #DIVISIONS
    bne !+
    ldx #0
!:
    stx irqPos
    lda irqRows,x  // Raster Y position
    sta $d012

    lda irqRows,x
    .for (var i = 0; i < 8; i++) {
        sta $d001 + i*2
    }

    lda xpos,x
    tay
    iny
    lda costable,y
    clc
    .for (var i = 0; i < 8; i++) {
        sta $d000 + i*2
        adc #24
    }
    tya
    sta xpos,x

    lda #0
    sta $d020

    lda #$ff   // this is the orthodox and safe way of clearing the interrupt condition of the VICII.
    sta $d019

    lda save_a:#0
    ldy save_y:#0
    ldx save_x:#0
    rti


clearScreen:
    lda #0
    sta $d020
    sta $d021

    lda #0
    ldx #0
!:
    .for (var i = 0; i < 8; i++) {
        sta FONT+i*256,x
    }
    dex
    bne !-

    lda $DD00
    and #%11111100
    ora #%00000010  //<- vic bank $4000-$7fff
    sta $DD00
    ldx #0
    lda #0
!:
    .for (var i = 0; i < 4; i++) {
        sta SCREEN+i*256,x
        sta SCREEN2+i*256,x
    }
    dex
    bne !-
    rts

initSprites:
    // enable all sprites
    lda #$ff
    sta $d015

    // copy sprites to bank
    ldx #127
!:
    lda spriteData,x
    sta SPRITEDATA,x
    dex
    bpl !-

    // init all screen pointers
    ldx #7
!:
    lda #SPRITEDATA/64
    sta SCREEN+$3f8,x
    clc
    adc #1
    sta SCREEN2+$3f8,x

    dex
    bpl !-

    lda #2
    ldx #7
!:
    sta $d027,x
    adc #1
    dex
    bpl !-

    ldx #0
    ldy #24
!:
    lda #229
    sta $d001,x
    tya
    sta $d000,x
    adc #24
    tay

    inx
    inx
    cpx #16
    bne !-

    rts

initIrq:
    lda #$7f
    sta $dc0d  //disable timer interrupts which can be generated by the two CIA chips
    sta $dd0d  //the kernal uses such an interrupt to flash the cursor and scan the keyboard, so we better
               //stop it.

    lda $dc0d  //by reading this two registers we negate any pending CIA irqs.
    lda $dd0d  //if we don't do this, a pending CIA irq might occur after we finish setting up our irq.
               //we don't want that to happen.

    lda #$01   //this is how to tell the VICII to generate a raster interrupt
    sta $d01a

    lda irqRows  //this is how to tell at which rasterline we want the irq to be triggered
    sta $d012

    lda #$1b   //as there are more than 256 rasterlines, the topmost bit of $d011 serves as
    sta $d011  //the 9th bit for the rasterline we want our irq to be triggered.
               //here we simply set up a character screen, leaving the topmost bit 0.

    lda #$35   //we turn off the BASIC and KERNAL rom here
    sta $01    //the cpu now sees RAM everywhere except at $d000-$e000, where still the registers of
               //SID/VICII/etc are visible

    lda #<irq  //this is how we set up
    sta $fffe  //the address of our interrupt code
    lda #>irq
    sta $ffff

    lda #<nmi
    sta $fffa
    lda #>nmi
    sta $fffb

    rts

nmi:
    rti

irqPos:
    .byte 0
irqRows:
    .fill DIVISIONS,50+i*7
d018:
    .fill DIVISIONS/2, [$0e,$0e,$0e,$1e,$1e,$1e]

costable:
    .fill 256, 63+24*cos(toRadians(i*360/128))

xpos:
    .fill DIVISIONS,i

    .align 64
spriteData:
    .fill 3,$ff
    .fill 19,[$80,$00,$01]
    .fill 3,$ff
    .byte 0
spriteData2:
    .byte $80,$00,$01
    .byte $40,$00,$02
    .byte $20,$00,$04
    .byte $10,$00,$08
    .byte $08,$00,$10
    .byte $04,$00,$20
    .byte $02,$00,$40
    .byte $01,$00,$80
    .byte $00,$81,$00
    .byte $00,$42,$00

    .byte $00,$3c,$00

    .byte $00,$42,$00
    .byte $00,$81,$00
    .byte $01,$00,$80
    .byte $02,$00,$40
    .byte $04,$00,$20
    .byte $08,$00,$10
    .byte $10,$00,$08
    .byte $20,$00,$04
    .byte $40,$00,$02
    .byte $80,$00,$01
    .byte 0

