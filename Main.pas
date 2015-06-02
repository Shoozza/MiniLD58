unit Main;

interface

procedure Run;

implementation

uses
  SysUtils,
  Allegro5,
  al5primitives,
  al5audio,
  al5acodec,
  al5font,
  al5ttf,
  al5Image,
  Global,
  Player,
  Pad,
  Coin,
  GameSettings,
  Input,
  GameIntro,
  GameMenu,
  GameOptions;

const
  MAX_COINS = 2;

var
  Timer: ALLEGRO_TIMERptr;
  Pad1, Pad2: TPad;
  Coins: Array [1..MAX_COINS] of TCoin;
  BackgroundColor, BackgroundShadeColor,
    LeftPadColor, LeftPadShadeColor,
    RightPadColor, RightPadShadeColor: ALLEGRO_COLOR;
  WallSound, LeftPadSound, RightPadSound,
    LostSound, PointSound: ALLEGRO_SAMPLEptr;
  StartUpDelay1, StartUpDelay2: Integer;
  Score: Integer;
  BestScore: Integer;
  Pause: Boolean;
  IsRunning: Boolean;

procedure Init;
var
  I: Integer;
begin
  SetCurrentDir(ExtractFilePath(ParamStr(0)));
  InitSettings(Settings, 'config.ini');

  InitInput;

  if not al_init then
  begin
    WriteLn('Error: al_init');
    Halt;
  end;

  if Settings.Mode = 0 then
    al_set_new_display_flags(ALLEGRO_WINDOWED)
  else if Settings.Mode = 1 then
    al_set_new_display_flags(ALLEGRO_FULLSCREEN);

  al_set_new_display_option(ALLEGRO_VSYNC, Settings.Vsync, ALLEGRO_REQUIRE);

  Display := al_create_display(Settings.Width, Settings.Height);
  if Display = nil then
  begin
    WriteLn('Error: Cannot create window');
    Halt;
  end;

  al_clear_to_color(al_map_rgb(164, 164, 164));
  al_flip_display;
  al_set_window_title(Display, 'MiniLD58 - Theme: "Pong" - Balldr');

  RatioX := Settings.Width / INTERNAL_WIDTH;
  RatioY := Settings.Height / INTERNAL_HEIGHT;

  Randomize;

  if not al_init_image_addon then
    WriteLn('Error: al_init_image_addon');
  al_init_font_addon;
  if not al_init_ttf_addon then
    WriteLn('Error: al_init_ttf_addon');
  if not al_init_primitives_addon then
    WriteLn('Error: al_init_primitives_addon');

  al_init_acodec_addon;
  if not al_install_audio then
    Writeln('Error: al_install_audio');
  if not al_reserve_samples(16) then
    Writeln('Error: al_reserve_samples');

  if not al_install_keyboard then
    Writeln('Error: al_install_keyboard');

  Timer := al_create_timer(1.0 / 60.0);
  if Timer = nil then
    Writeln('Error: al_create_timer');

  Queue := al_create_event_queue;
  if Queue = nil then
    Writeln('Error: al_create_event_queue');

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

  InitPlayer(Player1);
  InitPlayer(Player2);

  Player2.Color := al_map_rgb(202, 185, 152);
  Player2.ShadeColor := al_map_rgb(226, 217, 199);

  BackgroundColor      := al_map_rgb(255, 255, 255);
  BackgroundShadeColor := al_map_rgb(235, 235, 235);
  LeftPadColor         := al_map_rgb( 51, 139, 209);
  LeftPadShadeColor    := al_map_rgb(199, 219, 246);
  RightPadColor        := al_map_rgb(230,  98, 98);
  RightPadShadeColor   := al_map_rgb(251, 185, 185);
  CoinColor            := al_map_rgb(175, 223, 142);
  CoinShadeColor       := al_map_rgb(213, 228, 202);
  HardCoinColor        := al_map_rgb(184, 145, 223);
  HardCoinShadeColor   := al_map_rgb(215, 202, 227);

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
    InitCoin(Coins[I]);

  BestScore := 0;
  Score := 0;

  Pause := False;

  InitPad(Pad1);
  InitPad(Pad2);

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

procedure DrawLevel;
const
  SIZE = 60;
begin
  al_draw_filled_rectangle(Settings.Width/2-SIZE*RatioX, 0,
    Settings.Width/2+SIZE*RatioX, Settings.Height, BackgroundShadeColor);
end;

procedure Draw;
var
  I: Integer;
begin
  al_clear_to_color(BackgroundColor);

  DrawLevel;

  DrawScore;

  DrawPad(Pad1, LeftPadColor, LeftPadShadeColor);
  DrawPad(Pad2, RightPadColor, RightPadShadeColor);

  DrawPlayer(Player1);
  DrawPlayer(Player2);

  for I := 1 to MAX_COINS do
    if Coins[I].Active <> 0 then
      DrawCoin(Coins[I]);

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
  UpdatePlayer(Player1);
  UpdatePlayer(Player2);

  UpdatePad(Pad1);
  UpdatePad(Pad2);

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
  if (IsDownNew(GAMEKEY_PAUSE)) or (IsDownNew(GAMEKEY_PAUSE_2)) then
    Pause := not Pause;

  if (IsDown(GAMEKEY_CANCEL)) or (IsDown(GAMEKEY_CANCEL_2)) then
    IsRunning := False;

  if Pause then
    Exit;

  if Player1.vx = 0 then
  begin
    if IsDown(GAMEKEY_LEFT) then
    begin
      Player1.vx := -10;
      al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0,
        ALLEGRO_PLAYMODE_ONCE, nil)
    end
    else if IsDown(GAMEKEY_RIGHT) then
    begin
      Player1.vx := 10;
      al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0,
        ALLEGRO_PLAYMODE_ONCE, nil)
    end;
  end;

  if Player2.vx = 0 then
  begin
    if IsDown(GAMEKEY_LEFT_2) then
    begin
      Player2.vx := -10;
      al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0,
        ALLEGRO_PLAYMODE_ONCE, nil)
    end
    else if IsDown(GAMEKEY_RIGHT_2) then
    begin
      Player2.vx := 10;
      al_play_sample(SpawnSound, Settings.SfxVolume, 0.0, 1.0,
        ALLEGRO_PLAYMODE_ONCE, nil)
    end;
  end;

  if IsDown(GAMEKEY_UP) then
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

  if IsDown(GAMEKEY_DOWN) then
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

  if IsDown(GAMEKEY_UP_2) then
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

  if IsDown(GAMEKEY_DOWN_2) then
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

procedure Loop;
var
  ShouldDraw: boolean;
  Event: ALLEGRO_EVENT;
begin
  ClearInput;
  IsRunning := True;
  ShouldDraw := True;

  Player1.x := -100;
  Player2.x := -100;

  while IsRunning do
  begin
    if (ShouldDraw) and (al_is_event_queue_empty(Queue)) then
    begin
      HandleInput;
      SwapInput;
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
        UpdateKeyboard(Event.Keyboard.KeyCode, True);
      ALLEGRO_EVENT_KEY_UP:
        UpdateKeyboard(Event.Keyboard.KeyCode, False);
    end;
  end;
end;

procedure Clean;
begin
  SaveSettings(Settings);
  DestroySettings(Settings);
end;

procedure Run;
const
  INDEX_START = 0;
  INDEX_OPTIONS = 1;
  INDEX_EXIT = 2;
begin
  Writeln('Start');

  IsMenuInited := False;

  Init;
  Intro;
  repeat
    Menu;
     if MenuIndex = INDEX_START then
       Loop
     else if MenuIndex = INDEX_OPTIONS then
       Options;
  until MenuIndex = INDEX_EXIT;
  Clean;

  Writeln('End');
end;

end.
