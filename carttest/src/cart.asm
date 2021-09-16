.const EASYFLASH_BANK    = $DE00
.const EASYFLASH_CONTROL = $DE02
.const EASYFLASH_LED     = $80
.const EASYFLASH_16K     = $07
.const EASYFLASH_KILL    = $04

.segment CARTRIDGE_FILE [outBin="cart.bin"]
    .segmentout [segments = "BANK0_0"]
    .segmentout [segments = "BANK0_1"]
    .segmentout [segments = "BANK1"]
    .segmentout [segments = "BANK_DUMMY"]

.segmentdef BANK0_0 [min=$8000, max=$9fff, fill]
.segmentdef BANK0_1 [min=$e000, max=$ffff, fill]
.segmentdef BANK1 [min=$8000, max=$bfff, fill]
.segmentdef BANK_DUMMY [min=$0, max=$f7fff, fill]

.segment BANK0_0
*=$8000
    // Copy the code to $c000 so we are protected from bankswitching
    ldx #0
!:
    lda main,x
    sta $c000,x
    dex
    bne !-
    jmp $c000
main:
.pseudopc $c000 {
    lda #1
    sta EASYFLASH_BANK
    lda $8000
    sta $0400
    lda $a000
    sta $0401
!:
    inc $d020
    jmp !-
}

.segment BANK0_1
* = $e000
cold_start:
    // === the reset vector points here ===
    sei
    ldx #$ff
    txs
    cld

    // enable VIC (e.g. RAM refresh)
    lda #8
    sta $d016

!:  // Some weird memory initialization
    sta $0100, x
    dex
    bne !-

    ldx #(startup_end-startup_begin)
!:
    lda startup_begin,x
    sta $0100,x
    dex
    bpl !-
    jmp $0100

startup_begin:
.pseudopc $0100 {
    lda #EASYFLASH_16K + EASYFLASH_LED
    sta EASYFLASH_CONTROL

    // Check keyboard if we should kill cartridge
    lda #$7f
    sta $dc00   // pull down row 7 PORTA

    ldx #$ff
    stx $dc02   // Set DDRA to outputs
    ldx #0
    stx $dc03   // Set DDRB to inputs

    lda $dc01   // Read columns

    stx $dc02   // Set DDRA back to inputs
    stx $dc00   // No row pulled down

    and #$e0    // Leave "Run/Stop", "Q" and "C="
    cmp #$e0
    bne kill    // if pressed, we kill the cartridge

    ldx #0
    stx $d016
    jsr $ff84   // initialize I/O

    jsr $ff87   // initial system constants
    jsr $ff8a   // restore kernal vectors
    jsr $ff81   // initialize screen editor

    jmp $8000   // Start application
kill:
    lda #EASYFLASH_KILL
    sta EASYFLASH_CONTROL
    jmp ($fffc) // Reset
}
startup_end:

no_interrupt:
    rti
* = $fffa
    .word no_interrupt
    .word cold_start
    .word no_interrupt

.segment BANK1
* = $8000
.encoding "screencode_upper"
    .fill $2000,'0'
    .fill $2000,'1'

.segment BANK_DUMMY
