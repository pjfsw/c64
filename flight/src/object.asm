#importonce

.segment Default

.const NUMBER_OF_BULLETS=3

object: {
    // Sprite 7 is bullet sprite shared between 2 x NPC + player
    multiplex: {
        ldx multiplex_count
        lda bullet.x_lo,x
        sta x.lo + 7
        lda bullet.x_hi,x
        sta x.hi + 7
        lda bullet.y_lo,x
        sta y.lo + 7
        lda bullet.y_hi,x
        sta y.hi + 7
        lda bullet.ptr,x
        sta sprite.ptr + 7
        lda bullet.enabled,x
        sta sprite.enabled + 7
        inx
        cpx #NUMBER_OF_BULLETS
        bne !+
        ldx #0
    !:
        stx multiplex_count
        rts
    }

    animate: {
        ldx #6 // Sprites 0-6 are animated
    !next_object:
        lda sprite.enabled,x
        beq !done+
        {
            lda animation.timer,x
            beq !advance_frame+

            dec animation.timer,x
            jmp !update_sprite+

        !advance_frame:
            lda animation.frame_length,x
            sta animation.timer,x
            clc
            lda animation.frame,x
            adc #1
            cmp animation.animation_length,x
            bcc !+
            {
                lda animation.loop,x
                bne !+
                // one shot animation, turn off sprite
                lda #0
                sta sprite.enabled,x
                sta animation.frame,x
                jmp !done+
            !:
                // animation loop, reset to first frame
                lda #0
            }
        !:
            sta animation.frame,x

        !update_sprite:
            lda animation.ptr_lo,x
            sta animation_ptr
            lda animation.ptr_hi,x
            sta animation_ptr + 1

            lda animation.frame,x
            tay
            lda animation_ptr:$1000,y
            sta sprite.ptr,x
        }
    !done:
        dex
        bpl !next_object-
        rts
    }

multiplex_count:
    .byte 0

.segment DATA
    bullet: {
        x_lo: .fill NUMBER_OF_BULLETS,0
        x_hi: .fill NUMBER_OF_BULLETS,0
        y_lo: .fill NUMBER_OF_BULLETS,0
        y_hi: .fill NUMBER_OF_BULLETS,0
        ptr: .fill NUMBER_OF_BULLETS,0
        enabled: .fill NUMBER_OF_BULLETS,0
    }

    // IN WORLD COORDINATES
    y: {
        lo: {
            player: .byte 0
            shadow: .byte 0
            gun:    .byte 0
            npc:    .byte 0
            npc2:   .byte 0
            npc_shadow1: .byte 0
            npc_shadow2: .byte 0
            bullet: .byte 0

        }
        hi: {
            player: .byte 0
            shadow: .byte 0
            gun:    .byte 0
            npc:    .byte 0
            npc2:   .byte 0
            npc_shadow1: .byte 0
            npc_shadow2: .byte 0
            bullet: .byte 0
        }
    }

    // IN SCREEN CORDINATES
    x: {
        lo: {
            player: .byte 0
            shadow: .byte 0
            gun:    .byte 0
            npc:    .byte 0
            npc2:   .byte 0
            npc_shadow1: .byte 0
            npc_shadow2: .byte 0
            bullet: .byte 0
        }
        hi: {
            player: .byte 0
            shadow: .byte 0
            gun:    .byte 0
            npc:    .byte 0
            npc2:   .byte 0
            npc_shadow1: .byte 0
            npc_shadow2: .byte 0
            bullet: .byte 0
        }
    }

    sprite: {
        enabled: .fill 8,0
        ptr: .fill 8,0
    }

    animation: {
        // Number of frames in animation
        animation_length: .fill 8,0

        // Number of raster frames per animation frame
        frame_length: .fill 8,0

        // Countdown timer per frame
        timer: .fill 8,0

        // 1 = animation will loop, 0 = sprite is turned off after one iteration
        loop: .fill 8,0

        // Current frame in animation
        frame: .fill 8,0

        // Low byte of pointer to animation sequence
        ptr_lo: .fill 8,0

        // High byte of pointer to animation sequence
        ptr_hi: .fill 8,0
    }
}
