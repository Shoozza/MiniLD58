unit Main;

interface

procedure Run;

implementation

uses
  Allegro5;

var
  Display: ALLEGRO_DISPLAYptr;

procedure Init;
begin
  al_init;
  Display := al_create_display(1920, 1080);
  al_clear_to_color(al_map_rgb(0, 0, 0));
  al_flip_display;
end;

procedure Loop;
var
  IsRunning: boolean;
begin
  IsRunning := True;

  al_rest(1);
  While IsRunning do
  begin
    IsRunning := False;
  end;
end;

procedure Clean;
begin
end;

procedure Run;
begin
  Writeln('Start');

  Init;
  Loop;
  Clean;

  Writeln('End');
end;

end.
