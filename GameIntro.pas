unit GameIntro;

interface

procedure Intro;


implementation

uses
  SysUtils,
  Allegro5,
  Global;

var
  IntroImage: ALLEGRO_BITMAPptr;
const
  IntroDelay = 60;

procedure LoadIntro;
begin
  IntroImage := al_load_bitmap(GetCurrentDir + PathDelim + 'intro.png');
  if IntroImage = nil then
    Writeln('Error: cannot load intro.png');
end;

procedure DrawIntro(Counter: Integer);
var
  C, R: Single;
begin
  al_clear_to_color(al_map_rgb(164, 164, 164));
  C := Counter / IntroDelay;
  R := Settings.Width / al_get_bitmap_width(IntroImage);
  al_draw_tinted_scaled_bitmap(IntroImage,
    al_map_rgba_f(1.0*C, 1.0*C, 1.0*C, C),
    0, 0, al_get_bitmap_width(IntroImage), al_get_bitmap_height(IntroImage),
    (Settings.Width   - 0.5*R*al_get_bitmap_width(IntroImage))  / 2.0,
    (Settings.Height  - 0.45*R*al_get_bitmap_height(IntroImage)) / 2.0,
    0.4*R*al_get_bitmap_width(IntroImage),
    0.4*R*al_get_bitmap_height(IntroImage), 0);
  al_flip_display;
end;

procedure Intro;
var
  Fade, ShowIntro: Integer;
  ShouldDraw: Boolean;
  Event: ALLEGRO_EVENT;
begin
  Fade := 165;
  ShowIntro := IntroDelay;
  ShouldDraw := False;

  LoadIntro;

  while ShowIntro > -30 do
  begin
    if (ShouldDraw) and (al_is_event_queue_empty(Queue)) then
    begin
      if ShowIntro > 0 then
      begin
        DrawIntro(ShowIntro);
      end
      else
      begin
        Inc(Fade, 3);
        al_clear_to_color(al_map_rgb(Fade, Fade, Fade));
        al_flip_display;
      end;
      Dec(ShowIntro);
    end;

    al_wait_for_event(Queue, Event);

    case Event._type of
      ALLEGRO_EVENT_DISPLAY_CLOSE:
        Halt;
      ALLEGRO_EVENT_TIMER:
        ShouldDraw := True;
      ALLEGRO_EVENT_KEY_DOWN:
        ShowIntro := -30;
    end;
  end;
end;

end.
