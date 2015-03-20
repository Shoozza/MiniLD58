unit Main;

interface

procedure Run;

implementation

procedure Init;
begin
end;

procedure Loop;
var
  IsRunning: boolean;
begin
  IsRunning := True;

  While IsRunning do
  begin
    IsRunning := False;
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
