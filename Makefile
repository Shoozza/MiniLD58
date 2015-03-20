all:
	@fpc MiniLD58.dpr -FUobj -FEbin

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
