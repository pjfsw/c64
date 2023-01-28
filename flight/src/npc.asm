npc: {
.segment Default

update_npc_hit:
{
    lda npc_player_fire_x+1
    cmp #$ff
    beq !+

    ldx npc_index

    // 16-bit indexed from here
    txa
    asl
    tax
    cmp16x_mem(sprite_x_coord.npc, sprite_x_coord.npc+1, npc_player_fire_x)
    bcs !+

    clc
    lda sprite_x_coord.npc,x
    adc #24
    sta npc_right_x
    lda sprite_x_coord.npc + 1,x
    adc #0
    sta npc_right_x+1

    cmp16mem(npc_right_x, npc_player_fire_x)
    bcc !+

    ldx npc_index
    inc npc_hits,x
!:
    rts
}
update_npc:
{
    // Animation stuff
    lda #npc_sprite/64
    sta level_renderer.sprite_ptr + NPC_SPRITE_NO
    sta level_renderer.sprite_ptr + NPC_SPRITE_NO + 1
    lda npc_hits
    sta level_renderer.sprite_color + NPC_SPRITE_NO
    lda npc_hits+1
    sta level_renderer.sprite_color + NPC_SPRITE_NO + 1
    ldx npc_index
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

next_npc:
    .byte 0
next_npc_sprite:
    .byte 0
npc_trigger_x_coord:
    .word 0,0
npc_hits:
    .fill 2,0


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
npc_right_x:
    .word 0
}

.function getMoveX(i) {
    .return abs(i-32)/28+1
}

.function getMoveY(i) {
    .return 16-i/2
}