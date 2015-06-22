unit Game;

interface

procedure Loop;


implementation

uses
  SysUtils,

  Allegro5,
  al5audio,
  al5font,
  al5primitives,

  GameMenu,

  Input,
  GameSettings,

  Global,
  Player,
  Coin,
  Pad;

const
  MAX_COINS = 2;

var
  Pad1, Pad2: TPad;
  Coins: Array [1..MAX_COINS] of TCoin;
  StartUpDelay1, StartUpDelay2: Integer;
  Score: Integer;
  BestScore: Integer;
  Pause: Boolean;
  IsRunning: Boolean;
  IsInited: Boolean;

procedure InitGame;
begin
  if IsInited then
    Exit;

  InitPlayer(Player2);

  Player2.Color := al_map_rgb(202, 185, 152);
  Player2.ShadeColor := al_map_rgb(226, 217, 199);

  IsInited := True;
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

procedure ResetGame;
var
  I: Integer;
begin
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

  ClearInput;

  IsRunning := True;

  Player1.x := -100;
  Player2.x := -100;
end;

procedure Loop;
var
  ShouldDraw: boolean;
  Event: ALLEGRO_EVENT;
begin
  ShouldDraw := True;

  InitGame;
  ResetGame;

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

end.
