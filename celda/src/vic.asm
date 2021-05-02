#importonce

.const VIC_BANK = $0000
.const SCREEN_MEM = VIC_BANK + $0400
.const SPRITE_PTR = SCREEN_MEM + $03f8
.const COLOR_RAM = $d800

.const SPRITE_ENABLE = $d015
.const SPRITE0_COLOR = $d027
.const SPRITE0_X = $d000
.const SPRITE0_Y = $d001
.const SPRITE_X_HI = $d010

.const JOYSTICK_PORT_2 = $dc00
.const JOYSTICK_PORT_1 = $dc01