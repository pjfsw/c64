BasicUpstart2(start)

*=$080e
start:
    inc $d020
    jmp start