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
  al5acodec,
  al5font,
  al5ttf,
  al5Image;

type
  TPlayer = record
    x, y: Integer;
    w, h: Integer;
    vx, vy: Integer;
    Color, ShadeColor: ALLEGRO_COLOR;
    Shake, ShakeX, ShakeY: Integer;
  end;

  TPad = record
    x, y: Integer;
    w, h: Integer;
    vx, vy: Integer;
  end;

  TCoin = record
    x, y: Integer;
    w, h: Integer;
    vx, vy: Integer;
    Active: Integer;
    Hits: Integer;
    Shake, ShakeX, ShakeY: Integer;
  end;

  TSettings = record
    Width, Height, Mode, Vsync: Integer;
    SfxVolumeNum: Integer;
    SfxVolume: Single;
  end;

const
  MAX_COINS = 2;
  INTERNAL_HEIGHT = 1080;
  INTERNAL_WIDTH  = 1920;

var
  Display: ALLEGRO_DISPLAYptr;
  Queue: ALLEGRO_EVENT_QUEUEptr;
  Timer: ALLEGRO_TIMERptr;
  Player1, Player2: TPlayer;
  Pad1, Pad2: TPad;
  Coins: Array [1..MAX_COINS] of TCoin;
  Settings: TSettings;
  Ini: TMemIniFile;
  BackgroundColor, BackgroundShadeColor,
    CoinColor, CoinShadeColor,
    HardCoinColor, HardCoinShadeColor,
    LeftPadColor, LeftPadShadeColor,
    RightPadColor, RightPadShadeColor: ALLEGRO_COLOR;
  MenuColor, MenuShadeColor: Array [0..4] of ALLEGRO_COLOR;
  WallSound, LeftPadSound, RightPadSound,
    LostSound, SpawnSound, PointSound: ALLEGRO_SAMPLEptr;
  StartUpDelay1, StartUpDelay2: Integer;
  KeyS, KeyW: Boolean;
  KeyUp, KeyDown: Boolean;
  Score: Integer;
  BestScore: Integer;
  Font: ALLEGRO_FONTptr;
  Pause: Boolean;
  RatioX, RatioY: Single;

procedure Init;
var
  I: Integer;
begin
  SetCurrentDir(ExtractFilePath(ParamStr(0)));
  Ini := TMemIniFile.Create('config.ini');

  Settings.Width := Ini.ReadInteger('GENERAL', 'Screen_Width', 1920);
  Settings.Height := Ini.ReadInteger('GENERAL', 'Screen_Height', 1080);
  Settings.Mode := Ini.ReadInteger('GENERAL', 'Fullscreen', 0);
  Settings.Vsync := Ini.ReadInteger('GENERAL', 'VSync', 0);
  Settings.SfxVolumeNum := Ini.ReadInteger('GENERAL', 'Sfx_Volume', 50);
  Settings.SfxVolume := Settings.SfxVolumeNum / 100;

  al_init;
  if Settings.Mode = 0 then
    al_set_new_display_flags(ALLEGRO_WINDOWED)
  else if Settings.Mode = 1 then
    al_set_new_display_flags(ALLEGRO_FULLSCREEN);

  al_set_new_display_option(ALLEGRO_VSYNC, Settings.Vsync, ALLEGRO_REQUIRE);

  Display := al_create_display(Settings.Width, Settings.Height);
  if Display = nil then
    WriteLn('Error: Cannot create window');

  al_clear_to_color(al_map_rgb(164, 164, 164));
  al_flip_display;
  al_set_window_title(Display, 'MiniLD58 - Theme: "Pong" - Balldr');

  RatioX := Settings.Width / INTERNAL_WIDTH;
  RatioY := Settings.Height / INTERNAL_HEIGHT;

  Randomize;

  al_init_image_addon;
  al_init_font_addon;
  al_init_ttf_addon;
  al_init_primitives_addon;

  al_init_acodec_addon;
  if not al_install_audio then
    Writeln('error: al_install_audio');
  if not al_reserve_samples(16) then
    Writeln('error: al_reserve_samples');

  al_install_keyboard;

  Timer := al_create_timer(1.0 / 60.0);
  Queue := al_create_event_queue;

  al_register_event_source(Queue, al_get_display_event_source(display));
  al_register_event_source(Queue, al_get_timer_event_source(Timer));
  al_register_event_source(Queue, al_get_keyboard_event_source);
  al_start_timer(Timer);

  WallSound := al_load_sample(GetCurrentDir + PathDelim + 'wall.wav');
  if WallSound = nil then
    Writeln('Error: loading ' + GetCurrentDir + PathDelim + 'wall.wav');

  LeftPadSound := al_load_sample(GetCurrentDir + PathDelim + 'left.wav');
  if leftPadSound = nil then
    Writeln('Error: loading ' + GetCurrentDir + PathDelim + 'left.wav');

  RightPadSound := al_load_sample(GetCurrentDir + PathDelim + 'right.wav');
  if RightPadSound = nil then
    Writeln('Error: loading ' + GetCurrentDir + PathDelim + 'right.wav');

  LostSound := al_load_sample(GetCurrentDir + PathDelim + 'lost.wav');
  if LostSound = nil then
    Writeln('Error: loading ' + GetCurrentDir + PathDelim + 'lost.wav');

  SpawnSound := al_load_sample(GetCurrentDir + PathDelim + 'spawn.wav');
  if SpawnSound = nil then
    Writeln('Error: loading ' + GetCurrentDir + PathDelim + 'spawn.wav');

  PointSound := al_load_sample(GetCurrentDir + PathDelim + 'point.wav');
  if PointSound = nil then
    Writeln('Error: loading ' + GetCurrentDir + PathDelim + 'point.wav');

  Font := al_load_font(GetCurrentDir + PathDelim + 'font.ttf', Trunc(504.0 * RatioX), 0);
  if Font = nil then
    WriteLn('Error: loading ttf font');

  Player1.Shake := 0;
  Player1.ShakeX := 0;
  Player1.ShakeY := 0;

  Player1.x := -100;
  Player1.y := 100;
  Player1.w := 80;
  Player1.h := Player1.w;
  Player1.vx := 0;
  Player1.vy := 0;

  Player1.Color := al_map_rgb(248, 180, 93);
  Player1.ShadeColor := al_map_rgb(255, 222, 178);

  Player2 := Player1;

  Player2.Color := al_map_rgb(202, 185, 152);
  Player2.ShadeColor := al_map_rgb(226, 217, 199);

  BackgroundColor := al_map_rgb(255, 255, 255);
  BackgroundShadeColor := al_map_rgb(235, 235, 235);
  LeftPadColor := al_map_rgb(51, 139, 209);
  LeftPadShadeColor := al_map_rgb(199, 219, 246);
  RightPadColor := al_map_rgb(230,  98, 98);
  RightPadShadeColor := al_map_rgb(251, 185, 185);
  CoinColor := al_map_rgb(175, 223, 142);
  CoinShadeColor := al_map_rgb(213, 228, 202);
  HardCoinColor := al_map_rgb(184, 145, 223);
  HardCoinShadeColor := al_map_rgb(215, 202, 227);

  MenuColor[0] := LeftPadColor;
  MenuColor[1] := RightPadColor;
  MenuColor[2] := Player1.Color;
  MenuColor[3] := CoinColor;
  MenuColor[4] := HardCoinColor;

  MenuShadeColor[0] := LeftPadShadeColor;
  MenuShadeColor[1] := RightPadShadeColor;
  MenuShadeColor[2] := Player1.ShadeColor;
  MenuShadeColor[3] := CoinShadeColor;
  MenuShadeColor[4] := HardCoinShadeColor;

  for I := 1 to MAX_COINS do
  begin
    Coins[I].Active := 0;
    Coins[I].w := 80;
    Coins[I].h := 80;
    Coins[I].Shake := 0;
  end;

  BestScore := 0;
  Score := 0;

  KeyW := False;
  KeyS := False;
  KeyUp := False;
  KeyDown := False;
  Pause := False;

  Pad1.x := 0;
  Pad1.y := 0;
  Pad1.w := 60;
  Pad1.h := 180;
  Pad1.vx := 0;
  Pad1.vy := 4;

  Pad2 := Pad1;

  Pad2.x := INTERNAL_WIDTH - 60;
  Pad2.y := INTERNAL_HEIGHT - 180;
  Pad2.vy := -Pad2.vy;
end;

procedure DrawScore;
begin
  al_draw_text(Font, al_map_rgb(230, 230, 230),
    Settings.Width div 4, Settings.Height div 4,
    ALLEGRO_ALIGN_CENTRE, IntToStr(Score));
  al_draw_text(Font, al_map_rgb(230, 230, 230),
    Settings.Width div 4 * 3, Settings.Height div 4,
    ALLEGRO_ALIGN_CENTRE, IntToStr(BestScore));
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

  al_draw_filled_triangle(
    (x1+Player.ShakeX) * RatioX, (y1+Player.ShakeY) * RatioY,
    (x2+Player.ShakeX) * RatioX, (y2+Player.ShakeY) * RatioY,
    (x3+Player.ShakeX) * RatioX, (y3+Player.ShakeY) * RatioY, Player.ShadeColor);
  al_draw_filled_rectangle(
    (Player.x+Player.ShakeX) * RatioX, (Player.y+Player.ShakeY) * RatioY,
    (Player.x+Player.w+Player.ShakeX) * RatioX, (Player.y+Player.h+Player.ShakeY) * RatioY,
    Player.Color);
end;

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

procedure DrawPad(var Pad: TPad;
  var PadColor: ALLEGRO_COLOR; var PadShadeColor: ALLEGRO_COLOR);
begin
  al_draw_filled_rectangle(
    Pad.x*RatioX, Pad.y*RatioY,
    (Pad.x+Pad.w)*RatioX, (Pad.y+Pad.h)*RatioY, PadColor);
  if Pad.vy > 0 then
    al_draw_filled_rectangle(
      Pad.x*RatioX, (Pad.y-Pad.vy*10)*RatioY, (Pad.x+Pad.w)*RatioX, Pad.y*RatioY, PadShadeColor)
  else if Pad.vy < 0 then
    al_draw_filled_rectangle(
      Pad.x*RatioX, (Pad.y+Pad.h)*RatioY, (Pad.x+Pad.w)*RatioX, (Pad.y+Pad.h-Pad.vy*10)*RatioY, PadShadeColor);
end;

procedure Draw;
const
  SIZE = 60;
var
  I: Integer;
begin
  al_clear_to_color(BackgroundColor);
  DrawScore;

  if Player1.Shake > 0 then
  begin
    Dec(Player1.Shake);
    Player1.ShakeX := random(35);
    Player1.ShakeY := random(35);
  end
  else if Player1.Shake = 0 then
  begin
    Dec(Player1.Shake);
    Player1.ShakeX := 0;
    Player1.ShakeY := 0;
  end;

  if Player2.Shake > 0 then
  begin
    Dec(Player2.Shake);
    Player2.ShakeX := random(35);
    Player2.ShakeY := random(35);
  end
  else if Player2.Shake = 0 then
  begin
    Dec(Player2.Shake);
    Player2.ShakeX := 0;
    Player2.ShakeY := 0;
  end;

  al_draw_filled_rectangle(Settings.Width/2-SIZE*RatioX, 0,
    Settings.Width/2+SIZE*RatioX, Settings.Height, BackgroundShadeColor);

  DrawPad(Pad1, LeftPadColor, LeftPadShadeColor);
  DrawPad(Pad2, RightPadColor, RightPadShadeColor);

  for I := 1 to MAX_COINS do
  begin
    if Coins[I].Active <> 0 then
    begin
      if Coins[I].Shake > 0 then
      begin
        Dec(Coins[I].Shake);
        Coins[I].ShakeX := random(35);
        Coins[I].ShakeY := random(35);
      end
      else if Coins[I].Shake = 0 then
      begin
        Dec(Coins[I].Shake);
        Coins[I].ShakeX := 0;
        Coins[I].ShakeY := 0;
      end;
      DrawCoin(Coins[I]);
    end;
  end;
  DrawPlayer(Player1);
  DrawPlayer(Player2);

  if Pause then
  begin
    al_draw_filled_rectangle(0, 0,
      Settings.Width, Settings.Height,
      al_map_rgba(0, 0, 0, 40));
    al_draw_filled_rectangle(Settings.Width / 20 * RatioX,
      Settings.Height / 20 * RatioY,
      Settings.Width - Settings.Width / 20 * RatioX,
      Settings.Height - Settings.Height / 20 * RatioX,
      al_map_rgba(0, 0, 0, 40));
  end;

  al_flip_display;
end;

procedure Update;
var
  I: Integer;
  N: Integer;
const
  SIZE = 60;
begin
  if Pause then
    Exit;

  N := random(MAX_COINS) + 1;
  if Coins[N].Active = 0 then
  begin
    Coins[N].Hits := random(2) + 1;
    Coins[N].Active := (random(40) + 300) * Coins[N].Hits;


    // spawn points on the other side of the field
    if (Player1.x + Player1.w) < (INTERNAL_WIDTH div 2 - SIZE) then
      Coins[N].x := random(INTERNAL_WIDTH div 2 - SIZE*2) + SIZE + INTERNAL_WIDTH div 2
    else if (Player1.x) > (INTERNAL_WIDTH div 2 + SIZE) then
      Coins[N].x := random(INTERNAL_WIDTH div 2 - SIZE*2) + SIZE
    else
    begin
      Coins[N].x := random(INTERNAL_WIDTH - SIZE * 4);
      if Coins[N].x > (INTERNAL_WIDTH - SIZE * 4) div 2 then
        Coins[N].x := Coins[N].x + SIZE*3
      else
        Coins[N].x := Coins[N].x + SIZE;
    end;

    Coins[N].y := random(INTERNAL_HEIGHT div 2) + INTERNAL_HEIGHT div 4;
    Coins[N].vx := random(3) - 2;
    Coins[N].vy := random(9) - 5;
    Coins[N].Shake := 0;
  end;

  // move
  Player1.x := Player1.x + Player1.vx;
  Player1.y := Player1.y + Player1.vy;

  Player2.x := Player2.x + Player2.vx;
  Player2.y := Player2.y + Player2.vy;

  Pad1.x := Pad1.x + Pad1.vx;
  Pad1.y := Pad1.y + Pad1.vy;

  Pad2.x := Pad2.x + Pad2.vx;
  Pad2.y := Pad2.y + Pad2.vy;

  for I := 1 to MAX_COINS do
  begin
    if Coins[I].Active > 0 then
    begin
      Coins[I].x := Coins[I].x + Coins[I].vx;
      Coins[I].y := Coins[I].y + Coins[I].vy;

      Dec(Coins[I].Active);
      if (Player1.x+Player1.w >= Coins[I].x) and
        (Player1.x <= Coins[I].x+Coins[i].w) and
        (Player1.y+Player1.h >= Coins[I].y) and
        (Player1.y <= Coins[I].y+Coins[I].h) then
      begin
        if Coins[I].Hits = 1 then
        begin
          Coins[I].Active := 0;
          Inc(Score);
          al_play_sample(PointSound, Settings.SfxVolume, 0.0, 1.0,
            ALLEGRO_PLAYMODE_ONCE, nil);
        end
        else
        begin
          Dec(Coins[I].Hits);
          Inc(Score);
          al_play_sample(LeftPadSound, Settings.SfxVolume, 0.0, 1.0,
            ALLEGRO_PLAYMODE_ONCE, nil);
          Player1.vx := -Player1.vx;
          Player1.vy := -Player1.vy;
        end;
      end;

      if (Player2.x+Player2.w >= Coins[I].x) and
        (Player2.x <= Coins[I].x+Coins[i].w) and
        (Player2.y+Player2.h >= Coins[I].y) and
        (Player2.y <= Coins[I].y+Coins[I].h) then
      begin
        if Coins[I].Hits = 1 then
        begin
          Coins[I].Active := 0;
          Inc(Score);
          al_play_sample(PointSound, Settings.SfxVolume, 0.0, 1.0,
            ALLEGRO_PLAYMODE_ONCE, nil);
        end
        else
        begin
          Dec(Coins[I].Hits);
          Inc(Score);
          al_play_sample(LeftPadSound, Settings.SfxVolume, 0.0, 1.0,
            ALLEGRO_PLAYMODE_ONCE, nil);
          Player2.vx := -Player2.vx;
          Player2.vy := -Player2.vy;
        end;
      end;

      if Coins[I].Active > 0 then
      begin
        if Coins[I].y+Coins[I].h >= INTERNAL_HEIGHT then
        begin
          Coins[I].Shake := 20;
          Coins[I].vy := -Coins[I].vy;
          Coins[I].y := INTERNAL_HEIGHT-Coins[I].h;
        end
        else if Coins[I].y <= 0 then
        begin
          Coins[I].Shake := 20;
          Coins[I].vy := -Coins[I].vy;
          Coins[I].y := 0;
        end;
      end;
    end;
  end;

  // bots
  if Pad1.y+Pad1.h >= INTERNAL_HEIGHT then
  begin
    Pad1.vy := -Pad1.vy;
    Pad1.y := INTERNAL_HEIGHT-Pad1.h;
  end
  else if Pad1.y <= 0 then
  begin
    Pad1.vy := -Pad1.vy;
    Pad1.y := 0;
  end;

  if Pad2.y+Pad2.h >= INTERNAL_HEIGHT then
  begin
    Pad2.vy := -Pad2.vy;
    Pad2.y := INTERNAL_HEIGHT-Pad2.h;
  end
  else if Pad2.y <= 0 then
  begin
    Pad2.vy := -Pad2.vy;
    Pad2.y := 0;
  end;

  if Player1.y+Player1.h >= INTERNAL_HEIGHT then
  begin
    Player1.Shake := 10;
    Player1.vy := -Player1.vy;
    Player1.y := INTERNAL_HEIGHT-Player1.h;
    al_play_sample(WallSound, Settings.SfxVolume, 0.0, 1.0, ALLEGRO_PLAYMODE_ONCE, nil)
  end
  else if Player1.y <= 0 then
  begin
    Player1.Shake := 10;
    Player1.vy := -Player1.vy;
    Player1.y := 0;
    al_play_sample(WallSound, Settings.SfxVolume, 0.0, 1.0, ALLEGRO_PLAYMODE_ONCE, nil)
  end;

  if Player2.y+Player2.h >= INTERNAL_HEIGHT then
  begin
    Player2.Shake := 10;
    Player2.vy := -Player2.vy;
    Player2.y := INTERNAL_HEIGHT-Player2.h;
    al_play_sample(WallSound, Settings.SfxVolume, 0.0, 1.0, ALLEGRO_PLAYMODE_ONCE, nil)
  end
  else if Player2.y <= 0 then
  begin
    Player2.Shake := 10;
    Player2.vy := -Player2.vy;
    Player2.y := 0;
    al_play_sample(WallSound, Settings.SfxVolume, 0.0, 1.0, ALLEGRO_PLAYMODE_ONCE, nil)
  end;

  // collide
  if (Player1.x <= Pad1.x+Pad1.w) and (Player1.x >= 0) and
    ((Player1.y+Player1.h >= Pad1.y) and (Player1.y+Player1.h <= Pad1.y+Pad1.h) or
    (Player1.y >= Pad1.y) and (Player1.y <= Pad1.y+Pad1.h)) then
  begin
    Player1.Shake := 5;
    Player1.vx := -Player1.vx;
    Player1.x := Pad1.x+Pad1.w;
    Pad1.vy := Pad1.vy + 1;
    Inc(Score);
    al_play_sample(LeftPadSound, Settings.SfxVolume, -0.75, 1.0, ALLEGRO_PLAYMODE_ONCE, nil)
  end
  else if (Player1.x+Player1.w >= Pad2.x) and (Player1.x <= Pad2.x+Pad2.w) and
    ((Player1.y+Player1.h >= Pad2.y) and (Player1.y+Player1.h <= Pad2.y+Pad2.h) or
    (Player1.y >= Pad2.y) and (Player1.y <= Pad2.y+Pad2.h)) then
  begin
    Player1.Shake := 5;
    Player1.vx := -Player1.vx;
    Player1.x := Pad2.x-Player1.w;
    Pad2.vy := Pad2.vy - 1;
    Inc(Score);
    al_play_sample(RightPadSound, Settings.SfxVolume, 0.75, 1.0, ALLEGRO_PLAYMODE_ONCE, nil)
  end;

  if (Player2.x <= Pad1.x+Pad1.w) and (Player2.x >= 0) and
    ((Player2.y+Player2.h >= Pad1.y) and (Player2.y+Player2.h <= Pad1.y+Pad1.h) or
    (Player2.y >= Pad1.y) and (Player2.y <= Pad1.y+Pad1.h)) then
  begin
    Player2.Shake := 5;
    Player2.vx := -Player2.vx;
    Player2.x := Pad1.x+Pad1.w;
    Pad1.vy := Pad1.vy + 1;
    Inc(Score);
    al_play_sample(LeftPadSound, Settings.SfxVolume, -0.75, 1.0, ALLEGRO_PLAYMODE_ONCE, nil)
  end
  else if (Player2.x+Player2.w >= Pad2.x) and (Player2.x <= Pad2.x+Pad2.w) and
    ((Player2.y+Player2.h >= Pad2.y) and (Player2.y+Player2.h <= Pad2.y+Pad2.h) or
    (Player2.y >= Pad2.y) and (Player2.y <= Pad2.y+Pad2.h)) then
  begin
    Player2.Shake := 5;
    Player2.vx := -Player2.vx;
    Player2.x := Pad2.x-Player2.w;
    Pad2.vy := Pad2.vy - 1;
    Inc(Score);
    al_play_sample(RightPadSound, Settings.SfxVolume, 0.75, 1.0, ALLEGRO_PLAYMODE_ONCE, nil)
  end;

  // check for lost game
  if (Player1.x+Player1.w < 0) or (Player1.x > INTERNAL_WIDTH) then
  begin
    // lost
    if Player1.x < INTERNAL_WIDTH then
      al_play_sample(LostSound, Settings.SfxVolume, -0.75, 1.0, ALLEGRO_PLAYMODE_ONCE, nil)
    else
      al_play_sample(LostSound, Settings.SfxVolume,  0.75, 1.0, ALLEGRO_PLAYMODE_ONCE, nil);

    Player1.x := INTERNAL_WIDTH div 2 - Player1.w div 2;
    Player1.y := INTERNAL_HEIGHT div 4 - Player1.h div 2;
    Player1.vx := 0;
    Player1.vy := 0;
    while Player1.vy = 0 do
      Player1.vy := (Random(3)-1) * 10;
    StartUpDelay1 := 100;
    if Score > BestScore then
      BestScore := Score;
    Score := 0;
  end;

  if Player1.vx = 0 then
  begin
    Dec(StartUpDelay1);
    if StartUpDelay1 = 0 then
    begin
      while Player1.vx = 0 do
        Player1.vx := (Random(3)-1) * 10;
      StartUpDelay1 := 100;
      al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0, ALLEGRO_PLAYMODE_ONCE, nil)
    end;
  end;

  if (Player2.x+Player2.w < 0) or (Player2.x > INTERNAL_WIDTH) then
  begin
    // lost
    if Player2.x < INTERNAL_WIDTH then
      al_play_sample(LostSound, Settings.SfxVolume, -0.75, 1.0, ALLEGRO_PLAYMODE_ONCE, nil)
    else
      al_play_sample(LostSound, Settings.SfxVolume,  0.75, 1.0, ALLEGRO_PLAYMODE_ONCE, nil);

    Player2.x := INTERNAL_WIDTH div 2 - Player2.w div 2;
    Player2.y := INTERNAL_HEIGHT div 4*3 - Player2.h div 2;
    Player2.vx := 0;
    Player2.vy := 0;
    while Player2.vy = 0 do
      Player2.vy := (Random(3)-1) * 10;
    StartUpDelay2 := 100;
    if Score > BestScore then
      BestScore := Score;
    Score := 0;
  end;

  if Player2.vx = 0 then
  begin
    Dec(StartUpDelay2);
    if StartUpDelay2 = 0 then
    begin
      while Player2.vx = 0 do
        Player2.vx := (Random(3)-1) * 10;
      StartUpDelay2 := 100;
      al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0, ALLEGRO_PLAYMODE_ONCE, nil)
    end;
  end;

  if (Player1.x+Player1.w >= Player2.x) and
    (Player1.x <= Player2.x+Player2.w) and
    (Player1.y+Player1.h >= Player2.y) and
    (Player1.y <= Player2.y+Player2.h) then
  begin
    Player1.vx := -Player1.vx;
    Player2.vx := -Player2.vx;
    Player1.vy := -Player1.vy;
    Player2.vy := -Player2.vy;

    while (Player1.x+Player1.w >= Player2.x) and
      (Player1.x <= Player2.x+Player2.w) and
      (Player1.y+Player1.h >= Player2.y) and
      (Player1.y <= Player2.y+Player2.h) do
    begin
      Player1.x := Player1.x + Player1.vx;
      Player2.x := Player2.x + Player2.vx;
      Player1.y := Player1.y + Player1.vy;
      Player2.y := Player2.y + Player2.vy;
    end;
  end;
end;

procedure HandleInput;
begin
  if Pause then
    Exit;

  if KeyW then
  begin
    if Player1.vy > 0 then
    begin
      if Player1.vy < 2 then
        Player1.vy := Trunc(Player1.vy/2)
      else if Player1.vy < 10 then
        Player1.vy := Trunc(Player1.vy/1.5)
      else
        Player1.vy := Trunc(Player1.vy/1.1);
    end
    else if Player1.vy < 0  then
    begin
      if Player1.vy > -2 then
        Player1.vy := Trunc(Player1.vy*2)
      else if Player1.vy > -10 then
        Player1.vy := Trunc(Player1.vy*1.5)
      else
        Player1.vy := Trunc(Player1.vy*1.1);

    end
    else
    begin
      Player1.vy := -1;
    end;
  end;

  if KeyS then
  begin
    if Player1.vy > 0 then
    begin
      if Player1.vy < 2 then
        Player1.vy := Trunc(Player1.vy*2)
      else if Player1.vy < 10 then
        Player1.vy := Trunc(Player1.vy*1.5)
      else
        Player1.vy := Trunc(Player1.vy*1.1);
    end
    else if Player1.vy < 0 then
    begin
      if Player1.vy > -2 then
        Player1.vy := Trunc(Player1.vy/2)
      else if Player1.vy > -10 then
        Player1.vy := Trunc(Player1.vy/1.5)
      else
        Player1.vy := Trunc(Player1.vy/1.1);
    end
    else
    begin
      Player1.vy := 1;
    end;
  end;

  if Player1.vy > 50 then
    Player1.vy := 50
  else if Player1.vy < -50 then
    Player1.vy := -50;

  if Player1.vx > 50 then
    Player1.vx := 50
  else if Player1.vx < -50 then
    Player1.vx := -50;

  if KeyUp then
  begin
    if Player2.vy > 0 then
    begin
      if Player2.vy < 2 then
        Player2.vy := Trunc(Player2.vy/2)
      else if Player2.vy < 10 then
        Player2.vy := Trunc(Player2.vy/1.5)
      else
        Player2.vy := Trunc(Player2.vy/1.1);
    end
    else if Player2.vy < 0  then
    begin
      if Player2.vy > -2 then
        Player2.vy := Trunc(Player2.vy*2)
      else if Player2.vy > -10 then
        Player2.vy := Trunc(Player2.vy*1.5)
      else
        Player2.vy := Trunc(Player2.vy*1.1);

    end
    else
    begin
      Player2.vy := -1;
    end;
  end;

  if KeyDown then
  begin
    if Player2.vy > 0 then
    begin
      if Player2.vy < 2 then
        Player2.vy := Trunc(Player2.vy*2)
      else if Player2.vy < 10 then
        Player2.vy := Trunc(Player2.vy*1.5)
      else
        Player2.vy := Trunc(Player2.vy*1.1);
    end
    else if Player2.vy < 0 then
    begin
      if Player2.vy > -2 then
        Player2.vy := Trunc(Player2.vy/2)
      else if Player2.vy > -10 then
        Player2.vy := Trunc(Player2.vy/1.5)
      else
        Player2.vy := Trunc(Player2.vy/1.1);
    end
    else
    begin
      Player2.vy := 1;
    end;
  end;

  if Player2.vy > 50 then
    Player2.vy := 50
  else if Player2.vy < -50 then
    Player2.vy := -50;

  if Player2.vx > 50 then
    Player2.vx := 50
  else if Player2.vx < -50 then
    Player2.vx := -50;
end;

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

procedure Loop;
var
  IsRunning, ShouldDraw: boolean;
  Event: ALLEGRO_EVENT;
begin
  IsRunning := True;
  ShouldDraw := True;

  Player1.x := -100;
  Player2.x := -100;

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
        Halt;
      ALLEGRO_EVENT_TIMER:
        ShouldDraw := True;
      ALLEGRO_EVENT_KEY_DOWN:
        begin
          case Event.Keyboard.KeyCode of
            ALLEGRO_KEY_S:
              KeyS := True;
            ALLEGRO_KEY_DOWN:
              KeyDown := True;
            ALLEGRO_KEY_W:
              KeyW := True;
            ALLEGRO_KEY_UP:
              KeyUp := True;
            ALLEGRO_KEY_D:
              if (not Pause) and (Player1.vx = 0) then
              begin
                Player1.vx := 10;
                al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0,
                  ALLEGRO_PLAYMODE_ONCE, nil)
              end;
            ALLEGRO_KEY_RIGHT:
              if (not Pause) and (Player2.vx = 0) then
              begin
                Player2.vx := 10;
                al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0,
                  ALLEGRO_PLAYMODE_ONCE, nil)
              end;
            ALLEGRO_KEY_A:
              if (not Pause) and (Player1.vx = 0) then
              begin
                Player1.vx := -10;
                al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0,
                  ALLEGRO_PLAYMODE_ONCE, nil)
              end;
            ALLEGRO_KEY_LEFT:
              if (not Pause) and (Player2.vx = 0) then
              begin
                Player2.vx := -10;
                al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0,
                  ALLEGRO_PLAYMODE_ONCE, nil)
              end;
            ALLEGRO_KEY_P:
              Pause := not Pause;

            ALLEGRO_KEY_ESCAPE:
              IsRunning := False;
          end;
        end;
      ALLEGRO_EVENT_KEY_UP:
        begin
          case Event.Keyboard.KeyCode of
            ALLEGRO_KEY_S:
              KeyS := False;
            ALLEGRO_KEY_DOWN:
              KeyDown := False;
            ALLEGRO_KEY_W:
              KeyW := False;
            ALLEGRO_KEY_UP:
              KeyUp := False;
          end;
        end;
    end;
  end;
end;

var
  IsMenuInited: Boolean;
  MenuFont: ALLEGRO_FONTptr;
  MenuIndex: Integer;
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

var
  IsOptionsInited: Boolean;
  OptionsIndex: Integer;
  OptionsSettings: TSettings;

procedure InitOptions;
begin
  OptionsSettings := Settings;
  OptionsIndex := 0;
end;

procedure DrawOptions;
begin
  al_clear_to_color(al_map_rgb(255, 255, 255));
  al_draw_text(MenuFont, al_map_rgb(77, 77, 77),
    Settings.Width div 2, Settings.Height div 40 * 4,
    ALLEGRO_ALIGN_CENTRE, 'Options');

  if OptionsIndex = 0 then
  begin
    al_draw_filled_rectangle(
      0,
      Settings.Height div 40 * 12,
      Settings.Width,
      Settings.Height div 40 * 16,
      LeftPadShadeColor);
    al_draw_filled_rectangle(
      Settings.Width div 5,
      Settings.Height div 40 * 12,
      Settings.Width - Settings.Width div 5,
      Settings.Height div 40 * 16,
      LeftPadColor);
    al_draw_text(MenuFont, al_map_rgb(255, 255, 255),
      Settings.Width div 2, Settings.Height div 40 * 12,
      ALLEGRO_ALIGN_CENTRE, 'Resolution: ' +
        IntToStr(OptionsSettings.Width) + 'x' + IntToStr(OptionsSettings.Height));
  end
  else
  begin
    al_draw_text(MenuFont, al_map_rgb(77, 77, 77),
      Settings.Width div 2, Settings.Height div 40 * 12,
      ALLEGRO_ALIGN_CENTRE, 'Resolution: ' +
        IntToStr(OptionsSettings.Width) + 'x' + IntToStr(OptionsSettings.Height));
  end;

  if OptionsIndex = 1 then
  begin
    al_draw_filled_rectangle(
      0,
      Settings.Height div 40 * 16,
      Settings.Width,
      Settings.Height div 40 * 20,
      RightPadShadeColor);
    al_draw_filled_rectangle(
      Settings.Width div 5,
      Settings.Height div 40 * 16,
      Settings.Width - Settings.Width div 5,
      Settings.Height div 40 * 20,
      RightPadColor);
    al_draw_text(MenuFont, al_map_rgb(255, 255, 255),
      Settings.Width div 2, Settings.Height div 40 * 16,
      ALLEGRO_ALIGN_CENTRE, 'Fullscreen: ' + BoolToStr(OptionsSettings.Mode <> 0, 'On', 'Off'));
  end
  else
  begin
    al_draw_text(MenuFont, al_map_rgb(77, 77, 77),
      Settings.Width div 2, Settings.Height div 40 * 16,
      ALLEGRO_ALIGN_CENTRE, 'Fullscreen: ' + BoolToStr(OptionsSettings.Mode <> 0, 'On', 'Off'));
  end;

  if OptionsIndex = 2 then
  begin
    al_draw_filled_rectangle(
      0,
      Settings.Height div 40 * 20,
      Settings.Width,
      Settings.Height div 40 * 24,
      MenuPlayer.ShadeColor);
    al_draw_filled_rectangle(
      Settings.Width div 5,
      Settings.Height div 40 * 20,
      Settings.Width - Settings.Width div 5,
      Settings.Height div 40 * 24,
      MenuPlayer.Color);
    al_draw_text(MenuFont, al_map_rgb(255, 255, 255),
      Settings.Width div 2, Settings.Height div 40 * 20,
      ALLEGRO_ALIGN_CENTRE, 'VSync: ' + BoolToStr(OptionsSettings.Vsync <> 0, 'On', 'Off'));
  end
  else
  begin
    al_draw_text(MenuFont, al_map_rgb(77, 77, 77),
      Settings.Width div 2, Settings.Height div 40 * 20,
      ALLEGRO_ALIGN_CENTRE, 'VSync: ' + BoolToStr(OptionsSettings.Vsync <> 0, 'On', 'Off'));
  end;

  if OptionsIndex = 3 then
  begin
    al_draw_filled_rectangle(
      0,
      Settings.Height div 40 * 24,
      Settings.Width,
      Settings.Height div 40 * 28,
      CoinShadeColor);
    al_draw_filled_rectangle(
      Settings.Width div 5,
      Settings.Height div 40 * 24,
      Settings.Width - Settings.Width div 5,
      Settings.Height div 40 * 28,
      CoinColor);
    al_draw_text(MenuFont, al_map_rgb(255, 255, 255),
      Settings.Width div 2, Settings.Height div 40 * 24,
      ALLEGRO_ALIGN_CENTRE, 'Sfx Volume: ' + IntToStr(OptionsSettings.SfxVolumeNum));
  end
  else
  begin
    al_draw_text(MenuFont, al_map_rgb(77, 77, 77),
      Settings.Width div 2, Settings.Height div 40 * 24,
      ALLEGRO_ALIGN_CENTRE, 'Sfx Volume: ' + IntToStr(OptionsSettings.SfxVolumeNum));
  end;

  if OptionsIndex = 4 then
  begin
    al_draw_filled_rectangle(
      0,
      Settings.Height div 40 * 28,
      Settings.Width,
      Settings.Height div 40 * 32,
      HardCoinShadeColor);
    al_draw_filled_rectangle(
      Settings.Width div 5,
      Settings.Height div 40 * 28,
      Settings.Width - Settings.Width div 5,
      Settings.Height div 40 * 32,
      HardCoinColor);
    al_draw_text(MenuFont, al_map_rgb(255, 255, 255),
      Settings.Width div 2, Settings.Height div 40 * 28,
      ALLEGRO_ALIGN_CENTRE, 'Save');
  end
  else
  begin
    al_draw_text(MenuFont, al_map_rgb(77, 77, 77),
      Settings.Width div 2, Settings.Height div 40 * 28,
      ALLEGRO_ALIGN_CENTRE, 'Save');
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
                end
                else if OptionsIndex = 1 then
                begin
                  al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0,
                    ALLEGRO_PLAYMODE_ONCE, nil);
                  OptionsSettings.Mode:= (OptionsSettings.Mode + 1) mod 2;
                end
                else if OptionsIndex = 2 then
                begin
                  al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0,
                    ALLEGRO_PLAYMODE_ONCE, nil);
                  OptionsSettings.Vsync := (OptionsSettings.Vsync + 1) mod 2
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
                end
                else if OptionsIndex = 1 then
                begin
                  al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0,
                    ALLEGRO_PLAYMODE_ONCE, nil);
                  OptionsSettings.Mode := (OptionsSettings.Mode + 1) mod 2;
                end
                else if OptionsIndex = 2 then
                begin
                  al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0,
                    ALLEGRO_PLAYMODE_ONCE, nil);
                  OptionsSettings.Vsync := (OptionsSettings.Vsync + 1) mod 2
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

procedure Clean;
begin
  Ini.WriteInteger('GENERAL', 'Screen_Width', Settings.Width);
  Ini.WriteInteger('GENERAL', 'Screen_Height', Settings.Height);
  Ini.WriteInteger('GENERAL', 'Fullscreen', Settings.Mode);
  Ini.WriteInteger('GENERAL', 'Vsync', Settings.Vsync);
  Ini.WriteInteger('GENERAL', 'Sfx_Volume', Settings.SfxVolumeNum);
  Ini.Free;
end;

procedure Run;
begin
  Writeln('Start');

  IsMenuInited := False;

  Init;
  Intro;
  repeat
    Menu;
     if MenuIndex = 0 then
       Loop
     else if MenuIndex = 1 then
       Options;
  until MenuIndex = 2;
  Clean;

  Writeln('End');
end;

end.
