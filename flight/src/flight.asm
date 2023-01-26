    .segmentdef DATA[startAfter= "Default", align=$100, virtual]
    .segmentdef ZP[start=$02, virtual]

    .const SCREEN=$8800
    .const SCREEN_D018=$24
    .const SCREEN_SPRITES=SCREEN+$3f8

    .const SCREEN2=$8c00
    .const SCREEN2_D018=$34
    .const SCREEN2_SPRITES=SCREEN2+$3f8

    .const PLAYER_LEFT_BOUND = 24
    .const PLAYER_RIGHT_BOUND = 320
    .const PLAYER_TOP_BOUND = 16
    .const PLAYER_BOTTOM_BOUND = 2
    .const PLAYER_BOTTOM_POS = 224
    .const ROWS_TO_RENDER_PER_FRAME=3
    .const FRAMES_TO_RENDER_TILES=8
    .const BORDER_COLOR = 0
    .const FG_COLOR = 6
    .const HUD_FG_COLOR = 0
    .const HUD_MSG_OFFSET = 7
    .const HUD_MSG_LENGTH = 28
    .const CHAR_COLOR = 5
    .const HUD_CHAR_COLOR = 15
    .const TILE_WIDTH = 4
    .const TILES_PER_ROW = 40/TILE_WIDTH
    .const TILE_HEIGHT = 4
    .const FIXED_POINT = 8
    .const CHAR_HEIGHT = 8 // Well this is never gonna change but might as well constant it for readability
    .const CHAR_SUBPIXEL_SIZE = FIXED_POINT * CHAR_HEIGHT
    .const MAP_LENGTH = 200
    .const BOTTOM_TILE_AT_END = MAP_LENGTH - 24/TILE_HEIGHT
    .const SPRITE_MEM = $a000
    .const PLAYER_SPRITE_NO = 0
    .const SHADOW_SPRITE_NO = 1
    .const FIRE_SPRITE_NO = 2
    .var SHADOW_SPRITE_OFFSET = (shadow_sprite-player_sprite)/64
    .const HUD_SPRITE_POS = 50
    .const HUD_IRQ_ROW = 62
    .const SPRITE_IRQ_ROW = 70
    .const IRQ_ROW = $d8


.macro set_top_row_colors(color) {
    lda #color
    .for (var i = HUD_MSG_OFFSET; i < HUD_MSG_OFFSET+HUD_MSG_LENGTH; i++) {
        sta $d800+i
    }
}

BasicUpstart2(program_start)
    *=$080e

program_start:
    lda #0
    sta frame
    sta last_frame
    jsr copy_sprites
    sei
    ldx #<main_irq
    ldy #>main_irq
    lda #IRQ_ROW
    jsr irq.lib_setup_irq
    jsr setup_screen
    cli

main:
    lda frame
    cmp last_frame
    beq main
    sta last_frame
    sec
    sbc last_frame
    sta frames
    debug1()
    jsr move_player
    jsr update_shadow
    jsr update_fire
    debugoff(BORDER_COLOR)
    jmp main

update_fire:
{
    lda #0
    sta player_fire_x
    sta player_fire_x+1
    lda sprite_y
    sbc #5
    sta player_fire_y

    lda joyfire
    beq !+

    lda player_x
    sta player_fire_x
    lda player_x + 1
    sta player_fire_x + 1

!:
    // TODO multiplex fire sprite between player and enemy fire
    lda frame
    and #1
    bne !odd_frame+

    lda player_fire_x
    sta sprite_x + FIRE_SPRITE_NO
    lda player_fire_x + 1
    sta sprite_x_hi + FIRE_SPRITE_NO
    lda player_fire_y
    sta sprite_y + FIRE_SPRITE_NO

    ldx gun_anim
    lda gun_anim_color,x
    sta sprite_color + FIRE_SPRITE_NO
    inx
    cpx #gun_anim_color_end-gun_anim_color
    bne !+
    ldx #0
!:
    stx gun_anim
    rts

!odd_frame:
    lda #0
    sta sprite_x + FIRE_SPRITE_NO
    sta sprite_x_hi + FIRE_SPRITE_NO
    rts

}

update_shadow:
{
    lda player_x
    clc
    adc player_h
    sta sprite_x + SHADOW_SPRITE_NO
    rol
    and #1
    ora sprite_x_hi + PLAYER_SPRITE_NO
    sta sprite_x_hi + SHADOW_SPRITE_NO
    lda #PLAYER_BOTTOM_POS
    sta sprite_y + SHADOW_SPRITE_NO
    rts
}
.const HSPEED = 2
.const VSPEED = 1
move_player:
{
    ldx joyleft
    beq !+
    sub8(player_x, HSPEED, player_x)
!:
    ldx joyright
    beq !+
    add8(player_x, HSPEED, player_x)
!:
    ldx joyup
    beq !+
    sub8(player_h, VSPEED, player_h)
!:
    ldx joydown
    beq !+
    add8(player_h, VSPEED, player_h)
!:
    jmp bound_player
    rts
}

bound_player:
    cmp16(player_x, PLAYER_LEFT_BOUND)
    bcs !+
    lda #<PLAYER_LEFT_BOUND
    sta player_x
    lda #>PLAYER_LEFT_BOUND
    sta player_x+1
!:
    cmp16(player_x, PLAYER_RIGHT_BOUND)
    bcc !+
    lda #<PLAYER_RIGHT_BOUND
    sta player_x
    lda #>PLAYER_RIGHT_BOUND
    sta player_x+1
!:
    cmp16(player_h, PLAYER_BOTTOM_BOUND)
    bcs !+
    lda #<PLAYER_BOTTOM_BOUND
    sta player_h
    lda #>PLAYER_BOTTOM_BOUND
    sta player_h+1
!:
    cmp16(player_h, PLAYER_TOP_BOUND)
    bcc !+
    lda #<PLAYER_TOP_BOUND
    sta player_h
    lda #>PLAYER_TOP_BOUND
    sta player_h+1
!:
    lda player_x
    sta sprite_x
    lda player_x+1
    sta sprite_x_hi

    lda #PLAYER_BOTTOM_POS
    sec
    sbc player_h
    sta sprite_y
    rts

level_clear_irq: {
    sta save_a
    stx save_x
    sty save_y
    lda #$ff   // this is the orthodox and safe way of clearing the interrupt condition of the VICII.
    sta $d019

    lda save_a:#0
    ldy save_y:#0
    ldx save_x:#0
    rti
}

hud_irq: {
    sta save_a
    stx save_x
    sty save_y

    debug2()

    ldx level_renderer.scroll
    lda d011,x
    sta $d011

    set_top_row_colors(CHAR_COLOR)
    lda #FG_COLOR
    sta $d021

    debugoff(BORDER_COLOR)

    next_irq(sprite_irq, SPRITE_IRQ_ROW)

    lda save_a:#0
    ldy save_y:#0
    ldx save_x:#0
    rti

}

sprite_irq: {
    sta save_a
    stx save_x
    sty save_y

    debug1()

    ldy #0
    sty $d01c
    .for (var i = 0; i < 8; i++) {
        lda sprite_ptr + i
        sta (level_renderer.screen_sprite_ptr),y
        iny
    }

    lda #$7f
    sta $d015 // sprite enable
    lda #0
    sta $d01d // normal width

    .for (var i = 0; i < 8; i++) {
        lda sprite_x + i
        sta $d000 + i * 2
        lda sprite_y + i
        sta $d001 + i * 2
        lda sprite_color + i
        sta $d027 + i // color
    }

    lda #0
    .for (var i = 0; i < 8; i++) {
        asl
        ora sprite_x_hi + (7-i)
    }
    sta $d010

    debugoff(BORDER_COLOR)

    next_irq(main_irq, IRQ_ROW)

    lda save_a:#0
    ldy save_y:#0
    ldx save_x:#0
    rti
}

main_irq: {
    sta save_a
    stx save_x
    sty save_y

    debug2()
    jsr level_renderer.update
    debug1()
    jsr update_hud
    jsr update_anim
    jsr read_input
    set_top_row_colors(HUD_CHAR_COLOR)

    lda bottom+1
    cmp #BOTTOM_TILE_AT_END
    bne !+

    next_irq(level_clear_irq, IRQ_ROW)
    jmp !irq_done+
!:
    inc frame

    next_irq(hud_irq, HUD_IRQ_ROW)

!irq_done:
    debugoff(BORDER_COLOR)

    lda save_a:#0
    ldy save_y:#0
    ldx save_x:#0
    rti

update_hud:
{
    lda #hud_sprite/64
    ldy #0

    .for (var i = 0; i < 7; i++) {
        sta (level_renderer.screen_sprite_ptr),y
        iny
    }

    lda #HUD_SPRITE_POS
    .for (var i = 0; i < 7; i++) {
        sta $d001 + i * 2
    }
    .for (var i = 0; i < 7; i++) {
        lda #i*48+24
        sta $d000 + i * 2
    }
    lda #$60
    sta $d010
    lda #$7f
    sta $d015 // sprite enable
    sta $d01d // double width
    lda #$7f
    sta $d01c // multicolor
    lda #BORDER_COLOR
    sta $d026
    lda #HUD_CHAR_COLOR
    sta $d025

    lda #$1f
    sta $d011

    ldx level_renderer.screen_number
    lda d018,x
    sta $d018

    ldx #20
!:
    nop
    dex
    bne !-

    lda #HUD_FG_COLOR
    sta $d021

    rts
}

read_input:
{
    ldx #0
    ldy #1
    lda $dc00
    stx joyup
    lsr
    bcs !+
    sty joyup
!:
    stx joydown
    lsr
    bcs !+
    sty joydown
!:
    stx joyleft
    lsr
    bcs !+
    sty joyleft
!:
    stx joyright
    lsr
    bcs !+
    sty joyright
!:
    stx joyfire
    lsr
    bcs !+
    sty joyfire
!:
    rts
}

update_anim:
    inc player_anim
    lda player_anim
    lsr
    and #1
    clc
    adc #player_sprite/64
    sta sprite_ptr + PLAYER_SPRITE_NO
    adc #SHADOW_SPRITE_OFFSET
    sta sprite_ptr + SHADOW_SPRITE_NO
    lda #gun_sprite/64
    sta sprite_ptr + FIRE_SPRITE_NO
    rts

    #import "level_renderer.asm"
}

.segment Default

setup_screen:
    lda $dd00
    and #%11111100
    ora #%00000001 // // VIC bank in $8000-$bfff
    sta $dd00

    lda #0
    sta $d01b // sprite priority

    .for (var i = 0; i < 127; i++) {
        lda player_sprite + i
        .if (mod((i&63),6) >= 3) {
            and #%10101010
        } else {
            and #%01010101
        }
        sta player_sprite + SHADOW_SPRITE_OFFSET * 64 + i
    }

    lda #172
    sta player_x
    lda #0
    sta player_x+1
    lda #<PLAYER_BOTTOM_BOUND
    sta player_h
    lda #>PLAYER_BOTTOM_BOUND
    sta player_h+1

    lda #PLAYER_BOTTOM_POS
    sta sprite_y
    lda #PLAYER_BOTTOM_POS
    sta sprite_y+1

    lda #FG_COLOR
    sta $d021

    lda #CHAR_COLOR
    ldx #0
!:
    sta $d800,x
    sta $d900,x
    sta $da00,x
    sta $db00,x
    inx
    bne !-

    lda #32
    ldx #0
!:
    .for (var i = 0; i < 4; i++) {
        sta SCREEN + i * $100,x
        sta SCREEN2 + i * $100,x
    }
    inx
    bne !-

    ldx #40
    lda #32
!:
    sta SCREEN,x
    sta SCREEN2,x
    dex
    bpl !-

    ldx #hud_msg_length-1
!:
    lda hud_msg,x
    sta SCREEN + hud_msg_center,x
    sta SCREEN2 + hud_msg_center,x
    dex
    bpl !-

    rts

hud_msg:
    .text "ammo: 00 fuel: 00 dist: 00"
hud_msg_end:
.label hud_msg_length = hud_msg_end - hud_msg
.label hud_msg_center = (40-(hud_msg_end-hud_msg))/2

copy_sprites:
{
    lda #0
    sta copy_src_ptr    // Copy 256 bytes at a time
    sta copy_dst_ptr
    lda #>sprite_data
    sta copy_src_ptr+1
    lda #>sprite_location
    sta copy_dst_ptr+1
!:
    {
        ldy #0
    !:
        lda (copy_src_ptr),y
        sta (copy_dst_ptr),y
        iny
        bne !-
    }

    inc copy_dst_ptr+1
    lda copy_src_ptr+1
    clc
    adc #1
    sta copy_src_ptr+1
    cmp #>sprite_data_end
    bcc !-

    rts
}

#import "debug.asm"
#import "../../lib/src/irq.asm"
#import "arithmetic.asm"

gun_anim:
    .byte 0
gun_anim_color:
    .byte 8,7,2,1
gun_anim_color_end:

player_anim:
    .byte 0
sprite_ptr:
    .fill 8,0
sprite_x:
    .fill 8,0
sprite_y:
    .fill 8,0
sprite_x_hi:
    .fill 8,0
sprite_color:
    .byte 1,0,7,0,0,0,0,0

.align $100
sprite_data:
#import "spritedata.asm"
sprite_data_end:

// 16 bit y-coord:
// tttttttt TTyyynnn
// t = tile no
// T = row in tile data
// y = pixel on screen (scroll)
// n = 3-bit fixed point

bottom: .word 0
d011:   .byte $17,$10,$11,$12,$13,$14,$15,$16

d018:   .byte SCREEN_D018, SCREEN2_D018

.segment DATA

frame:
    .byte 0
last_frame:
    .byte 0
frames:
    .byte 0
joyup:
    .byte 0
joydown:
    .byte 0
joyleft:
    .byte 0
joyright:
    .byte 0
joyfire:
    .byte 0
player_x:
    .word 0
player_h:
    .word 0
player_fire_x:
    .word 0
player_fire_y:
    .word 0
*=$8800 "Screen1" virtual
    .fill $400,0
*=$8c00 "Screen2" virtual
    .fill $400,0
*=SPRITE_MEM "Sprites" virtual
sprite_location:
hud_sprite:
    .fill 64,0
player_sprite:
    .fill 128,0
gun_sprite:
    .fill 64,0
shadow_sprite:
    .fill 64,0

.segment ZP
.zp {
    copy_src_ptr: .word 0
    copy_dst_ptr: .word 0
    row_in_tile: .byte 0
}
