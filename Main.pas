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
  end;

const
  MAX_COINS = 2;
  INTERNAL_HEIGHT = 1080;
  INTERNAL_WIDTH  = 1920;

var
  Display: ALLEGRO_DISPLAYptr;
  Queue: ALLEGRO_EVENT_QUEUEptr;
  Timer: ALLEGRO_TIMERptr;
  Player: TPlayer;
  Pad1, Pad2: TPad;
  Coins: Array [1..MAX_COINS] of TCoin;
  Settings: TSettings;
  Ini: TMemIniFile;
  BackgroundColor, BackgroundShadeColor,
    PlayerColor, PlayerShadeColor,
    CoinColor, CoinShadeColor,
    HardCoinColor, HardCoinShadeColor,
    LeftPadColor, LeftPadShadeColor,
    RightPadColor, RightPadShadeColor: ALLEGRO_COLOR;
  WallSound, LeftPadSound, RightPadSound,
    LostSound, SpawnSound, PointSound: ALLEGRO_SAMPLEptr;
  StartUpDelay: Integer;
  Shake: Integer;
  ShakeX, ShakeY: Single;
  KeyS, KeyW: Boolean;
  Score: Integer;
  BestScore: Integer;
  Font: ALLEGRO_FONTptr;
  Pause: Boolean;
  RatioX, RatioY: Single;
  QuitGame: Boolean;

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

  BackgroundColor := al_map_rgb(255, 255, 255);
  BackgroundShadeColor := al_map_rgb(235, 235, 235);
  PlayerColor := al_map_rgb(248, 180, 93);
  PlayerShadeColor := al_map_rgb(255, 222, 178);
  LeftPadColor := al_map_rgb(51, 139, 209);
  LeftPadShadeColor := al_map_rgb(199, 219, 246);
  RightPadColor := al_map_rgb(230,  98, 98);
  RightPadShadeColor := al_map_rgb(251, 185, 185);
  CoinColor := al_map_rgb(175, 223, 142);
  CoinShadeColor := al_map_rgb(213, 228, 202);
  HardCoinColor := al_map_rgb(184, 145, 223);
  HardCoinShadeColor := al_map_rgb(215, 202, 227);

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
  Pause := False;

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

  Pad2.x := INTERNAL_WIDTH - 60;
  Pad2.y := INTERNAL_HEIGHT - 180;
  Pad2.w := 60;
  Pad2.h := 180;
  Pad2.vx := 0;
  Pad2.vy := -4;
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
    (x1+ShakeX) * RatioX, (y1+ShakeY) * RatioY,
    (x2+ShakeX) * RatioX, (y2+ShakeY) * RatioY,
    (x3+ShakeX) * RatioX, (y3+ShakeY) * RatioY, PlayerShadeColor);
  al_draw_filled_rectangle(
    (Player.x+ShakeX) * RatioX, (Player.y+ShakeY) * RatioY,
    (Player.x+Player.w+ShakeX) * RatioX, (Player.y+Player.h+ShakeY) * RatioY,
    PlayerColor);
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
      else if Shake = 0 then
      begin
        Dec(Coins[I].Shake);
        Coins[I].ShakeX := 0;
        Coins[I].ShakeY := 0;
      end;
      DrawCoin(Coins[I]);
    end;
  end;
  DrawPlayer(Player);

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


    if (Player.x + Player.w) < (INTERNAL_WIDTH div 2 - SIZE) then
      Coins[N].x := random(INTERNAL_WIDTH div 2 - SIZE*2) + SIZE + INTERNAL_WIDTH div 2
    else if (Player.x) > (INTERNAL_WIDTH div 2 + SIZE) then
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
  Player.x := Player.x + Player.vx;
  Player.y := Player.y + Player.vy;

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
      if (Player.x+Player.w >= Coins[I].x) and
        (Player.x <= Coins[I].x+Coins[i].w) and
        (Player.y+Player.h >= Coins[I].y) and
        (Player.y <= Coins[I].y+Coins[I].h) then
      begin
        if Coins[I].Hits = 1 then
        begin
          Coins[I].Active := 0;
          Inc(Score);
          al_play_sample(PointSound, 1.0, 0.0, 1.0,
            ALLEGRO_PLAYMODE_ONCE, nil);
        end
        else
        begin
          Dec(Coins[I].Hits);
          Inc(Score);
          al_play_sample(LeftPadSound, 1.0, 0.0, 1.0,
            ALLEGRO_PLAYMODE_ONCE, nil);
          Player.vx := -Player.vx;
          Player.vy := -Player.vy;
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

  if Player.y+Player.h >= INTERNAL_HEIGHT then
  begin
    Shake := 10;
    Player.vy := -Player.vy;
    Player.y := INTERNAL_HEIGHT-Player.h;
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
    Inc(Score);
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
    Inc(Score);
    al_play_sample(RightPadSound, 1.0, 0.75, 1.0, ALLEGRO_PLAYMODE_ONCE, nil)
  end;

  // check for lost game
  if (Player.x+Player.w < 0) or (Player.x > INTERNAL_WIDTH) then
  begin
    // lost
    if player.x < INTERNAL_WIDTH then
      al_play_sample(LostSound, 1.0, -0.75, 1.0, ALLEGRO_PLAYMODE_ONCE, nil)
    else
      al_play_sample(LostSound, 1.0,  0.75, 1.0, ALLEGRO_PLAYMODE_ONCE, nil);

    Player.x := INTERNAL_WIDTH div 2 - Player.w div 2;
    Player.y := INTERNAL_HEIGHT div 2 - Player.h div 2;
    Player.vx := 0;
    Player.vy := 0;
    while Player.vy = 0 do
      Player.vy := (Random(3)-1) * 10;
    StartUpDelay := 100;
    if Score > BestScore then
      BestScore := Score;
    Score := 0;
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
  if Pause then
    Exit;

  if KeyW then
  begin
    if Player.vy > 0 then
    begin
      if Player.vy < 2 then
        Player.vy := Trunc(Player.vy/2)
      else if Player.vy < 10 then
        Player.vy := Trunc(Player.vy/1.5)
      else
        Player.vy := Trunc(Player.vy/1.1);
    end
    else if Player.vy < 0  then
    begin
      if Player.vy > -2 then
        Player.vy := Trunc(Player.vy*2)
      else if Player.vy > -10 then
        Player.vy := Trunc(Player.vy*1.5)
      else
        Player.vy := Trunc(Player.vy*1.1);

    end
    else
    begin
      Player.vy := -1;
    end;
  end;

  if KeyS then
  begin
    if Player.vy > 0 then
    begin
      if Player.vy < 2 then
        Player.vy := Trunc(Player.vy*2)
      else if Player.vy < 10 then
        Player.vy := Trunc(Player.vy*1.5)
      else
        Player.vy := Trunc(Player.vy*1.1);
    end
    else if Player.vy < 0 then
    begin
      if Player.vy > -2 then
        Player.vy := Trunc(Player.vy/2)
      else if Player.vy > -10 then
        Player.vy := Trunc(Player.vy/1.5)
      else
        Player.vy := Trunc(Player.vy/1.1);
    end
    else
    begin
      Player.vy := 1;
    end;
  end;

  if Player.vy > 50 then
    Player.vy := 50
  else if Player.vy < -50 then
    Player.vy := -50;

  if Player.vx > 50 then
    Player.vx := 50
  else if Player.vx < -50 then
    Player.vx := -50;
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
    (Settings.Width   - 0.25*R*al_get_bitmap_width(IntroImage))  / 2.0,
    (Settings.Height  - 0.25*R*al_get_bitmap_height(IntroImage)) / 2.0,
    0.25*R*al_get_bitmap_width(IntroImage),
    0.25*R*al_get_bitmap_height(IntroImage), 0);
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

  Player.x := -100;

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
            ALLEGRO_KEY_S, ALLEGRO_KEY_DOWN:
              KeyS := True;
            ALLEGRO_KEY_W, ALLEGRO_KEY_UP:
              KeyW := True;
            ALLEGRO_KEY_D, ALLEGRO_KEY_RIGHT:
              if (not Pause) and (Player.vx = 0) then
              begin
                Player.vx := 10;
                al_play_sample(SpawnSound, 1.0, 0.0, 1.0,
                  ALLEGRO_PLAYMODE_ONCE, nil)
              end;
            ALLEGRO_KEY_A, ALLEGRO_KEY_LEFT:
              if (not Pause) and (Player.vx = 0) then
              begin
                Player.vx := -10;
                al_play_sample(SpawnSound, 1.0, 0.0, 1.0,
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
            ALLEGRO_KEY_S, ALLEGRO_KEY_DOWN:
              KeyS := False;
            ALLEGRO_KEY_W, ALLEGRO_KEY_UP:
              KeyW := False;
          end;
        end;
    end;
  end;
end;

var
  IsMenuInited: Boolean;
  MenuFont: ALLEGRO_FONTptr;
  MenuIndex, MenuLayer: Integer;

procedure InitMenu;
begin
  MenuFont := al_load_font(GetCurrentDir + PathDelim + 'font.ttf', Trunc(126 * RatioX), 0);
  if MenuFont = nil then
    WriteLn('Error: loading menu ttf font');
  MenuIndex := 0;
  MenuLayer := 0;
end;

procedure DrawMenu;
begin
  al_clear_to_color(al_map_rgb(255, 255, 255));
  if MenuIndex = 0 then
  begin
    al_draw_filled_rectangle(
      0,
      Settings.Height div 40 * 24,
      Settings.Width,
      Settings.Height div 40 * 28,
      LeftPadShadeColor);
    al_draw_filled_rectangle(
      Settings.Width div 5,
      Settings.Height div 40 * 24,
      Settings.Width - Settings.Width div 5,
      Settings.Height div 40 * 28,
      LeftPadColor);
    al_draw_text(MenuFont, al_map_rgb(255, 255, 255),
      Settings.Width div 2, Settings.Height div 40 * 24,
      ALLEGRO_ALIGN_CENTRE, 'Start Game');
  end
  else
  begin
    al_draw_text(MenuFont, al_map_rgb(77, 77, 77),
      Settings.Width div 2, Settings.Height div 40 * 24,
      ALLEGRO_ALIGN_CENTRE, 'Start Game');
  end;
  if MenuIndex = 1 then
  begin
    al_draw_filled_rectangle(
      0,
      Settings.Height div 40 * 28,
      Settings.Width,
      Settings.Height div 40 * 32,
      RightPadShadeColor);
    al_draw_filled_rectangle(
      Settings.Width div 5,
      Settings.Height div 40 * 28,
      Settings.Width - Settings.Width div 5,
      Settings.Height div 40 * 32,
      RightPadColor);
    al_draw_text(MenuFont, al_map_rgb(255, 255, 255),
      Settings.Width div 2, Settings.Height div 40 * 28,
      ALLEGRO_ALIGN_CENTRE, 'Options');
  end
  else
  begin
    al_draw_text(MenuFont, al_map_rgb(77, 77, 77),
      Settings.Width div 2, Settings.Height div 40 * 28,
      ALLEGRO_ALIGN_CENTRE, 'Options');
  end;

  if MenuIndex = 2 then
  begin
    al_draw_filled_rectangle(
      0,
      Settings.Height div 40 * 32,
      Settings.Width,
      Settings.Height div 40 * 36,
      PlayerShadeColor);
    al_draw_filled_rectangle(
      Settings.Width div 5,
      Settings.Height div 40 * 32,
      Settings.Width - Settings.Width div 5,
      Settings.Height div 40 * 36,
      PlayerColor);
    al_draw_text(MenuFont, al_map_rgb(255, 255, 255),
      Settings.Width div 2, Settings.Height div 40 * 32,
      ALLEGRO_ALIGN_CENTRE, 'Exit');
  end
  else
  begin
    al_draw_text(MenuFont, al_map_rgb(77, 77, 77),
      Settings.Width div 2, Settings.Height div 40 * 32,
      ALLEGRO_ALIGN_CENTRE, 'Exit');
  end;
  al_flip_display;
end;

procedure Menu;
var
  IsMenuRunning, ShouldDraw: Boolean;
  CurrentMenuItem: Byte;
  Event: ALLEGRO_EVENT;
begin
  if not IsMenuInited then
  begin
    InitMenu;
    IsMenuInited := True;
  end;

  IsMenuRunning := True;
  ShouldDraw := False;

  CurrentMenuItem := 0;
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
        IsMenuRunning := False;
      ALLEGRO_EVENT_TIMER:
        ShouldDraw := True;
      ALLEGRO_EVENT_KEY_DOWN:
        begin
          case Event.Keyboard.KeyCode of
            ALLEGRO_KEY_S, ALLEGRO_KEY_DOWN:
              begin
                MenuIndex := (MenuIndex + 1) mod 3;
                al_play_sample(SpawnSound, 1.0, 0.0, 1.0,
                  ALLEGRO_PLAYMODE_ONCE, nil);
              end;
            ALLEGRO_KEY_W, ALLEGRO_KEY_UP:
              begin
                MenuIndex := (MenuIndex + 5) mod 3;
                al_play_sample(SpawnSound, 1.0, 0.0, 1.0,
                  ALLEGRO_PLAYMODE_ONCE, nil);
              end;
            ALLEGRO_KEY_D, ALLEGRO_KEY_RIGHT:
              begin
                al_play_sample(SpawnSound, 1.0, 0.0, 1.0,
                  ALLEGRO_PLAYMODE_ONCE, nil);
              end;
            ALLEGRO_KEY_A, ALLEGRO_KEY_LEFT:
              begin
                al_play_sample(SpawnSound, 1.0, 0.0, 1.0,
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
  Ini.Free;
end;

procedure Run;
begin
  Writeln('Start');

  IsMenuInited := False;
  QuitGame := False;

  Init;
  Intro;
  repeat
    Menu;
     if MenuIndex = 0 then
       Loop;
  until MenuIndex <> 0;
  Clean;

  Writeln('End');
end;

end.
