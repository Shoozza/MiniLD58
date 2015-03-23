all:
	@fpc MiniLD58.dpr -XM__al_mangled_main -B -l- -FUobj -FEbin -Fulib/allegro-pas5/lib -dMONOLITH

delphi:
	@DCC32 MiniLD58.dpr -l- -Nobj -Ebin -CC -Ulib/allegro-pas5/lib -dMONOLITH

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
