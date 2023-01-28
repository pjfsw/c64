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
    .var SHADOW_SPRITE_OFFSET = (shadow_sprite-player_sprite)/64
    .const HUD_SPRITE_POS = 50
    .const HUD_IRQ_ROW = 62
    .const SPRITE_IRQ_ROW = 70
    .const IRQ_ROW = $d8
    .const NUMBER_OF_NPCS = 50
    .const NPC_TRIGGER_OFFSET = 3


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
    cli

main:
    lda level_renderer.frame
    cmp last_frame
    beq main
    sta last_frame
    sec
    sbc last_frame
    sta frames
    lda next_npc
    sta $d020
    //debug3()
    jsr move_player
    lda next_npc
    cmp NUMBER_OF_NPCS
    bcs !+
    jsr cycle_npc
!:
    lda #0
    sta npc_index
    jsr npc_move_call:do_nothing
    lda #1
    sta npc_index
    jsr npc_move_call2:do_nothing
    jsr update_fire
    jsr draw_sprites
    debugoff(BORDER_COLOR)
    jmp main

do_nothing:
    rts

draw_sprites:
{
    // World coordinates are pointing upwards, so first we add a screen length to the bottom coordinate
    add16(level_renderer.bottom, chars_to_world(24), world_top)
    .for (var i = 0; i < 5; i++) {
        ldx #0
        ldy #0

        // For each sprite we calc the difference between the top coord and the sprite coord
        sub16mem(world_top, sprite_y_coord + i * 2, temp_coord)
        lda temp_coord+1
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
        ldx sprite_x_coord + i * 2
        ldy sprite_x_coord + i * 2 + 1
    !:
        stx level_renderer.sprite_x + i
        sty level_renderer.sprite_x_hi + i
    }
}

cycle_npc: {
    lda level_renderer.bottom+1
    clc
    adc #NPC_TRIGGER_OFFSET
    ldx next_npc
    stx $d021
    cmp npc_trigger,x
    bcs !+
    rts
!:  // Next NPC in frame, setup game logic things for that NPC here
    lda #0
    ldy next_npc_sprite
    sta sprite_y_coord.npc,y
    lda npc_trigger,x
    sta sprite_y_coord.npc+1,y
    lda npc_trigger_x_coord,y
    sta sprite_x_coord.npc,y
    lda npc_trigger_x_coord+1,y
    sta sprite_x_coord.npc+1,y

    cpy #0
    bne !+
    {
        lda npc_move_func_lo,x
        sta npc_move_call
        lda npc_move_func_hi,x
        sta npc_move_call + 1
        lda #0
        sta npc_sequence_pos
        sta npc_sequence_pos_scale
    }
    jmp !done+
!:
    lda npc_move_func_lo,x
    sta npc_move_call2
    lda npc_move_func_hi,x
    sta npc_move_call2 + 1
    lda #0
    sta npc_sequence_pos+1
    sta npc_sequence_pos_scale+1

!done:
    inx
    stx next_npc

    tya
    eor #%00000010  // Toggle two words back and forth
    sta next_npc_sprite

    rts
}

update_npc:
{
    // Animation stuff
    lda #npc_sprite/64
    sta level_renderer.sprite_ptr + NPC_SPRITE_NO
    sta level_renderer.sprite_ptr + NPC_SPRITE_NO + 1
    lda #0
    sta level_renderer.sprite_color + NPC_SPRITE_NO
    lda #2
    sta level_renderer.sprite_color + NPC_SPRITE_NO + 1
    ldx npc_index
    lda npc_sequence_pos_scale,x
    clc
    adc #1
    and #3  // Takes too much memory to change position every frame
    bne !+
    inc npc_sequence_pos,x
    lda #0
!:
    sta npc_sequence_pos_scale,x
    lda npc_sequence_pos,x
    tay
    // Do 8-bit indexed operations here
    // ..
    // 16-bit indexed from here
    txa
    asl
    tax

    clc
    lda npc_movement_x_lo,y
    adc sprite_x_coord.npc,x
    sta sprite_x_coord.npc,x
    lda npc_movement_x_hi,y
    adc sprite_x_coord.npc+1,x
    sta sprite_x_coord.npc+1,x

    clc
    lda npc_movement_y_lo,y
    adc sprite_y_coord.npc,x
    sta sprite_y_coord.npc,x
    lda npc_movement_y_hi,y
    adc sprite_y_coord.npc+1,x
    sta sprite_y_coord.npc+1,x

    rts
}

update_fire:
{
    lda #0
    sta sprite_x_coord.gun
    sta sprite_x_coord.gun+1
    add16(sprite_y_coord.player, pixels_to_world(5), sprite_y_coord.gun)

    lda level_renderer.joyfire
    beq !+

    lda sprite_x_coord.player
    sta sprite_x_coord.gun
    lda sprite_x_coord.player + 1
    sta sprite_x_coord.gun + 1
!:
    // TODO multiplex fire sprite between player and enemy fire
    lda level_renderer.frame
    and #2
    bne !odd_frame+

    ldx gun_anim
    lda gun_anim_color,x
    sta level_renderer.sprite_color + FIRE_SPRITE_NO
    inx
    cpx #gun_anim_color_end-gun_anim_color
    bne !+
    ldx #0
!:
    stx gun_anim
    rts

!odd_frame:
    lda #0
    sta level_renderer.sprite_x + FIRE_SPRITE_NO
    sta level_renderer.sprite_x_hi + FIRE_SPRITE_NO
    rts

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
    copy16(player_x, sprite_x_coord.player)
    add16(level_renderer.bottom, pixels_to_world(PLAYER_BOTTOM_POS), sprite_y_coord.player)
    copy16(sprite_y_coord.player, sprite_y_coord.shadow)
    ldx player_h
    lda height_to_world,x
    sta h_world_temp
    add_16_8_mem(sprite_y_coord.player, h_world_temp, sprite_y_coord.player)

    add_16_8_mem(player_x, player_h, sprite_x_coord.shadow)

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

.segment Default

setup_screen:
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

gun_anim:
    .byte 0
gun_anim_color:
    .byte 8,7,2,1
gun_anim_color_end:

player_anim:
    .byte 0

world_coord_high_bits:
    .fill 8,i*32
height_to_world:
    .fill 32,i*8

next_npc:
    .byte 0
next_npc_sprite:
    .byte 0
npc_trigger_x_coord:
    .word 0,0

npc_trigger:
    .fill NUMBER_OF_NPCS, [i*8+4, i*8+8] // 41*6+9 = 255
npc_move_func_lo:
    .fill NUMBER_OF_NPCS, <update_npc
npc_move_func_hi:
    .fill NUMBER_OF_NPCS, >update_npc

.function getMoveX(i) {
    .return abs(i-32)/20+1
}

.function getMoveY(i) {
    .return 16-i/4
}

npc_movement_x_lo:
    .fill 64,<getMoveX(i)
npc_movement_x_hi:
    .fill 64,>getMoveX(i)
npc_movement_y_lo:
    .fill 64,<getMoveY(i)
npc_movement_y_hi:
    .fill 64,>getMoveY(i)

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

.segment DATA

// IN WORLD COORDINATES
sprite_y_coord: {
    player: .word 0
    shadow: .word 0
    gun:    .word 0
    npc:    .fillword 2,0
            .fillword 3,0
}

// IN SCREEN CORDINATES
sprite_x_coord: {
    player: .word 0
    shadow: .word 0
    gun:    .word 0
    npc:    .fillword 2,0
            .fillword 3,0
}

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
npc_index:
    .byte 0
npc_sequence_pos_scale:
    .byte 0
    .byte 0
npc_sequence_pos:
    .byte 0
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
    .fill 64,0
shadow_sprite:
    .fill 64,0

.segment ZP
.zp {
    copy_src_ptr: .word 0
    copy_dst_ptr: .word 0
    row_in_tile: .byte 0
}
