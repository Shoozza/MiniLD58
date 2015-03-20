all:
	@fpc MiniLD58.dpr -l- -FUobj -FEbin

delphi:
	@DCC32 MiniLD58.dpr -l- -Nobj -Ebin -CC

clean:
	@rm -f *.o
	@rm -f *.~*
	@rm -f *.ppu
	@rm -f *.dcu
	@rm -f *.exe
	@rm -f bin/*.*
	@rm -f obj/*.*
	@touch bin/.gitkeep
	@touch obj/.gitkeep

try: all run

run:
	@bin/MiniLD58
