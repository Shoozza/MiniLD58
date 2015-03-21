unit Main;

interface

procedure Run;

implementation

uses
  SysUtils,
  IniFiles,
  Allegro5,
  al5primitives,
  al5audio,
  al5acodec;

type
  TPlayer = record
    x, y: Integer;
    w, h: Integer;
    vx, vy: Integer;
  end;

  TPad = record
    x, y: Integer;
    w, h: Integer;
    vx, vy: Integer;
  end;

  TSettings = record
    Width, Height: Integer;
  end;

var
  Display: ALLEGRO_DISPLAYptr;
  Queue: ALLEGRO_EVENT_QUEUEptr;
  Timer: ALLEGRO_TIMERptr;
  Player: TPlayer;
  Pad1, Pad2: TPad;
  Settings: TSettings;
  Ini: TMemIniFile;
  BackgroundColor, BackgroundShadeColor,
    PlayerColor, PlayerShadeColor,
    LeftPadColor, LeftPadShadeColor,
    RightPadColor, RightPadShadeColor: ALLEGRO_COLOR;
  WallSound, LeftPadSound, RightPadSound,
    LostSound, SpawnSound, PointSound: ALLEGRO_SAMPLEptr;
  StartUpDelay: Integer;
  Shake: Integer;
  ShakeX, ShakeY: Single;
  KeyS, KeyW: Boolean;

procedure Init;
begin
  SetCurrentDir(ExtractFilePath(ParamStr(0)));
  Ini := TMemIniFile.Create('config.ini');

  Settings.Width := Ini.ReadInteger('GENERAL', 'Screen_Width', 1920);
  Settings.Height := Ini.ReadInteger('GENERAL', 'Screen_Height', 1080);

  al_init;
  Display := al_create_display(Settings.Width, Settings.Height);

  Randomize;
  al_install_keyboard;
  al_init_acodec_addon;
  if not al_install_audio then
    Writeln('error: al_install_audio');
  if not al_reserve_samples(16) then
    Writeln('error: al_reserve_samples');

  Timer := al_create_timer(1.0 / 60.0);
  Queue := al_create_event_queue;

  al_init_primitives_addon;

  al_register_event_source(Queue, al_get_display_event_source(display));
  al_register_event_source(Queue, al_get_timer_event_source(Timer));
  al_register_event_source(Queue, al_get_keyboard_event_source);
  al_start_timer(Timer);

  WallSound := al_load_sample(GetCurrentDir + '\wall.wav');
  if WallSound = nil then
    Writeln('Error: loading ' + GetCurrentDir + '\wall.wav');

  LeftPadSound := al_load_sample(GetCurrentDir + '\left.wav');
  if leftPadSound = nil then
    Writeln('Error: loading ' + GetCurrentDir + '\left.wav');

  RightPadSound := al_load_sample(GetCurrentDir + '\right.wav');
  if RightPadSound = nil then
    Writeln('Error: loading ' + GetCurrentDir + '\right.wav');

  LostSound := al_load_sample(GetCurrentDir + '\lost.wav');
  if LostSound = nil then
    Writeln('Error: loading ' + GetCurrentDir + '\lost.wav');

  SpawnSound := al_load_sample(GetCurrentDir + '\spawn.wav');
  if SpawnSound = nil then
    Writeln('Error: loading ' + GetCurrentDir + '\spawn.wav');

  PointSound := al_load_sample(GetCurrentDir + '\point.wav');
  if PointSound = nil then
    Writeln('Error: loading ' + GetCurrentDir + '\point.wav');

  BackgroundColor := al_map_rgb(255, 255, 255);
  BackgroundShadeColor := al_map_rgb(235, 235, 235);
  PlayerColor := al_map_rgb(248, 180, 93);
  PlayerShadeColor := al_map_rgb(255, 222, 178);
  LeftPadColor := al_map_rgb(51, 139, 209);
  LeftPadShadeColor := al_map_rgb(199, 219, 246);
  RightPadColor := al_map_rgb(230,  98, 98);
  RightPadShadeColor := al_map_rgb(251, 185, 185);

  KeyW := False;
  KeyS := False;

  Shake := 0;
  ShakeX := 0;
  ShakeY := 0;

  Player.x := -100;
  Player.y := 100;
  Player.w := 80;
  Player.h := Player.w;
  Player.vx := 0;
  Player.vy := 0;

  Pad1.x := 0;
  Pad1.y := 0;
  Pad1.w := 60;
  Pad1.h := 180;
  Pad1.vx := 0;
  Pad1.vy := 4;

  Pad2.x := Settings.Width-60;
  Pad2.y := Settings.Height - 180;
  Pad2.w := 60;
  Pad2.h := 180;
  Pad2.vx := 0;
  Pad2.vy := -4;
end;

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

  al_draw_filled_triangle(x1+ShakeX, y1+ShakeY, x2+ShakeX, y2+ShakeY, x3+ShakeX, y3+ShakeY, PlayerShadeColor);
  al_draw_filled_rectangle(Player.x+ShakeX, Player.y+ShakeY, Player.x+Player.w+ShakeX, Player.y+Player.h+ShakeY, PlayerColor);
end;

procedure DrawPad(var Pad: TPad; var PadColor: ALLEGRO_COLOR; var PadShadeColor: ALLEGRO_COLOR);
begin
  al_draw_filled_rectangle(Pad.x, Pad.y, Pad.x+Pad.w, Pad.y+Pad.h, PadColor);
  if Pad.vy > 0 then
    al_draw_filled_rectangle(Pad.x, Pad.y-Pad.vy*10, Pad.x+Pad.w, Pad.y, PadShadeColor)
  else if Pad.vy < 0 then
    al_draw_filled_rectangle(Pad.x, Pad.y+Pad.h, Pad.x+Pad.w, Pad.y+Pad.h-Pad.vy*10, PadShadeColor);
end;

procedure Draw;
const
  SIZE = 60;
begin
  al_clear_to_color(BackgroundColor);

  if Shake > 0 then
  begin
    Dec(Shake);
    ShakeX := random(35);
    ShakeY := random(35);
  end
  else if Shake = 0 then
  begin
    Dec(Shake);
    ShakeX := 0;
    ShakeY := 0;
  end;

  al_draw_filled_rectangle(Settings.Width/2-SIZE, 0, Settings.Width/2+SIZE,
    Settings.Height, BackgroundShadeColor);

  DrawPlayer(Player);
  DrawPad(Pad1, LeftPadColor, LeftPadShadeColor);
  DrawPad(Pad2, RightPadColor, RightPadShadeColor);

  al_flip_display;
end;

procedure Update;
begin
  // move
  Player.x := Player.x + Player.vx;
  Player.y := Player.y + Player.vy;

  Pad1.x := Pad1.x + Pad1.vx;
  Pad1.y := Pad1.y + Pad1.vy;

  Pad2.x := Pad2.x + Pad2.vx;
  Pad2.y := Pad2.y + Pad2.vy;

  // bots
  if Pad1.y+Pad1.h >= Settings.Height then
  begin
    Pad1.vy := -Pad1.vy;
    Pad1.y := Settings.Height-Pad1.h;
  end
  else if Pad1.y <= 0 then
  begin
    Pad1.vy := -Pad1.vy;
    Pad1.y := 0;
  end;

  if Pad2.y+Pad2.h >= Settings.Height then
  begin
    Pad2.vy := -Pad2.vy;
    Pad2.y := Settings.Height-Pad2.h;
  end
  else if Pad2.y <= 0 then
  begin
    Pad2.vy := -Pad2.vy;
    Pad2.y := 0;
  end;

  if Player.y+Player.h >= Settings.Height then
  begin
    Shake := 10;
    Player.vy := -Player.vy;
    Player.y := Settings.Height-Player.h;
    al_play_sample(WallSound, 1.0, 0.0, 1.0, ALLEGRO_PLAYMODE_ONCE, nil)
  end
  else if Player.y <= 0 then
  begin
    Shake := 10;
    Player.vy := -Player.vy;
    Player.y := 0;
    al_play_sample(WallSound, 1.0, 0.0, 1.0, ALLEGRO_PLAYMODE_ONCE, nil)
  end;

  // collide
  if (Player.x <= Pad1.x+Pad1.w) and (Player.x >= 0) and
    ((Player.y+Player.h >= Pad1.y) and (Player.y+Player.h <= Pad1.y+Pad1.h) or
    (Player.y >= Pad1.y) and (Player.y <= Pad1.y+Pad1.h)) then
  begin
    Shake := 5;
    Player.vx := -Player.vx;
    Player.x := Pad1.x+Pad1.w;
    Pad1.vy := Pad1.vy + 1;
    al_play_sample(LeftPadSound, 1.0, -0.75, 1.0, ALLEGRO_PLAYMODE_ONCE, nil)
  end
  else if (Player.x+Player.w >= Pad2.x) and (Player.x <= Pad2.x+Pad2.w) and
    ((Player.y+Player.h >= Pad2.y) and (Player.y+Player.h <= Pad2.y+Pad2.h) or
    (Player.y >= Pad2.y) and (Player.y <= Pad2.y+Pad2.h)) then
  begin
    Shake := 5;
    Player.vx := -Player.vx;
    Player.x := Pad2.x-Player.w;
    Pad2.vy := Pad2.vy - 1;
    al_play_sample(RightPadSound, 1.0, 0.75, 1.0, ALLEGRO_PLAYMODE_ONCE, nil)
  end;

  // check for lost game
  if (Player.x+Player.w < 0) or (Player.x > Settings.Width) then
  begin
    // lost
    if player.x < Settings.Width then
      al_play_sample(LostSound, 1.0, -0.75, 1.0, ALLEGRO_PLAYMODE_ONCE, nil)
    else
      al_play_sample(LostSound, 1.0,  0.75, 1.0, ALLEGRO_PLAYMODE_ONCE, nil);

    Player.x := Settings.Width div 2 - Player.w div 2;
    Player.y := Settings.Height div 2 - Player.h div 2;
    Player.vx := 0;
    Player.vy := 0;
    while Player.vy = 0 do
      Player.vy := (Random(3)-1) * 10;
    StartUpDelay := 100;
  end;

  if Player.vx = 0 then
  begin
    Dec(StartUpDelay);
    if StartUpDelay = 0 then
    begin
      while Player.vx = 0 do
        Player.vx := (Random(3)-1) * 10;
      StartUpDelay := 100;
      al_play_sample(SpawnSound, 1.0, 0.0, 1.0, ALLEGRO_PLAYMODE_ONCE, nil)
    end;
  end;
end;

procedure HandleInput;
begin
  if KeyW then
  begin
    if Player.vy > 0 then
      Player.vy := Trunc(Player.vy/1.5)
    else if Player.vy < 0 then
      Player.vy := Trunc(Player.vy*1.5)
    else
      Player.vy := -3;
  end;

  if KeyS then
  begin
    if Player.vy > 0 then
      Player.vy := Trunc(Player.vy*1.5)
    else if Player.vy < 0 then
      Player.vy := Trunc(Player.vy/1.5)
    else
      Player.vy := 3;
  end;

end;

procedure Loop;
var
  IsRunning, ShouldDraw: boolean;
  Event: ALLEGRO_EVENT;
begin
  IsRunning := True;
  ShouldDraw := True;

  while IsRunning do
  begin
    if (ShouldDraw) and (al_is_event_queue_empty(Queue)) then
    begin
      HandleInput;
      Update;
      Draw;
      ShouldDraw := False;
    end;

    al_wait_for_event(Queue, Event);

    case Event._type of
      ALLEGRO_EVENT_DISPLAY_CLOSE:
        IsRunning := False;
      ALLEGRO_EVENT_TIMER:
        ShouldDraw := True;
      ALLEGRO_EVENT_KEY_DOWN:
        begin
          case Event.Keyboard.KeyCode of
            ALLEGRO_KEY_S:
              KeyS := True;
            ALLEGRO_KEY_W:
              KeyW := True;
            ALLEGRO_KEY_D:
              if Player.vx = 0 then
              begin
                Player.vx := 10;
                al_play_sample(SpawnSound, 1.0, 0.0, 1.0, ALLEGRO_PLAYMODE_ONCE, nil)
              end;
            ALLEGRO_KEY_A:
              if Player.vx = 0 then
              begin
                Player.vx := -10;
                al_play_sample(SpawnSound, 1.0, 0.0, 1.0, ALLEGRO_PLAYMODE_ONCE, nil)
              end;
            ALLEGRO_KEY_ESCAPE:
              IsRunning := False;
          end;
        end;
      ALLEGRO_EVENT_KEY_UP:
        begin
          case Event.Keyboard.KeyCode of
            ALLEGRO_KEY_S:
              KeyS := False;
            ALLEGRO_KEY_W:
              KeyW := False;
          end;
        end;
    end;
  end;
end;

procedure Clean;
begin
  Ini.WriteInteger('GENERAL', 'Screen_Width', Settings.Width);
  Ini.WriteInteger('GENERAL', 'Screen_Height', Settings.Height);
  Ini.Free;
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
