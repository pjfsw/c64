#/bin/sh

PRG=`echo $1 | sed s/\.asm/.prg/`
PRG=`echo $PRG | sed s/src/target/`
java -jar /Users/johanfr/priv/KickAssembler/KickAss.jar -odir ../target $1 && open -a /Applications/vice-sdl2-3.4-r37694/x64sc.app $PRG

