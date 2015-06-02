unit GameOptions;

interface

procedure Options;


implementation

uses
  SysUtils,
  Allegro5,
  al5primitives,
  al5audio,
  al5font,
  Global,
  GameSettings,
  GameMenu;

const
  MAX_OPTIONS = 4;
  OptionsText: Array[0..MAX_OPTIONS] of string =
  (
    'Resolution: ', 'Fullscreen: ', 'Vsync: ', 'Sfx Volume: ', 'Save'
  );
var
  IsOptionsInited: Boolean;
  OptionsIndex: Integer;
  OptionsSettings: TSettings;
  OptionsTextFull: Array[0..MAX_OPTIONS] of string;

procedure InitOptions;
begin
  OptionsSettings := Settings;
  OptionsIndex := 0;

  OptionsTextFull[0] := OptionsText[0] +
    IntToStr(OptionsSettings.Width) + 'x' + IntToStr(OptionsSettings.Height);
  OptionsTextFull[1] := OptionsText[1] + BoolToStr(OptionsSettings.Mode <> 0, 'On', 'Off');
  OptionsTextFull[2] := OptionsText[2] + BoolToStr(OptionsSettings.Vsync <> 0, 'On', 'Off');
  OptionsTextFull[3] := OptionsText[3] + IntToStr(OptionsSettings.SfxVolumeNum);
  OptionsTextFull[4] := OptionsText[4];
end;

procedure DrawOptions;
var
  I, Position, PositionDefault: Integer;
begin
  al_clear_to_color(al_map_rgb(255, 255, 255));
  al_draw_text(MenuFont, al_map_rgb(77, 77, 77),
    Settings.Width div 2, Settings.Height div 40 * 4,
    ALLEGRO_ALIGN_CENTRE, 'Options');

  Position := 12 + OptionsIndex * 4;
  PositionDefault := 12;

  for I := 0 to MAX_OPTIONS do
  begin
    if OptionsIndex = I then
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
        ALLEGRO_ALIGN_CENTRE, OptionsTextFull[I]);
    end
    else
    begin
      al_draw_text(MenuFont, al_map_rgb(77, 77, 77),
        Settings.Width div 2, Settings.Height div 40 * (PositionDefault + 4 * I),
        ALLEGRO_ALIGN_CENTRE, OptionsTextFull[I]);
    end;
  end;

  al_flip_display;
end;

procedure Options;
var
  IsOptionsRunning, ShouldDraw: Boolean;
  Event: ALLEGRO_EVENT;
begin
  if not IsOptionsInited then
  begin
    InitOptions;
    IsOptionsInited := True;
  end;

  ShouldDraw := False;
  IsOptionsRunning := True;
  while IsOptionsRunning do
  begin
    if (ShouldDraw) and (al_is_event_queue_empty(Queue)) then
    begin
      DrawOptions;
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
                OptionsIndex := (OptionsIndex + 1) mod 5;
                al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0,
                  ALLEGRO_PLAYMODE_ONCE, nil);
              end;
            ALLEGRO_KEY_W, ALLEGRO_KEY_UP:
              begin
                OptionsIndex := (OptionsIndex + 4) mod 5;
                al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0,
                  ALLEGRO_PLAYMODE_ONCE, nil);
              end;
            ALLEGRO_KEY_D, ALLEGRO_KEY_RIGHT:
              begin
                if OptionsIndex = 0 then
                begin
                  al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0,
                    ALLEGRO_PLAYMODE_ONCE, nil);
                  if OptionsSettings.Width = 1920 then
                  begin
                    OptionsSettings.Width := 1280;
                    OptionsSettings.Height := 720;
                  end
                  else
                  begin
                    OptionsSettings.Width := 1920;
                    OptionsSettings.Height := 1080;
                  end;
                  OptionsTextFull[0] := OptionsText[0] +
                    IntToStr(OptionsSettings.Width) + 'x' + IntToStr(OptionsSettings.Height);
                end
                else if OptionsIndex = 1 then
                begin
                  al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0,
                    ALLEGRO_PLAYMODE_ONCE, nil);
                  OptionsSettings.Mode:= (OptionsSettings.Mode + 1) mod 2;
                  OptionsTextFull[1] := OptionsText[1] + BoolToStr(OptionsSettings.Mode <> 0, 'On', 'Off');
                end
                else if OptionsIndex = 2 then
                begin
                  al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0,
                    ALLEGRO_PLAYMODE_ONCE, nil);
                  OptionsSettings.Vsync := (OptionsSettings.Vsync + 1) mod 2;
                  OptionsTextFull[2] := OptionsText[2] + BoolToStr(OptionsSettings.Vsync <> 0, 'On', 'Off');
                end
                else if OptionsIndex = 3 then
                begin
                  Inc(OptionsSettings.SfxVolumeNum, 10);
                  if OptionsSettings.SfxVolumeNum > 100 then
                  begin
                    OptionsSettings.SfxVolumeNum := 100;
                  end;
                  OptionsSettings.SfxVolume := OptionsSettings.SfxVolumeNum / 100;
                  al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0,
                    ALLEGRO_PLAYMODE_ONCE, nil);
                  OptionsTextFull[3] := OptionsText[3] + IntToStr(OptionsSettings.SfxVolumeNum);
                end
                else if OptionsIndex = 4 then
                begin
                end;
              end;
            ALLEGRO_KEY_A, ALLEGRO_KEY_LEFT:
              begin
                if OptionsIndex = 0 then
                begin
                  al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0,
                    ALLEGRO_PLAYMODE_ONCE, nil);
                  if OptionsSettings.Width = 1920 then
                  begin
                    OptionsSettings.Width := 1280;
                    OptionsSettings.Height := 720;
                  end
                  else
                  begin
                    OptionsSettings.Width := 1920;
                    OptionsSettings.Height := 1080;
                  end;
                  OptionsTextFull[0] := OptionsText[0] +
                    IntToStr(OptionsSettings.Width) + 'x' + IntToStr(OptionsSettings.Height);
                end
                else if OptionsIndex = 1 then
                begin
                  al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0,
                    ALLEGRO_PLAYMODE_ONCE, nil);
                  OptionsSettings.Mode := (OptionsSettings.Mode + 1) mod 2;
                  OptionsTextFull[1] := OptionsText[1] + BoolToStr(OptionsSettings.Mode <> 0, 'On', 'Off');
                end
                else if OptionsIndex = 2 then
                begin
                  al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0,
                    ALLEGRO_PLAYMODE_ONCE, nil);
                  OptionsSettings.Vsync := (OptionsSettings.Vsync + 1) mod 2;
                  OptionsTextFull[2] := OptionsText[2] + BoolToStr(OptionsSettings.Vsync <> 0, 'On', 'Off');
                end
                else if OptionsIndex = 3 then
                begin
                  Dec(OptionsSettings.SfxVolumeNum, 10);
                  if OptionsSettings.SfxVolumeNum < 0 then
                  begin
                    OptionsSettings.SfxVolumeNum := 0;
                  end;
                  OptionsSettings.SfxVolume := OptionsSettings.SfxVolumeNum / 100;

                  al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0,
                    ALLEGRO_PLAYMODE_ONCE, nil);
                  OptionsTextFull[3] := OptionsText[3] + IntToStr(OptionsSettings.SfxVolumeNum);
                end
                else if OptionsIndex = 4 then
                begin
                end;
              end;
            ALLEGRO_KEY_ENTER, ALLEGRO_KEY_SPACE:
              begin
                if OptionsIndex = 4 then
                begin
                  al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0,
                    ALLEGRO_PLAYMODE_ONCE, nil);
                  if (Settings.Vsync <> OptionsSettings.Vsync) or
                     (Settings.Mode <> OptionsSettings.Mode) or
                     (Settings.Width <> OptionsSettings.Width) then
                  begin
                    al_destroy_font(MenuFont);
                    al_destroy_font(Font);
                    al_destroy_display(Display);
                    if OptionsSettings.Mode = 0 then
                      al_set_new_display_flags(ALLEGRO_WINDOWED)
                    else if OptionsSettings.Mode = 1 then
                      al_set_new_display_flags(ALLEGRO_FULLSCREEN);

                    al_set_new_display_option(ALLEGRO_VSYNC, OptionsSettings.Vsync, ALLEGRO_REQUIRE);

                    Display := al_create_display(OptionsSettings.Width, OptionsSettings.Height);
                    if Display = nil then
                      WriteLn('Error: Cannot create window');

                    al_set_window_title(Display, 'MiniLD58 - Theme: "Pong" - Balldr');

                    RatioX := OptionsSettings.Width / INTERNAL_WIDTH;
                    RatioY := OptionsSettings.Height / INTERNAL_HEIGHT;

                    Font := al_load_font(GetCurrentDir + PathDelim + 'font.ttf', Trunc(504.0 * RatioX), 0);
                    if Font = nil then
                      WriteLn('Error: loading ttf font');

                    MenuFont := al_load_font(GetCurrentDir + PathDelim + 'font.ttf', Trunc(126 * RatioX), 0);
                    if MenuFont = nil then
                      WriteLn('Error: loading menu ttf font');
                  end;

                  Settings := OptionsSettings;
                  IsOptionsRunning := False;
                end;
              end;
            ALLEGRO_KEY_ESCAPE:
              IsOptionsRunning := False;
            end;
          end;
        end;
  end;
end;

end.
