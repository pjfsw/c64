#/bin/sh

CART=`echo $1 | sed s/\.asm/.nes/`
CART=`echo $CART | sed s/src/target/`
if [ -z ${KICKASS} ]; then
  echo "KICKASS env variable is unset.";
  exit 1
else
  echo "KICKASS env variable is set to '$KICKASS'";
fi

rm $PRG
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  java -jar $KICKASS/KickAss.jar -binfile -o $CART -odir ../target $1 && /usr/bin/fceux $CART
elif [[ "$OSTYPE" == "darwin"* ]]; then
  # Mac OSX
  java -jar $KICKASS/KickAss.jar -binfile  -o $CART -odir ../target $1 # && open -a /Applications/vice-gtk3-3.5/x64sc.app -silent -autostartprgmode 1 $PRG
else
  echo "Unsupported OS, update script"
fi
