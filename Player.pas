unit Player;

interface

uses
  Allegro5;

type
  TPlayer = record
    x, y: Integer;
    w, h: Integer;
    vx, vy: Integer;
    Color, ShadeColor: ALLEGRO_COLOR;
    Shake, ShakeX, ShakeY: Integer;
  end;
  
implementation

end.
