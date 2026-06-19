dummy="-D mod1=0 -D mod2=0 -D mod3=0 -D mod4=0"
modules="-D pack_loader=0 -D pack_BTRANS=0 -D pack_VTRANS=0"
modules+=" -D pack_tape=0 -D pack_kick=0 -D pack_debug=0"
pyz80 $dummy $modules --obj=build/main --exportfile=build/main.sym -s offset main.asm
pyz80 --importfile=build/main.sym --obj=build/debug --mapfile=build/debug.map __debug.asm
pyz80 --importfile=build/main.sym --obj=build/tape --mapfile=build/tape.map __tape.asm
pyz80 --importfile=build/main.sym --obj=build/loader --mapfile=build/loader.map __loader.asm
pyz80 --importfile=build/main.sym --obj=build/btrans --mapfile=build/btrans.map -s padding __btrans.asm
pyz80 --importfile=build/main.sym --obj=build/vtrans --mapfile=build/vtrans.map __vtrans.asm
pyz80 --importfile=build/main.sym --obj=build/kick --mapfile=build/kick.map __kick.asm
pyz80 --obj=build/udg src/udg.asm
zx0 -f build/debug
zx0 -f build/tape
zx0 -f build/loader
zx0 -f build/btrans
zx0 -f build/vtrans
zx0 -f build/kick
zx0 -f build/udg
pyz80 --obj=build/modules --mapfile=build/modules.map --importfile=build/main.sym --exportfile=build/modules.sym modules.asm
pyz80 --obj=build/font src/font.asm
mod1=$(stat -f%z build/debug)
mod2=$(stat -f%z build/loader)
mod3=$(stat -f%z build/btrans)
mod4=$(stat -f%z build/vtrans)
mod5=$(stat -f%z build/kick)
mod6=$(stat -f%z build/tape)
defs="-D mod1=$mod1 -D mod2=$mod2 -D mod3=$mod3"
defs+=" -D mod4=$mod4 -D mod5=$mod5 -D mod6=$mod6"
params="--importfile=build/modules.sym --nozip --mapfile=build/main.map"
includes="-I build/samdos2 -I build/modules -I build/font"
pyz80 $defs $params $includes -o transam.mgt main.asm
echo "=========================="
echo Debug. file is $(stat -f%z build/debug) bytes
echo Loader file is $(stat -f%z build/loader) bytes
echo Tape.. file is $(stat -f%z build/tape) bytes
echo BTRANS file is $(stat -f%z build/btrans) bytes
echo VTRANS file is $(stat -f%z build/vtrans) bytes
echo kick.. file is $(stat -f%z build/kick) bytes
echo "=========================="
echo Main: $(stat -f%z build/main.bin) bytes
echo Modules: $(stat -f%z build/modules) bytes
echo Font: $(stat -f%z build/font) bytes
echo "=========================="