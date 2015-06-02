unit Global;

interface

uses
  Allegro5,
  al5audio,
  GameSettings;

const
  INTERNAL_HEIGHT = 1080;
  INTERNAL_WIDTH  = 1920;

var
  RatioX, RatioY: Single;
  CoinColor, CoinShadeColor,
  HardCoinColor, HardCoinShadeColor: ALLEGRO_COLOR;
  Settings: TSettings;
  Queue: ALLEGRO_EVENT_QUEUEptr;
  SpawnSound: ALLEGRO_SAMPLEptr;


implementation

end.
