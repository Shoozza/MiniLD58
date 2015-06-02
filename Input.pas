unit Input;

interface

const
  GAMEKEY_UP       = 0;
  GAMEKEY_DOWN     = 1;
  GAMEKEY_LEFT     = 2;
  GAMEKEY_RIGHT    = 3;
  GAMEKEY_PAUSE    = 4;
  GAMEKEY_ENTER    = 5;
  GAMEKEY_CANCEL   = 6;

  GAMEKEY_UP_2     = 7;
  GAMEKEY_DOWN_2   = 8;
  GAMEKEY_LEFT_2   = 9;
  GAMEKEY_RIGHT_2  = 10;
  GAMEKEY_PAUSE_2  = 11;
  GAMEKEY_ENTER_2  = 12;
  GAMEKEY_CANCEL_2 = 13;
  GAMEKEY_MAX      = 14;

procedure InitInput;
procedure SwapInput;
procedure ClearInput;

procedure UpdateKeyboard(KeyCode: Integer; IsDown: Boolean);
procedure UpdateMouse(Button: Integer; IsDown: Boolean);
procedure UpdateGamePad(Button: Integer; IsDown: Boolean);

function IsDown(GameKey: Integer): Boolean;
function IsReleased(GameKey: Integer): Boolean;
function IsDownNew(GameKey: Integer): Boolean;

function GetMouseX: Integer;
function GetMouseY: Integer;
function GetMouseScroll: Integer;

implementation

uses
  Allegro5;

const
  MOUSE_MAX    = 10;
  GAMEPAD_MAX  = 20;
  KEYBOARD_MAX = ALLEGRO_KEY_MAX;
  INPUT_MAX    = MOUSE_MAX + GAMEPAD_MAX + KEYBOARD_MAX;

var
  Key:    array[0..INPUT_MAX   - 1] of Boolean;
  KeyOld: array[0..INPUT_MAX   - 1] of Boolean;
  KeyMap: array[0..GAMEKEY_MAX - 1] of Integer;

procedure InitInput;
begin
  ClearInput;

  KeyMap[GAMEKEY_UP]     := MOUSE_MAX + GAMEPAD_MAX + ALLEGRO_KEY_W;
  KeyMap[GAMEKEY_DOWN]   := MOUSE_MAX + GAMEPAD_MAX + ALLEGRO_KEY_S;
  KeyMap[GAMEKEY_LEFT]   := MOUSE_MAX + GAMEPAD_MAX + ALLEGRO_KEY_A;
  KeyMap[GAMEKEY_RIGHT]  := MOUSE_MAX + GAMEPAD_MAX + ALLEGRO_KEY_D;
  KeyMap[GAMEKEY_PAUSE]  := MOUSE_MAX + GAMEPAD_MAX + ALLEGRO_KEY_P;
  KeyMap[GAMEKEY_ENTER]  := MOUSE_MAX + GAMEPAD_MAX + ALLEGRO_KEY_SPACE;
  KeyMap[GAMEKEY_CANCEL] := MOUSE_MAX + GAMEPAD_MAX + ALLEGRO_KEY_ESCAPE;

  KeyMap[GAMEKEY_UP_2]     := MOUSE_MAX + GAMEPAD_MAX + ALLEGRO_KEY_UP;
  KeyMap[GAMEKEY_DOWN_2]   := MOUSE_MAX + GAMEPAD_MAX + ALLEGRO_KEY_DOWN;
  KeyMap[GAMEKEY_LEFT_2]   := MOUSE_MAX + GAMEPAD_MAX + ALLEGRO_KEY_LEFT;
  KeyMap[GAMEKEY_RIGHT_2]  := MOUSE_MAX + GAMEPAD_MAX + ALLEGRO_KEY_RIGHT;
  KeyMap[GAMEKEY_PAUSE_2]  := MOUSE_MAX + GAMEPAD_MAX + ALLEGRO_KEY_ENTER;
  KeyMap[GAMEKEY_ENTER_2]  := MOUSE_MAX + GAMEPAD_MAX + ALLEGRO_KEY_ENTER;
  KeyMap[GAMEKEY_CANCEL_2] := MOUSE_MAX + GAMEPAD_MAX + ALLEGRO_KEY_BACKSPACE;
end;

procedure SwapInput;
begin
  Move(Key, KeyOld, INPUT_MAX);
end;

procedure ClearInput;
begin
  FillChar(Key,    INPUT_MAX, 0);
  FillChar(KeyOld, INPUT_MAX, 0);
end;

procedure UpdateKeyboard(KeyCode: Integer; IsDown: Boolean);
begin
  Key[MOUSE_MAX + GAMEPAD_MAX + KeyCode] := IsDown;
end;

procedure UpdateMouse(Button: Integer; IsDown: Boolean);
begin
  Key[Button] := IsDown;
end;

procedure UpdateGamePad(Button: Integer; IsDown: Boolean);
begin
  Key[MOUSE_MAX + Button] := IsDown;
end;

function IsDown(GameKey: Integer): Boolean;
begin
  Result := Key[KeyMap[GameKey]];
end;

function IsDownNew(GameKey: Integer): Boolean;
begin
  Result := (Key[KeyMap[GameKey]]) and (not KeyOld[KeyMap[GameKey]]);
end;

function IsReleased(GameKey: Integer): Boolean;
begin
  Result := (not Key[KeyMap[GameKey]]) and (KeyOld[KeyMap[GameKey]]);
end;

// TODO: Implement
function GetMouseX: Integer;
begin
  Result := 0;
end;

// TODO: Implement
function GetMouseY: Integer;
begin
  Result := 0;
end;

// TODO: Implement
function GetMouseScroll: Integer;
begin
  Result := 0;
end;

end.
