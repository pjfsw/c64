.var music = LoadSid("znorky50.sid")
.var bg = LoadBinary("znorky50.seq")

BasicUpstart2(programStart)
    *=$080e

programStart:
    sei
    jsr init
    
    lda #0
    jsr music.init

    lda #0
    sta $d020
    sta $d021
    cli
    jmp *

init:
    lda #$35    // RAM $0000-$CFFF, IO $D000-$DFFF, RAM $E000-$FFFF
    sta $01

    lda #$7f    // Clear CIA interrupts
    sta $dc0d
    sta $dd0d
    lda $dd0d

    lda #$01
    sta $d01a   // Raster IRQ enable

    lda #$f0 // Raster Y position
    sta $d012

    lda #$1b    // 25 rows
    sta $d011

    lda #$c8    // 40 cols, two color
    sta $d016

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

    ldx #0
!:
    .for (var i = 0; i < 4; i++) {
        lda bgdata+i*256,x
        sta $0400+i*256,x
        lda bgdata+1000+i*256,x
        sta $d800+i*256,x
    }
    inx
    bne !-

    .for (var i = 0; i < 8; i++) {
        lda #(spritedata+i*64)/64
        sta $07f8+i
    }
    lda #$1
    ldx #0

    lda #$ff
    sta $d015 // Enable all sprites
    //sta $d01b // Sprite behind bg
    
    rts

.const beatlength = 40
nmi:
    rti
irq:
    sta a_temp
    stx x_temp
    sty y_temp
    // IRQ START

    jsr music.play

    .for (var i = 0; i < 8; i++) {
        ldx sinidx+i
        lda sintab,x
        inx
        stx sinidx+i
        sta $d001+i*2
        lda xpos+i
        sta $d000+i*2
    }
    lda #$c0
    sta $d010

    ldx spritecolidx
    lda spritecol,x
    ldy #7
!:
    sta $d027,y
    dey
    bpl !-
    inx
    cpx #beatlength
    bne !+
    ldx #0
!:    
    stx spritecolidx

    // IRQ DONE
    asl $d019
    lda a_temp:#0
    ldx x_temp:#0
    ldy y_temp:#0
    rti

sinidx:
    .fill 8,i*5  
.align $100
sintab:    .fill 256,75+(25*sin(i*PI/64))
xpos: .byte 40,70,100,130,160,190,0,290

.align $40
spritedata:
.var lettern = LoadPicture("znorky50.png")
.for (var n = 0; n < 8; n++) {
    .for (var y = 0; y < 21; y++) {
        .for (var x = 0; x < 3; x++) {
            .byte lettern.getSinglecolorByte(x,y+n*21)
        }
    }
    .byte 0
}

spritecolidx:
    .byte beatlength-1
spritecol:
    .byte $01,$0d,$0d,$03,$03,$0e,$0e,$04,$04,$0b,$0b
    .fill beatlength-(*-spritecol),6
bgdata:    
#import "bg.asm"

*=music.location "Music"
    .fill music.size, music.getData(i)
