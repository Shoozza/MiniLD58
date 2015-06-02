all: 32bit

32bit:
	@fpc MiniLD58.dpr -B -l- -MObjFPC -FUobj -FEbin -Fulib/allegro-pas5/lib -dMONOLITH -XM_al_mangled_main

64bit:
	@fpc MiniLD58.dpr -B -l- -MObjFPC -FUobj -FEbin -Fulib/allegro-pas5/lib -dMONOLITH -XM_al_mangled_main -Px86_64

delphi:
	@DCC32 MiniLD58.dpr  -l-  -Nobj  -Ebin  -Ulib/allegro-pas5/lib -dMONOLITH -CC

clean:
	@rm -f *.o \
	       *.~* \
	       *.ppu \
	       *.dcu \
	       *.exe \
	       bin/*.exe \
	       obj/*.o \
	       obj/*.a \
	       obj/*.dcu \
	       obj/*.ppu

try: all run

run:
	@bin/MiniLD58
