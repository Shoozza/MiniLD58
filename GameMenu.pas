unit GameMenu;

interface

uses
  Allegro5,
  al5font;

var
  MenuFont: ALLEGRO_FONTptr;  // also used by options
  IsMenuInited: Boolean;
  MenuIndex: Integer;
  MenuColor, MenuShadeColor: Array [0..4] of ALLEGRO_COLOR;

procedure Menu;
procedure InitMenu;
procedure DrawMenu;


implementation

uses
  SysUtils,
  al5primitives,
  al5audio,
  Global,
  Player;

var
  MenuPlayer: TPlayer;

procedure InitMenu;
begin
  MenuFont := al_load_font(GetCurrentDir + PathDelim + 'font.ttf', Trunc(126 * RatioX), 0);
  if MenuFont = nil then
    WriteLn('Error: loading menu ttf font');
  MenuIndex := 0;

  MenuPlayer.w := Player1.w * 2;
  MenuPlayer.h := Player1.h * 2;
  MenuPlayer.x := (INTERNAL_WIDTH div 2) + Player1.w;
  MenuPlayer.y := INTERNAL_HEIGHT div 80 * 24;
  MenuPlayer.vx := 40;
  MenuPlayer.vy := 0;
  MenuPlayer.Color := Player1.Color;
  MenuPlayer.ShadeColor := Player1.ShadeColor;
end;

procedure DrawMenu;
const
  MenuText: Array[0..2] of string =
  (
    'Start Game', 'Options', 'Exit'
  );
  MAX_MENU = 2;
var
  I, Position, PositionDefault: Integer;
begin
  al_clear_to_color(al_map_rgb(255, 255, 255));

  MenuPlayer.x := (INTERNAL_WIDTH div 2) - Player1.w + 1 - random(2);
  MenuPlayer.vx := 35 + random(6);
  if MenuPlayer.vx = 41 then
    MenuPlayer.vx := 50;

  DrawPlayer(MenuPlayer);
  Position := 24 + MenuIndex * 4;
  PositionDefault := 24;

  for I := 0 to MAX_MENU do
  begin
    if MenuIndex = I then
    begin
      al_draw_filled_rectangle(
        0,
        Settings.Height div 40 * Position,
        Settings.Width,
        Settings.Height div 40 * (Position + 4),
        MenuShadeColor[I]);
      al_draw_filled_rectangle(
        Settings.Width div 5,
        Settings.Height div 40 * Position,
        Settings.Width - Settings.Width div 5,
        Settings.Height div 40 * (Position + 4),
        MenuColor[I]);
      al_draw_text(MenuFont, al_map_rgb(255, 255, 255),
        Settings.Width div 2, Settings.Height div 40 * Position,
        ALLEGRO_ALIGN_CENTRE, MenuText[I]);
    end
    else
    begin
      al_draw_text(MenuFont, al_map_rgb(77, 77, 77),
        Settings.Width div 2, Settings.Height div 40 * (PositionDefault + 4 * I),
        ALLEGRO_ALIGN_CENTRE, MenuText[I]);
    end;
  end;

  al_flip_display;
end;

procedure Menu;
var
  IsMenuRunning, ShouldDraw: Boolean;
  Event: ALLEGRO_EVENT;
begin
  if not IsMenuInited then
  begin
    InitMenu;
    IsMenuInited := True;
  end;

  IsMenuRunning := True;
  ShouldDraw := False;

  while IsMenuRunning do
  begin
    if (ShouldDraw) and (al_is_event_queue_empty(Queue)) then
    begin
      DrawMenu;
      ShouldDraw := False;
    end;

    al_wait_for_event(Queue, Event);

    case Event._type of
      ALLEGRO_EVENT_DISPLAY_CLOSE:
        Halt;
      ALLEGRO_EVENT_TIMER:
        ShouldDraw := True;
      ALLEGRO_EVENT_KEY_DOWN:
        begin
          case Event.Keyboard.KeyCode of
            ALLEGRO_KEY_S, ALLEGRO_KEY_DOWN:
              begin
                MenuIndex := (MenuIndex + 1) mod 3;
                al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0,
                  ALLEGRO_PLAYMODE_ONCE, nil);
              end;
            ALLEGRO_KEY_W, ALLEGRO_KEY_UP:
              begin
                MenuIndex := (MenuIndex + 5) mod 3;
                al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0,
                  ALLEGRO_PLAYMODE_ONCE, nil);
              end;
            ALLEGRO_KEY_D, ALLEGRO_KEY_RIGHT:
              begin
                al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0,
                  ALLEGRO_PLAYMODE_ONCE, nil);
              end;
            ALLEGRO_KEY_A, ALLEGRO_KEY_LEFT:
              begin
                al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0,
                  ALLEGRO_PLAYMODE_ONCE, nil);
              end;
            ALLEGRO_KEY_ENTER, ALLEGRO_KEY_SPACE:
              IsMenuRunning := False;
            ALLEGRO_KEY_ESCAPE:
              begin
                MenuIndex := 2;
                IsMenuRunning := False;
              end;
          end;
        end;
    end;
  end;
end;


end.
