unit Player;

interface

uses
  al5primitives,
  Allegro5;

type
  TPlayer = record
    x, y: Integer;
    w, h: Integer;
    vx, vy: Integer;
    Color, ShadeColor: ALLEGRO_COLOR;
    Shake, ShakeX, ShakeY: Integer;
  end;

var
  RatioX, RatioY: Single;

procedure DrawPlayer(var Player: TPlayer);
  

implementation

procedure DrawPlayer(var Player: TPlayer);
var
  x1, y1: Integer;
  x2, y2: Integer;
  x3, y3: Integer;
const
  LEN = 10;
begin
  x1 := 0;
  x2 := 0;
  x3 := 0;

  y1 := 0;
  y2 := 0;
  y3 := 0;

  if Player.vx = 0 then
  begin
    if Player.vy > 0 then
    begin
      x1 := Player.x;
      x2 := Player.x + Player.w;
      x3 := Player.x + Player.w div 2;

      y1 := Player.y;
      y2 := Player.y;
      y3 := Player.y - Player.vy*LEN;
    end
    else if Player.vy < 0 then
    begin
      x1 := Player.x;
      x2 := Player.x + Player.w;
      x3 := Player.x + Player.w div 2;

      y1 := Player.y + Player.h;
      y2 := Player.y + Player.h;
      y3 := Player.y + Player.h - Player.vy*LEN;
    end
  end
  else if Player.vy = 0 then
  begin
    if Player.vx > 0 then
    begin
      x1 := Player.x;
      x2 := Player.x;
      x3 := Player.x - Player.vx*LEN;

      y1 := Player.y;
      y2 := Player.y + Player.h;
      y3 := Player.y + Player.h div 2;
    end
    else if Player.vx < 0 then
    begin
      x1 := Player.x + Player.w;
      x2 := Player.x + Player.w;
      x3 := Player.x + Player.w - Player.vx*LEN;

      y1 := Player.y;
      y2 := Player.y + Player.h;
      y3 := Player.y + Player.h div 2;
    end
  end
  else if Player.vy > 0 then
  begin
    if Player.vx > 0 then
    begin
      x1 := Player.x;
      x2 := Player.x + Player.w;
      x3 := Player.x - Player.vx*LEN;

      y1 := Player.y + Player.h;
      y2 := Player.y;
      y3 := Player.y - Player.vy*LEN;
    end
    else if Player.vx < 0 then
    begin
      x1 := Player.x;
      x2 := Player.x + Player.w;
      x3 := Player.x + Player.w - Player.vx*LEN;

      y1 := Player.y;
      y2 := Player.y + Player.h;
      y3 := Player.y - Player.vy*LEN;
    end;
  end
  else if Player.vy < 0 then
  begin
    if Player.vx > 0 then
    begin
      x1 := Player.x;
      x2 := Player.x + Player.w;
      x3 := Player.x - Player.vx*LEN;

      y1 := Player.y;
      y2 := Player.y + Player.h;
      y3 := Player.y + Player.h - Player.vy*LEN;
    end
    else if Player.vx < 0 then
    begin
      x1 := Player.x;
      x2 := Player.x + Player.w;
      x3 := Player.x + Player.w - Player.vx*LEN;

      y1 := Player.y + Player.h;
      y2 := Player.y;
      y3 := Player.y + Player.h - Player.vy*LEN;
    end;
  end;

  al_draw_filled_triangle(
    (x1+Player.ShakeX) * RatioX, (y1+Player.ShakeY) * RatioY,
    (x2+Player.ShakeX) * RatioX, (y2+Player.ShakeY) * RatioY,
    (x3+Player.ShakeX) * RatioX, (y3+Player.ShakeY) * RatioY, Player.ShadeColor);
  al_draw_filled_rectangle(
    (Player.x+Player.ShakeX) * RatioX, (Player.y+Player.ShakeY) * RatioY,
    (Player.x+Player.w+Player.ShakeX) * RatioX, (Player.y+Player.h+Player.ShakeY) * RatioY,
    Player.Color);
end;
end.
