unit Coin;

interface

type
  TCoin = record
    x, y: Integer;
    w, h: Integer;
    vx, vy: Integer;
    Active: Integer;
    Hits: Integer;
    Shake, ShakeX, ShakeY: Integer;
  end;

procedure DrawCoin(var Coin: TCoin);


implementation

uses
  al5primitives,
  Global;

procedure DrawCoin(var Coin: TCoin);
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

  if Coin.vx = 0 then
  begin
    if Coin.vy > 0 then
    begin
      x1 := Coin.x;
      x2 := Coin.x + Coin.w;
      x3 := Coin.x + Coin.w div 2;

      y1 := Coin.y;
      y2 := Coin.y;
      y3 := Coin.y - Coin.vy*LEN;
    end
    else if Coin.vy < 0 then
    begin
      x1 := Coin.x;
      x2 := Coin.x + Coin.w;
      x3 := Coin.x + Coin.w div 2;

      y1 := Coin.y + Coin.h;
      y2 := Coin.y + Coin.h;
      y3 := Coin.y + Coin.h - Coin.vy*LEN;
    end
  end
  else if Coin.vy = 0 then
  begin
    if Coin.vx > 0 then
    begin
      x1 := Coin.x;
      x2 := Coin.x;
      x3 := Coin.x - Coin.vx*LEN;

      y1 := Coin.y;
      y2 := Coin.y + Coin.h;
      y3 := Coin.y + Coin.h div 2;
    end
    else if Coin.vx < 0 then
    begin
      x1 := Coin.x + Coin.w;
      x2 := Coin.x + Coin.w;
      x3 := Coin.x + Coin.w - Coin.vx*LEN;

      y1 := Coin.y;
      y2 := Coin.y + Coin.h;
      y3 := Coin.y + Coin.h div 2;
    end
  end
  else if Coin.vy > 0 then
  begin
    if Coin.vx > 0 then
    begin
      x1 := Coin.x;
      x2 := Coin.x + Coin.w;
      x3 := Coin.x - Coin.vx*LEN;

      y1 := Coin.y + Coin.h;
      y2 := Coin.y;
      y3 := Coin.y - Coin.vy*LEN;
    end
    else if Coin.vx < 0 then
    begin
      x1 := Coin.x;
      x2 := Coin.x + Coin.w;
      x3 := Coin.x + Coin.w - Coin.vx*LEN;

      y1 := Coin.y;
      y2 := Coin.y + Coin.h;
      y3 := Coin.y - Coin.vy*LEN;
    end;
  end
  else if Coin.vy < 0 then
  begin
    if Coin.vx > 0 then
    begin
      x1 := Coin.x;
      x2 := Coin.x + Coin.w;
      x3 := Coin.x - Coin.vx*LEN;

      y1 := Coin.y;
      y2 := Coin.y + Coin.h;
      y3 := Coin.y + Coin.h - Coin.vy*LEN;
    end
    else if Coin.vx < 0 then
    begin
      x1 := Coin.x;
      x2 := Coin.x + Coin.w;
      x3 := Coin.x + Coin.w - Coin.vx*LEN;

      y1 := Coin.y + Coin.h;
      y2 := Coin.y;
      y3 := Coin.y + Coin.h - Coin.vy*LEN;
    end;
  end;

  if Coin.Hits > 1 then
  begin
    al_draw_filled_triangle(
      (x1+Coin.ShakeX)*RatioX, (y1+Coin.ShakeY)*RatioY,
      (x2+Coin.ShakeX)*RatioX, (y2+Coin.ShakeY)*RatioY,
      (x3+Coin.ShakeX)*RatioX, (y3+Coin.ShakeY)*RatioY, HardCoinShadeColor);

    if Coin.Active > 30 then
      al_draw_filled_rectangle(
        (Coin.x+Coin.ShakeX)*RatioX, (Coin.y+Coin.ShakeY)*RatioY,
        (Coin.x+Coin.w+Coin.ShakeX)*RatioX, (Coin.y+Coin.h+Coin.ShakeY)*RatioY,
        HardCoinColor)
    else
      al_draw_filled_rectangle(
        (Coin.x+Coin.ShakeX)*RatioX, (Coin.y+Coin.ShakeY)*RatioY,
        (Coin.x+Coin.w+Coin.ShakeX)*RatioX, (Coin.y+Coin.h+Coin.ShakeY)*RatioY,
        HardCoinShadeColor);
  end
  else
  begin
    al_draw_filled_triangle(
      (x1+Coin.ShakeX)*RatioX, (y1+Coin.ShakeY)*RatioY,
      (x2+Coin.ShakeX)*RatioX, (y2+Coin.ShakeY)*RatioY,
      (x3+Coin.ShakeX)*RatioX, (y3+Coin.ShakeY)*RatioY, CoinShadeColor);

    if Coin.Active > 30 then
      al_draw_filled_rectangle(
        (Coin.x+Coin.ShakeX)*RatioX, (Coin.y+Coin.ShakeY)*RatioY,
        (Coin.x+Coin.w+Coin.ShakeX)*RatioX, (Coin.y+Coin.h+Coin.ShakeY)*RatioY,
        CoinColor)
    else
      al_draw_filled_rectangle(
        (Coin.x+Coin.ShakeX)*RatioX, (Coin.y+Coin.ShakeY)*RatioY,
        (Coin.x+Coin.w+Coin.ShakeX)*RatioX, (Coin.y+Coin.h+Coin.ShakeY)*RatioY,
        CoinShadeColor);
  end;
end;

end.
