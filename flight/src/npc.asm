npc: {
.segment Default

.const HELI_ANIMATION_SPEED = 3
.const EXPLODE_ANIMATION_SPEED = 2
.const NPC_HELICOPTER_HITS = 3
.const NPC_COLOR = 0
.const NPC_EXPL_COLOR = 7
.const NPC_HIT_COLOR = 1
.const HIT_DISPLAY_FRAMES = 4

cycle_npc: {
    lda level_renderer.bottom+1

    clc
    adc #NPC_TRIGGER_OFFSET
    ldx next_npc
    cmp npc_trigger,x
    bcs !+
    rts

!:  // Next NPC in frame, setup game logic things for that NPC here
    ldy next_npc_sprite

    lda #0
    sta object.y.lo.npc_shadow1,y
    lda npc_trigger,x
    sta object.y.hi.npc_shadow1,y

    lda npc_trigger_x_coord_lo,y
    sta object.x.lo.npc,y
    lda npc_trigger_x_coord_hi,y
    sta object.x.hi.npc,y

    jsr init_animation

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
    sta npc.npc_sequence_pos+1
    sta npc.npc_sequence_pos_scale+1

!done:
    inx
    stx next_npc

    lda #1
    sta npc_is_alive,y
    lda #NPC_HELICOPTER_HITS
    sta npc_hitpoints,y

    tya
    eor #1  // Toggle two words back and forth
    sta next_npc_sprite

    rts
}

// Sprite index in x!
init_animation: {
    lda #NPC_COLOR
    sta level_renderer.sprite_color + NPC_SPRITE_NO,y
    sta level_renderer.sprite_color + NPC_SHADOW_SPRITE_NO,y

    lda #HELI_ANIMATION_SPEED
    sta object.animation.frame_length + NPC_SPRITE_NO,y
    sta object.animation.frame_length + NPC_SHADOW_SPRITE_NO,y
    sta object.animation.timer + NPC_SPRITE_NO,y
    sta object.animation.timer + NPC_SHADOW_SPRITE_NO,y

    lda #heli_animation_end-heli_animation
    sta object.animation.animation_length + NPC_SPRITE_NO,y
    sta object.animation.animation_length + NPC_SHADOW_SPRITE_NO,y

    lda #heli_shadow_animation_end-heli_shadow_animation
    sta object.animation.animation_length + NPC_SPRITE_NO,y
    sta object.animation.animation_length + NPC_SHADOW_SPRITE_NO,y

    lda #1
    sta object.sprite.enabled + NPC_SPRITE_NO,y
    sta object.sprite.enabled + NPC_SHADOW_SPRITE_NO,y
    sta object.animation.loop + NPC_SPRITE_NO,y
    sta object.animation.loop + NPC_SHADOW_SPRITE_NO,y

    lda #0
    sta object.animation.frame + NPC_SPRITE_NO,y
    sta object.animation.frame + NPC_SHADOW_SPRITE_NO,y

    lda #<heli_animation
    sta object.animation.ptr_lo + NPC_SPRITE_NO,y
    lda #>heli_animation
    sta object.animation.ptr_hi + NPC_SPRITE_NO,y

    lda #<heli_shadow_animation
    sta object.animation.ptr_lo + NPC_SHADOW_SPRITE_NO,y
    lda #>heli_shadow_animation
    sta object.animation.ptr_hi + NPC_SHADOW_SPRITE_NO,y
    rts
}

explode: {
    lda #NPC_EXPL_COLOR
    sta level_renderer.sprite_color + NPC_SPRITE_NO,x

    lda #EXPLODE_ANIMATION_SPEED
    sta object.animation.frame_length + NPC_SPRITE_NO,x
    sta object.animation.timer + NPC_SPRITE_NO,x

    lda #EXPLOSION_FRAMES
    sta object.animation.animation_length + NPC_SPRITE_NO,x

    lda #1
    sta object.sprite.enabled + NPC_SPRITE_NO,x

    lda #0
    sta object.sprite.enabled + NPC_SHADOW_SPRITE_NO,x
    sta object.animation.frame + NPC_SPRITE_NO,x
    sta object.animation.loop + NPC_SPRITE_NO,x

    lda #<explode_animation
    sta object.animation.ptr_lo + NPC_SPRITE_NO,x
    lda #>explode_animation
    sta object.animation.ptr_hi + NPC_SPRITE_NO,x
    rts
}


update_npc_hit:
{
    lda player_fire
    beq !+

    ldx npc_index
    lda npc_is_alive,x
    beq !+

    // Compare heights first
    ldy npc_h_index
    lda npc_h,y
    adc #7 // Add some slack in height comparison
    cmp player_h
    bcc !+
    sec
    sbc #9
    cmp player_h
    bcs !+

    clc
    lda npc_player_fire_x
    adc #24
    sta npc_temp
    lda npc_player_fire_x+1
    adc #0
    sta npc_temp+1
    cmp16x_mem(object.x.lo.npc, object.x.hi.npc, npc_temp)
    bcs !+

    clc
    lda object.x.lo.npc,x
    adc #24
    sta npc_temp
    lda object.x.hi.npc,x
    adc #0
    sta npc_temp+1

    cmp16mem(npc_temp, npc_player_fire_x)
    bcc !+
    {
        dec npc_hitpoints,x
        bne !+
        lda #0
        sta npc_is_alive,x
        jsr explode
        rts
    !:
        lda #HIT_DISPLAY_FRAMES
        sta npc_hit_display_timer,x

    }
!:
    rts
}

update_npc:
{
    ldx npc_index

    // First set correct sprite color
    lda npc_is_alive,x
    bne !+
    lda #NPC_EXPL_COLOR
    jmp !update_movement+
!:
    lda npc_hit_display_timer,x
    beq !+
    dec npc_hit_display_timer,x
    beq !+
    lda #NPC_HIT_COLOR
    jmp !update_movement+
!:
    lda #NPC_COLOR

!update_movement:
    sta level_renderer.sprite_color + NPC_SPRITE_NO,x

    //lda npc_is_alive,x
    //sta npc_enabled,x

    lda npc_sequence_pos_scale,x
    clc
    adc #1
    and #7  // Takes too much memory to change position every frame
    bne !+
    inc npc_sequence_pos,x
    lda #0
!:
    sta npc_sequence_pos_scale,x
    lda npc_sequence_pos,x
    tay

    // Update and store x-position of NPC which is unaffected by height
    clc
    lda npc_movement_x_lo,y
    adc object.x.lo.npc,x
    sta object.x.lo.npc,x
    lda npc_movement_x_hi,y
    adc object.x.hi.npc,x
    sta object.x.hi.npc,x

    // Update and store NPC shadow y-position as it's not affected by height
    clc
    lda npc_movement_y_lo,y
    adc object.y.lo.npc_shadow1,x
    sta object.y.lo.npc_shadow1,x
    lda npc_movement_y_hi,y
    adc object.y.hi.npc_shadow1,x
    sta object.y.hi.npc_shadow1,x

    // Update y position of NPC based on shadow y position and height
    ldy npc_h_index
    lda npc_h,y
    tay

    clc
    lda height_to_world,y
    adc object.y.lo.npc_shadow1,x
    sta object.y.lo.npc,x
    lda #0
    adc object.y.hi.npc_shadow1,x
    sta object.y.hi.npc,x

    // Finally fix shadow X-position
    clc
    lda object.x.lo.npc,x
    ldy npc_h_index
    adc npc_h,y
    sta object.x.lo.npc_shadow1,x
    lda object.x.hi.npc,x
    adc #0
    sta object.x.hi.npc_shadow1,x

    rts
}

next_npc:
    .byte 0
next_npc_sprite:
    .byte 0

npc_trigger_x_coord_lo:
    .fill NPCS_ON_SCREEN,0
npc_trigger_x_coord_hi:
    .fill NPCS_ON_SCREEN,0
npc_hitpoints:
    .fill NPCS_ON_SCREEN,0
npc_is_alive:
    .fill NPCS_ON_SCREEN,0
npc_hit_display_timer:
    .fill NPCS_ON_SCREEN,0

npc_trigger:
    .fill NUMBER_OF_NPCS, [i*10+4, i*10+9] // 41*6+9 = 255
npc_move_func_lo:
    .fill NUMBER_OF_NPCS, <update_npc
npc_move_func_hi:
    .fill NUMBER_OF_NPCS, >update_npc

npc_movement_x_lo:
    .fill 64,<getMoveX(i)
npc_movement_x_hi:
    .fill 64,>getMoveX(i)
npc_movement_y_lo:
    .fill 64,<getMoveY(i)
npc_movement_y_hi:
    .fill 64,>getMoveY(i)
npc_h:
    .fill 256,round(8+7*sin(toRadians(i*360/256)))

heli_animation:
    .byte npc_sprite/64, npc_sprite/64+1
heli_animation_end:

heli_shadow_animation:
    .byte npc_shadow_sprite/64, npc_shadow_sprite/64+1
heli_shadow_animation_end:

explode_animation:
    .fill EXPLOSION_FRAMES,explosion_sprite/64+i
explode_animation_end:

.segment DATA
npc_index:
    .byte 0
npc_sequence_pos_scale:
    .byte 0
    .byte 0
npc_sequence_pos:
    .byte 0
    .byte 0
npc_player_fire_x:
    .word 0
npc_temp:
    .word 0
npc_h_index:
    .byte 0
npc_enabled:
    .byte 0,0
player_fire:
    .byte 0
}

.function getMoveX(i) {
    .return abs(i-32)/28+1
}

.function getMoveY(i) {
    .return 16-i/2
}