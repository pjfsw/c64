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
    .const PLAYER_TOP_BOUND = 15
    .const PLAYER_BOTTOM_BOUND = 2
    .const PLAYER_BOTTOM_POS = 24
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
    .const NPC_SPRITE_NO = 3
    .const NPC_SHADOW_SPRITE_NO = 5
    .var SHADOW_SPRITE_OFFSET = (shadow_sprite-player_sprite)/64
    .const HUD_SPRITE_POS = 50
    .const HUD_IRQ_ROW = 62
    .const SPRITE_IRQ_ROW = 70
    .const IRQ_ROW = $d8
    .const NUMBER_OF_NPCS = 50
    .const NPC_TRIGGER_OFFSET = 2
    .const NPC_HELICOPTER_HITS = 5
    .const NPCS_ON_SCREEN = 2

    .const PLAYER_ANIMATION_SPEED = 3
    .const FIRE_ANIMATION_SPEED = 3

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
    sta level_renderer.frame
    sta last_frame
    jsr copy_sprites
    sei
    ldx #<level_renderer.main_irq
    ldy #>level_renderer.main_irq
    lda #IRQ_ROW
    jsr irq.lib_setup_irq
    jsr setup_screen
    jsr init_animations
    cli

main:
    lda level_renderer.frame
    cmp last_frame
    beq main
    sta last_frame
    sec
    sbc last_frame
    sta frames
    debug3()
    jsr move_player
    lda npc.next_npc
    cmp #NUMBER_OF_NPCS
    bcs !+

    jsr npc.cycle_npc
!:
    jsr update_fire

    lda #0
    sta npc.npc_index
    jsr npc_move_call:do_nothing
    jsr npc.update_npc_hit

    lda #1
    sta npc.npc_index
    jsr npc_move_call2:do_nothing
    jsr npc.update_npc_hit

    inc npc.npc_h_index

    debug3()
    jsr object.animate
    debug2()
    jsr draw_sprites
    debugoff(BORDER_COLOR)
    jmp main


do_nothing:
    rts

draw_sprites:
{
    .for (var i = 0; i < NPCS_ON_SCREEN; i++) {
        lda npc.npc_enabled + i
        sta level_renderer.sprite_enabled + NPC_SPRITE_NO + i
        sta level_renderer.sprite_enabled + NPC_SHADOW_SPRITE_NO + i
    }

    // World coordinates are pointing upwards, so first we add a screen length to the bottom coordinate
    add16(level_renderer.bottom, chars_to_world(24), world_top)
    .for (var i = 0; i < 7; i++) {
        .if (i < 3) {
            lda object.sprite.ptr + i
            sta level_renderer.sprite_ptr + i
            lda object.sprite.enabled + i
            sta level_renderer.sprite_enabled + i
        }
        ldx #0
        ldy #0

        // For each sprite we calc the difference between the top coord and the sprite coord
        sec
        lda world_top
        sbc object.y.lo + i
        sta temp_coord
        lda world_top + 1
        sbc object.y.hi + i
        sta temp_coord + 1

        cmp #7
        bcs !+ // Out of bounds

        // Lowest byte contains CCxxxsss, C = char in tile, x = x-coord, so we get rid of the subpixels
        lda temp_coord
        lsr
        lsr
        lsr
        clc
        adc #50 // sprite offset
        sta temp_y
        // Fetch the three lower bits in the high byte and merge them to get a screen 256-pixel value
        lda temp_coord+1
        and #7
        tax
        lda world_coord_high_bits,x
        clc
        adc temp_y
        // Now we are in sprite coordinates so store it in the correct sprite position
        sta level_renderer.sprite_y + i

        // X-axis is just screen coords, plain copy
        ldx object.x.lo + i
        ldy object.x.hi + i
    !:
        stx level_renderer.sprite_x + i
        sty level_renderer.sprite_x_hi + i
    }
    rts
}

update_fire:
{
    lda #0
    sta npc.player_fire

    clc
    lda object.y.lo.player
    adc #<pixels_to_world(5)
    sta object.y.lo.gun
    lda object.y.hi.player
    adc #>pixels_to_world(5)
    sta object.y.hi.gun

    lda object.x.lo.player
    sta object.x.lo.gun
    sta npc.npc_player_fire_x
    lda object.x.hi.player
    sta object.x.hi.gun
    sta npc.npc_player_fire_x + 1

    lda gun_repeat_time
    beq !+
    dec gun_repeat_time
    rts
!:
    lda level_renderer.joyfire
    bne !+
    rts
!:
    lda #1
    sta npc.player_fire

    lda #FIRE_ANIMATION_SPEED * 3
    sta gun_repeat_time

    lda #1
    sta object.sprite.enabled + FIRE_SPRITE_NO

    jmp reset_fire_animation
}

.const HSPEED = 2
move_player:
{
    ldx level_renderer.joyleft
    beq !+
    sub8(player_x, HSPEED, player_x)
!:
    ldx level_renderer.joyright
    beq !+
    add8(player_x, HSPEED, player_x)
!:
    ldx level_renderer.joyup
    beq !+
    lda player_h
    beq !+
    dec player_h
!:
    ldx level_renderer.joydown
    beq !+
    inc player_h
!:

    // Set player bounds
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
    lda player_h
    cmp #PLAYER_BOTTOM_BOUND
    bcs !+
    lda #PLAYER_BOTTOM_BOUND
    sta player_h
!:
    cmp #PLAYER_TOP_BOUND
    bcc !+
    lda #PLAYER_TOP_BOUND
    sta player_h
!:
    lda player_x
    sta object.x.lo.player
    lda player_x + 1
    sta object.x.hi.player

    clc
    lda level_renderer.bottom
    adc #<pixels_to_world(PLAYER_BOTTOM_POS)
    sta object.y.lo.player
    lda level_renderer.bottom + 1
    adc #>pixels_to_world(PLAYER_BOTTOM_POS)
    sta object.y.hi.player


    lda object.y.lo.player
    sta object.y.lo.shadow
    lda object.y.hi.player
    sta object.y.hi.shadow

    ldx player_h
    lda height_to_world,x
    sta h_world_temp

    // Adjust player y-coordinate according to vehicle height
    clc
    lda object.y.lo.player
    adc h_world_temp
    sta object.y.lo.player
    bcc !+
    inc object.y.hi.player
!:

    // Adjust player shadow x-coordinate according to vehicle height
    clc
    lda player_x
    adc player_h
    sta object.x.lo.shadow
    lda player_x + 1
    adc #0
    sta object.x.hi.shadow

    rts
}

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

#import "level_renderer.asm"
#import "npc.asm"

.segment Default

.macro make_shadow(i) {
    .if (mod((i&63),6) >= 3) {
        and #%10101010
    } else {
        and #%01010101
    }
}

init_animations:
    lda #<player_animation
    sta object.animation.ptr_lo + PLAYER_SPRITE_NO
    lda #>player_animation
    sta object.animation.ptr_hi + PLAYER_SPRITE_NO

    lda #<shadow_animation
    sta object.animation.ptr_lo + SHADOW_SPRITE_NO
    lda #>shadow_animation
    sta object.animation.ptr_hi + SHADOW_SPRITE_NO

    lda #player_animation_end-player_animation
    sta object.animation.animation_length + PLAYER_SPRITE_NO
    sta object.animation.animation_length + SHADOW_SPRITE_NO

    lda #PLAYER_ANIMATION_SPEED
    sta object.animation.frame_length + PLAYER_SPRITE_NO
    sta object.animation.timer + PLAYER_SPRITE_NO
    sta object.animation.frame_length + SHADOW_SPRITE_NO
    sta object.animation.timer + SHADOW_SPRITE_NO

    lda #1
    sta object.animation.loop + PLAYER_SPRITE_NO
    sta object.animation.loop + SHADOW_SPRITE_NO

    sta object.sprite.enabled + PLAYER_SPRITE_NO
    sta object.sprite.enabled + SHADOW_SPRITE_NO

    lda #0
    sta object.animation.frame + PLAYER_SPRITE_NO
    sta object.animation.frame + SHADOW_SPRITE_NO

    lda #<gun_animation
    sta object.animation.ptr_lo + FIRE_SPRITE_NO
    lda #>gun_animation
    sta object.animation.ptr_hi + FIRE_SPRITE_NO
    lda #FIRE_ANIMATION_SPEED
    sta object.animation.frame_length + FIRE_SPRITE_NO

    lda #0
    sta object.sprite.enabled + FIRE_SPRITE_NO

    jmp reset_fire_animation

reset_fire_animation:
    lda #0
    sta object.animation.loop + FIRE_SPRITE_NO
    sta object.animation.frame + FIRE_SPRITE_NO
    lda #1
    sta object.animation.animation_length + FIRE_SPRITE_NO

    lda #FIRE_ANIMATION_SPEED
    sta object.animation.timer + FIRE_SPRITE_NO
    rts

setup_screen:
    and #%11111100
    ora #%00000001 // // VIC bank in $8000-$bfff
    sta $dd00

    lda #0
    sta $d01b // sprite priority

    .for (var i = 0; i < 127; i++) {
        lda player_sprite + i
        make_shadow(i)
        sta shadow_sprite + i
    }
    .for (var i = 0; i < 127; i++) {
        lda npc_sprite + i
        make_shadow(i)
        sta npc_shadow_sprite + i
    }

    lda #172
    sta player_x
    lda #0
    sta player_x+1
    lda #PLAYER_BOTTOM_BOUND
    sta player_h

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
    beq !-

    rts
}

#import "debug.asm"
#import "../../lib/src/irq.asm"
#import "arithmetic.asm"

gun_animation:
    .byte gun_sprite/64, gun_sprite/64
gun_animation_end:

player_animation:
    .byte player_sprite/64, player_sprite/64+1
player_animation_end:
shadow_animation:
    .byte shadow_sprite/64, shadow_sprite/64+1
shadow_animation_end:

world_coord_high_bits:
    .fill 8,i*32
height_to_world:
    .fill 32,i*8
gun_repeat_time:
    .byte 0


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


#import "object.asm"

.segment DATA

player_x:
    .word 0
player_h:
    .byte 0
h_world_temp:
    .byte 0

world_top:
    .word 0
temp_coord:
    .word 0
temp_y:
    .byte 0
last_frame:
    .byte 0
frames:
    .byte 0

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
npc_sprite:
    .fill 128,0
shadow_sprite:
    .fill 128,0
npc_shadow_sprite:
    .fill 128,0
explosion_sprite:
    .fill 64*6,0
empty_sprite:
    .fill 64,0

.segment ZP
.zp {
    copy_src_ptr: .word 0
    copy_dst_ptr: .word 0
    row_in_tile: .byte 0
}
