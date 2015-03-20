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
  IsRunning: boolean;
  Event: ALLEGRO_EVENT;
begin
  IsRunning := True;

  al_rest(1);
  while IsRunning do
  begin
    al_wait_for_event(Queue, Event);

    if event._type = ALLEGRO_EVENT_DISPLAY_CLOSE then
      IsRunning := False;

    Draw;
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
