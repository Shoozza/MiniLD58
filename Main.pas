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

  Game,
  GameIntro,
  GameMenu,
  GameOptions;

var
  Timer: ALLEGRO_TIMERptr;

procedure Init;
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

  RatioX := Settings.Width / INTERNAL_WIDTH;
  RatioY := Settings.Height / INTERNAL_HEIGHT;

  Randomize;

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
