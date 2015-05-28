unit Pad;

interface

uses
  Global,
  al5primitives,
  Allegro5;

type
  TPad = record
    x, y: Integer;
    w, h: Integer;
    vx, vy: Integer;
  end;

procedure InitPad(var Pad: TPad);
procedure DrawPad(var Pad: TPad;
  var PadColor: ALLEGRO_COLOR; var PadShadeColor: ALLEGRO_COLOR);


implementation

procedure InitPad(var Pad: TPad);
begin
  Pad.x := 0;
  Pad.y := 0;
  Pad.w := 60;
  Pad.h := 180;
  Pad.vx := 0;
  Pad.vy := 4;
end;

procedure DrawPad(var Pad: TPad;
  var PadColor: ALLEGRO_COLOR; var PadShadeColor: ALLEGRO_COLOR);
begin
  al_draw_filled_rectangle(Pad.x*RatioX, Pad.y*RatioY,
    (Pad.x+Pad.w)*RatioX, (Pad.y+Pad.h)*RatioY, PadColor);

  if Pad.vy > 0 then
    al_draw_filled_rectangle(Pad.x*RatioX, (Pad.y-Pad.vy*10)*RatioY,
      (Pad.x+Pad.w)*RatioX, Pad.y*RatioY, PadShadeColor)
  else if Pad.vy < 0 then
    al_draw_filled_rectangle(Pad.x*RatioX, (Pad.y+Pad.h)*RatioY,
      (Pad.x+Pad.w)*RatioX, (Pad.y+Pad.h-Pad.vy*10)*RatioY, PadShadeColor);
end;

end.
