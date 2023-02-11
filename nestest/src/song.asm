#importonce

pulse1:
    .for (var i = 0; i < 2; i++) {
        .byte 29,nn,nn,nn,oo,nn,33,nn
        .byte oo,nn,35,nn,oo,nn,38,oo
        .byte 36,nn,nn,nn,oo,nn,33,nn
        .byte oo,nn,29,nn,oo,nn,26,oo

        .byte 23,nn,nn,nn,oo,nn,24,nn
        .byte nn,nn,nn,nn,nn,nn,nn,oo
        .byte nn,nn,nn,nn,nn,nn,nn,nn
        .byte nn,nn,nn,nn,nn,nn,nn,nn

        .byte 29,nn,nn,nn,oo,nn,33,nn
        .byte oo,nn,35,nn,oo,nn,38,oo
        .byte 36,nn,nn,nn,oo,nn,33,nn
        .byte oo,nn,29,nn,oo,nn,26,oo

        .byte 23,oo,23,oo,23,nn,24,nn
        .byte nn,nn,nn,nn,nn,nn,nn,oo
        .byte nn,nn,nn,nn,nn,nn,nn,nn
        .byte nn,nn,nn,nn,nn,nn,nn,nn

    }
pulse2:
    .for (var i = 0; i < 4; i++) {
        .byte 23,oo,35,oo,35,oo,21,nn
        .byte oo,nn,17,nn,oo,nn,21,nn
        .byte 23,nn,nn,nn,nn,oo,24,nn
        .byte oo,nn,26,nn,oo,nn,24,nn

        .byte 17,oo,41,oo,41,oo,29,oo
        .byte nn,nn,29,oo,41,oo,41,oo
        .byte 50,48,47,45,48,47,45,43
        .byte 41,43,45,48,47,43,38,35
    }

tria:
    .for (var i = 0; i < 16; i++) {
        .byte 29,nn,oo,oo,oo,oo,23,nn
        .byte oo,nn,nn,nn,nn,nn,nn,nn
    }
noise:
    .fill 32,[nn,nn,nn,nn,50,nn,oo,nn]