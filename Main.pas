unit Main;

interface

procedure Run;

implementation

uses
  SysUtils,
  IniFiles,
  Allegro5,
  al5primitives;

type
  TPlayer = record
    x, y: Integer;
    vx, vy: Integer;
  end;

  TPad = record
    x, y: Integer;
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

procedure Init;
begin
  SetCurrentDir(ExtractFilePath(ParamStr(0)));
  Ini := TMemIniFile.Create('config.ini');

  Settings.Width := Ini.ReadInteger('GENERAL', 'Screen_Width', 1920);
  Settings.Height := Ini.ReadInteger('GENERAL', 'Screen_Height', 1080);

  al_init;
  Display := al_create_display(Settings.Width, Settings.Height);

  al_install_keyboard;

  Timer := al_create_timer(1.0 / 60.0);
  Queue := al_create_event_queue;

  al_init_primitives_addon;

  al_register_event_source(Queue, al_get_display_event_source(display));
  al_register_event_source(Queue, al_get_timer_event_source(Timer));
  al_register_event_source(Queue, al_get_keyboard_event_source);
  al_start_timer(Timer);

  Player.x := 100;
  Player.y := 100;
  Player.vx := 0;
  Player.vy := 0;

  Pad1.x := 0;
  Pad1.y := 0;
  Pad1.vx := 0;
  Pad1.vy := 0;

  Pad2.x := 0;
  Pad2.y := 0;
  Pad2.vx := 0;
  Pad2.vy := 0;
end;

procedure DrawPlayer(var Player: TPlayer);
const
  SIZE = 80;
begin
  al_draw_filled_rectangle(Player.x, Player.y, Player.x+SIZE, Player.y+SIZE, al_map_rgb(255, 255, 255));
end;

procedure DrawPad(var Pad: TPad);
const
  SIZE_X = 60;
  SIZE_Y = 3*60;
begin
  al_draw_filled_rectangle(Pad.x, Pad.y, Pad.x+SIZE_X, Pad.y+SIZE_Y, al_map_rgb(255,0,0));
end;

procedure Draw;
const
  SIZE = 60;
begin
  al_clear_to_color(al_map_rgb(0, 0, 0));

  al_draw_filled_rectangle(Settings.Width/2-SIZE, 0, Settings.Width/2+SIZE,
    Settings.Height, al_map_rgb(128, 128, 128));

  DrawPlayer(Player);
  DrawPad(Pad1);
  DrawPad(Pad2);

  al_flip_display;
end;

procedure Update;
begin
  Player.x := Player.x + Player.vx;
  Player.y := Player.y + Player.vy;

  Pad1.x := Pad1.x + Pad1.vx;
  Pad1.y := Pad1.y + Pad1.vy;

  Pad2.x := Pad2.x + Pad2.vx;
  Pad2.y := Pad2.y + Pad2.vy;
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
              Inc(Player.vy);
            ALLEGRO_KEY_W:
              Dec(Player.vy);
            ALLEGRO_KEY_D:
              Inc(Player.vx);
            ALLEGRO_KEY_A:
              Dec(Player.vx);
            ALLEGRO_KEY_ESCAPE:
              IsRunning := False;
          end;
        end;
      ALLEGRO_EVENT_KEY_UP:
        begin
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
