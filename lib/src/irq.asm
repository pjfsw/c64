#importonce

// Setup IRQ.
// A = IRQ line
// X/Y = IRQ handler

lib_setup_irq:
    sta irq_line
    lda #$7f
    sta $dc0d  //disable timer interrupts which can be generated by the two CIA chips
    sta $dd0d  //the kernal uses such an interrupt to flash the cursor and scan the keyboard, so we better
               //stop it.

    lda $dc0d  //by reading this two registers we negate any pending CIA irqs.
    lda $dd0d  //if we don't do this, a pending CIA irq might occur after we finish setting up our irq.
               //we don't want that to happen.

    lda #$01   //this is how to tell the VICII to generate a raster interrupt
    sta $d01a

    lda irq_line:#0  //this is how to tell at which rasterline we want the irq to be triggered
    sta $d012

    lda #$1b   //as there are more than 256 rasterlines, the topmost bit of $d011 serves as
    sta $d011  //the 9th bit for the rasterline we want our irq to be triggered.
               //here we simply set up a character screen, leaving the topmost bit 0.

    lda #$35   //we turn off the BASIC and KERNAL rom here
    sta $01    //the cpu now sees RAM everywhere except at $d000-$e000, where still the registers of
               //SID/VICII/etc are visible

    stx $fffe  //the address of our interrupt code
    sty $ffff

    lda #<lib_nmi
    sta $fffa
    lda #>lib_nmi
    sta $fffb
    rts

lib_nmi:
    rti