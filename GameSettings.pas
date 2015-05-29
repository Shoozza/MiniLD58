unit GameSettings;

interface

uses
  IniFiles;

type
  TSettings = record
    Width, Height, Mode, Vsync: Integer;
    SfxVolumeNum: Integer;
    SfxVolume: Single;
    Ini: TMemIniFile;
  end;

procedure InitSettings(var Settings: TSettings; FileName: string);
procedure LoadSettings(var Settings: TSettings);
procedure SaveSettings(var Settings: TSettings);
procedure DestroySettings(var Settings: TSettings);


implementation

procedure InitSettings(var Settings: TSettings; FileName: string);
begin
  Settings.Ini := TMemIniFile.Create(FileName);
  LoadSettings(Settings);
end;

procedure LoadSettings(var Settings: TSettings);
begin
  Settings.Width        := Settings.Ini.ReadInteger('GENERAL', 'Screen_Width', 1920);
  Settings.Height       := Settings.Ini.ReadInteger('GENERAL', 'Screen_Height', 1080);
  Settings.Mode         := Settings.Ini.ReadInteger('GENERAL', 'Fullscreen', 0);
  Settings.Vsync        := Settings.Ini.ReadInteger('GENERAL', 'VSync', 0);
  Settings.SfxVolumeNum := Settings.Ini.ReadInteger('GENERAL', 'Sfx_Volume', 50);
  Settings.SfxVolume    := Settings.SfxVolumeNum / 100;
end;

procedure SaveSettings(var Settings: TSettings);
begin
  Settings.Ini.WriteInteger('GENERAL', 'Screen_Width',  Settings.Width);
  Settings.Ini.WriteInteger('GENERAL', 'Screen_Height', Settings.Height);
  Settings.Ini.WriteInteger('GENERAL', 'Fullscreen',    Settings.Mode);
  Settings.Ini.WriteInteger('GENERAL', 'Vsync',         Settings.Vsync);
  Settings.Ini.WriteInteger('GENERAL', 'Sfx_Volume',    Settings.SfxVolumeNum);
end;

procedure DestroySettings(var Settings: TSettings);
begin
  Settings.Ini.Free;
end;

end.
