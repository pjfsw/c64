#importonce
    // T
    .fill 1, [$7f,$ff,$fc]
    .fill 20,[$00,$ff,$00]

    //E
    .align 64
    .fill 1, [$7f,$ff,$fe]
    .fill 8, [$7f,$00,$00]
    .fill 1, [$7f,$ff,$fc]
    .fill 10,[$7f,$00,$00]
    .fill 1, [$7f,$ff,$fe]

    // S
    .align 64
    .fill 1, [$3f,$ff,$fc]
    .fill 1, [$7f,$00,$fe]
    .fill 7, [$7f,$00,$00]
    .fill 1, [$3f,$ff,$fc]
    .fill 9, [$00,$00,$fe]
    .fill 1, [$7f,$00,$fe]
    .fill 1, [$3f,$ff,$fc]


    //O
    .align 64
    .fill 1, [$3f,$ff,$fc]
    .fill 19,[$7f,$00,$fe]
    .fill 1, [$3f,$ff,$fc]


    //!
    .align 64
    .fill 18, [$00,$ff,$00]
    .fill 1,[$00,$00,$00]
    .fill 2, [$00,$ff,$00]

