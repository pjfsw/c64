#/bin/sh

PRG=`echo $1 | sed s/\.asm/.prg/`
PRG=`echo $PRG | sed s/src/target/`
java -jar /Users/johanfr/priv/KickAssembler/KickAss.jar -odir ../target $1 && open -a /Applications/vice-gtk3-3.5/x64sc.app $PRG

