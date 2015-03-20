unit Main;

interface

procedure Run;

implementation

uses
  Allegro5;

var
  Display: ALLEGRO_DISPLAYptr;
  Queue: ALLEGRO_EVENT_QUEUEptr;
  Timer: ALLEGRO_TIMERptr;

procedure Init;
begin
  al_init;
  Display := al_create_display(1920, 1080);
  Timer := al_create_timer(1.0 / 60.0);
  Queue := al_create_event_queue;
  al_register_event_source(Queue, al_get_display_event_source(display));
  al_register_event_source(Queue, al_get_timer_event_source(Timer));
  al_start_timer(timer);
end;

procedure Draw;
begin
  al_clear_to_color(al_map_rgb(0, 0, 0));
  al_flip_display;
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
      Draw;

    al_wait_for_event(Queue, Event);

    case Event._type of
      ALLEGRO_EVENT_DISPLAY_CLOSE:
        IsRunning := False;
      ALLEGRO_EVENT_TIMER:
        ShouldDraw := True;
    end;
  end;
end;

procedure Clean;
begin
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
