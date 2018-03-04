program SnakeGame;

{$APPTYPE CONSOLE}

uses
  SysUtils, Console, Windows;

var
  ConHandle  : THandle;


procedure ShowCursor(Show : Boolean);
var
  CCI        : TConsoleCursorInfo;
begin
  CCI.bVisible := Show;
  SetConsoleCursorInfo(ConHandle, CCI);
end;

function GetConOutputHandle : THandle;
begin
  Result := GetStdHandle(STD_OUTPUT_HANDLE)
end;

const
  __MAXX     = 80;
  __LOWX     = 1;
  __MAXY     = 15;
  __LOWY     = 1;
  _MaxX      = 80;
  _LowX      = 15;
  _MaxY      = 24;
  _LowY      = 2;
  _StartX    = 35;
  _StartY    = 15;
  _StartLen  = 6;
  BodyChar   = #1;
  HeadChar   = #2;
  AppleChar  = #4;
  FrameChar  = #219;
  _TraceColor = Blue;
  _HeadColor = LightGreen;
  _BodyColor = Green;
  _SnakeBGColor = Blue;
  _FrameColor = White;
  _ScoreColor = Black;
  _SValuesColor = LightBlue;
  _GBGColor = Black;
  _SBGColor = White;
  _AppleColor = LightBlue; 
  NormalEasy = 60;
  NormalNormal = 33;
  NormalHard = 20;
  ScoreX = 4;



type
  TDirection = (Right, Left, Up, Down);
  TBodyPos = record
    X,
    Y: Integer;
  end;
  TBodyPostions = array of TBodyPos;


var
  GameSpeedBegin: Integer = 43;
  GameSpeed: Integer;
  GameSpeedMax: Integer   = 21;
  StartLen: Integer       = 6;
  AppleCollected: Integer = 0;
  GameTime: Integer       = 0;
  Score: Integer          = 0;
  MaxX: Integer           = _MaxX;
  LowX: Integer           = _LowX;
  MaxY: Integer           = _MaxY;
  LowY: Integer           = _LowY;
  StartX: Integer         = _StartX;
  StartY: Integer         = _StartY;

  SurvivalMode: Boolean   = True;
  Quit: Boolean           = False;
  Trace: Boolean          = True;
  WallTeleport: Boolean   = True;
  Lose: Boolean           = False;
  Pause: Boolean          = False;
  WriteLock: Boolean      = False; // Sync
  AppleSound: Boolean     = False;
  TimerBreak: Boolean     = False;

  TraceColor: Integer     = Blue;
  HeadColor: Integer      = LightGreen;
  BodyColor: Integer      = Green;
  SnakeBGColor: Integer   = Blue;
  FrameColor: Integer     = White;
  ScoreColor: Integer     = Black;
  SValuesColor: Integer   = LightBlue;
  GBGColor: Integer       = Black;
  SBGColor: Integer       = White;
  AppleColor: Integer     = LightRed;

  Snake: TBodyPostions;
  Direction: TDirection;
  Apple: TBodyPos;


procedure Fill(XFrom, YFrom, XToo, YToo: Integer);
var
  I: Integer;
begin
  for I:=YFrom to YToo do begin
    GotoXY(XFrom,I);
    Write(StringOfChar(BodyChar,XToo));
  end;
end;


function GetProcent(Procent, Value: Integer): Integer;
begin
  Result:=(Procent*Value)div 100;
end;

function GetProcentEx(Procent, Value: Integer): Integer;
begin
  Result:=(Procent*Value)div 100;
end;

function RandomRange(From,Too:Integer): Integer;
begin
  repeat
    Result:=Random(Too);
    if(Result in[From..Too])then Break;
  until(false);
end;

procedure DrawFrame;
var
  I: Integer;
begin
  TextColor(FrameColor);
  for I:=LowY-1 to MaxY+1 do begin
    GotoXY(LowX-1,I);
    Write(FrameChar);
  end;
  for I:=LowX-1 to MaxX do begin
    GotoXY(I,LowY-1);
    Write(FrameChar);
  end;
  for I:=LowX-1 to MaxX do begin
    GotoXY(I,MaxY+1);
    Write(FrameChar);
  end;
  TextBackground(SBGColor);
  for I:=LowY-1 to MaxY+1 do begin
    GotoXY(1,I);
    Write(StringOfChar(' ',LowX-2) );
  end;
end;

procedure DrawScore;
begin
  TextColor(ScoreColor);
  TextBackground(SBGColor);
  GotoXY(2,LowY+5);
  Write('JABLEK:');
  GotoXY(2,LowY+9);
  Write('CZAS GRY:');
  GotoXY(2,LowY+13);
  Write('WYNIK:');
  if(SurvivalMode)then begin
    GotoXY(2,LowY+17);
    Write('Predkosc:');
  end;
  ShowCursor(False);
end;

procedure DrawApple;
begin
  TextColor(ScoreColor);
  TextBackground(SBGColor);
  GotoXY(2,LowY+6);
  Write(StringOfChar(' ',LowX-4));
  GotoXY(2,LowY+6);
  Write(AppleCollected);
  ShowCursor(False);
end;

procedure DrawTime;
begin
  TextColor(ScoreColor);
  TextBackground(SBGColor);
  GotoXY(2,LowY+10);
  Write(StringOfChar(' ',LowX-5));
  GotoXY(2,LowY+10);
  Write(GameTime,' sec');
end;

procedure DrawGameSpeed;
begin
  TextColor(ScoreColor);
  TextBackground(SBGColor);
  GotoXY(2,LowY+18);
  Write(StringOfChar(' ',LowX-5));
  GotoXY(2,LowY+18);
  if(GameSpeed<>GameSpeedMax)then
    Write(((GameSpeedBegin*100)div GameSpeed),'%')
  else
    Write('MAX (',((GameSpeedBegin*100)div GameSpeed),'% )');
end;

procedure DrawScoreCount;
begin
  TextColor(ScoreColor);
  TextBackground(SBGColor);
  GotoXY(2,LowY+14);
  Write(StringOfChar(' ',LowX-5));
  GotoXY(2,LowY+14);
  Write(Score);
end;

procedure CreateApple;
label Rep;
var
  I: Integer;
  Again: Boolean;
begin
   Randomize;
   Rep:
    Again:=False;
    Apple.X:=RandomRange(LowX,MaxX);
    Apple.Y:=RandomRange(LowY,MaxY);
    for i:=0 to Length(Snake)-1 do
      if(Snake[i].X=Apple.X)and(Snake[i].Y=Apple.Y)then begin
        Again:=True;
        Break;
      end;
    if(Again)then Goto Rep;
  TextBackground(GBGColor);
  TextColor(AppleColor);
  GotoXY(Apple.X,Apple.Y);
  Write(AppleChar);
end;

procedure InitSnake;
var
  I: Integer;
begin
  SetLength(Snake,StartLen+1);
  Snake[0].X:=StartX;
  Snake[0].Y:=StartY;
  for I:=1 to Length(Snake)-1 do begin
    Snake[I].X:=StartX-I;
    Snake[I].Y:=StartY;
  end;
end;

procedure DrawSnake;
begin
  ShowCursor(False);
  TextBackground(SnakeBGColor);
  TextColor(HeadColor);
  GotoXY(Snake[0].X,Snake[0].Y);
  Write(HeadChar);
  TextBackground(SnakeBGColor);
  TextColor(BodyColor);
  GotoXY(Snake[1].X,Snake[1].Y);
  if(Snake[1].X in[__LOWX..__MAXX])then
  Write(BodyChar);
  GotoXY(Snake[Length(Snake)-1].X,Snake[Length(Snake)-1].Y);
  if not(Trace)then
    TextBackGround(GBGColor)
  else
    TextBackGround(TraceColor);
  Write(' ');
  TextBackGRound(GBGColor);
end;

procedure CopyTabs(var From, Too:TBodyPostions);
begin
  SetLength(Too,Length(From));
  Move(From[0],Too[0],Length(From)*SizeOf(TBodyPos));
end;

procedure PushValues;
var
  tmp: TBodyPostions;
  I: Integer;
begin
  CopyTabs(Snake,tmp);
  for I:=1 to Length(Snake)-1 do
    Snake[I]:=tmp[I-1];
  SetLength(tmp,0);
end;

function SnakeColision: Boolean;
var
  I: Integer;
begin
  Result:=False;
  for I:=2 to Length(Snake)-1 do
    if(Snake[0].X=Snake[I].X)and(Snake[0].Y=Snake[I].Y)then begin
      Result:=True;
      Break;
    end;
end;

function IncPosition: Boolean;
begin
  Result:=True;
  if not(WallTeleport)then
    if(Snake[0].X=MaxX)or(Snake[0].X=LowX)or
      (Snake[0].Y=MaxY)or(Snake[0].Y=LowY)then begin
      Result:=False;
      Exit;
    end;
  PushValues;
  case Direction of
    Right: begin
      if(Snake[0].X=MaxX)then
        Snake[0].X:=LowX
      else
        Inc(Snake[0].X);
    end;
    Left: begin
      if(Snake[0].X=LowX)then
        Snake[0].X:=MaxX
      else
        Dec(Snake[0].X);
    end;
    Down: begin
      if(Snake[0].Y=MaxY)then
        Snake[0].Y:=LowY
      else
        Inc(Snake[0].Y);
    end;
    Up: begin
      if(Snake[0].Y=LowY)then
        Snake[0].Y:=MaxY
      else
        Dec(Snake[0].Y);
    end;
  end;
end;

procedure AppleThread(PInt:Integer); stdcall;
begin
  Windows.Beep(325,279);
  Windows.Beep(325,279);
end;

procedure CountScore;
begin
  if(SurvivalMode)then
    Score:=(AppleCollected*ScoreX)+GameTime
  else
    Score:=(AppleCollected*ScoreX);
  if(Score<0)then Score:=0;
end;

procedure AppleHit;
var
  tmp: dword;
begin
  if(Snake[0].X=Apple.X)and(Snake[0].Y=Apple.Y)then begin
    SetLength(Snake,Length(Snake)+1);
    CreateApple;
    Inc(AppleCollected);
    DrawApple;
    if(AppleSound)then
      CreateThread(nil,0,@AppleThread,nil,0,tmp);
    if(SurvivalMode)then begin
      if(GameSpeed=GameSpeedMax)then Exit;
      if(AppleCollected mod 2=0)then begin
        GameSpeed:=GameSpeed-1;
        DrawGameSpeed;
      end;
    end;
  end;
end;

procedure GameThread(PInt:Integer); stdcall;
begin
  CreateApple;
  repeat
    if(Quit)then Break;
    if(Direction=Up)or(Direction=Down)then
      Sleep(GetProcent(40,GameSpeed));
    if(Pause)then
      repeat
        Sleep(10);
        ShowCursor(false);
      until(not Pause);
    if(Quit)then Break;
    DrawSnake;
    ShowCursor(False);
    if(SnakeColision)then Break;
    AppleHit;
    if(WriteLock)then begin
      WriteLock:=False;
      DrawTime;
      DrawScoreCount;
    end;
    Sleep(GameSpeed);
  until not(IncPosition=True);
  TimerBreak:=True;
  if not(Quit)then begin
    ClrScr;
    TextColor(Red);
    GotoXY(35,14);
    WriteLn('GAME OVER');
    GotoXY(35,15);
    WriteLn('JABLEK: ',AppleCollected);
    GotoXY(35,16);
    WriteLn('CZAS GRY: ',GameTime,' sekundy');
    Lose:=True;
    GotoXY(35,17);
    Write('Wcisnij enter...');
  end else
    ClrScr;
end;

procedure TimeThread(PInt:Integer); stdcall;
begin
  repeat
    if(TimerBreak)then Break;
    Sleep(1000);
    if(Pause)then Continue;
    Inc(GameTime);
    CountScore;
    WriteLock:=True;
  until(Lose);
  TimerBreak:=False;
end;

procedure DefaultGameColors;
begin
  TraceColor:=_TraceColor;
  HeadColor:=_HeadColor;
  BodyColor:=_BodyColor;
  SnakeBGColor:=_SnakeBGColor;
  FrameColor:=_FrameColor;
  ScoreColor:=_ScoreColor;
  SValuesColor:=_SValuesColor;
  GBGColor:=_GBGColor;
  SBGColor:=_SBGColor;
  AppleColor:=_AppleColor;
end;

procedure DrawGameDifficulty;
begin
  TextBackGround(Black);
  ClrScr;
  TextBackground(White);
  TextColor(Black);
  Fill(1,1,20,_MAXY+1);
  Fill(61,1,20,_MAXY+1);

  TextBackground(Black);

  Fill(21,1,39,_MAXY+1);
  //TextColor(White);

  TextBackground(White);
  Fill(20,1,41,2);

  TextBackground(White);
  Fill(21,_MAXY-3,41,_MAXY+1);

  GotoXY(1,1);
  TextBackground(Black);

  TextColor(Yellow);
  GotoXY(35,5);
  Write('  LATWY');
  GotoXY(22,8);
  TextColor(DarkGray);
  Write(StringOfChar('_',38));
  TextColor(White);
  GotoXY(35,11);
  Write(' NORMALNY');
  GotoXY(22,14);
  TextColor(DarkGray);
  Write(StringOfChar('_',38));
  TextColor(White);
  GotoXY(35,17);
  Write('  TRUDNY');
end;

procedure DeSelectGD(MenuOpt: Integer);
begin
  TextBackground(Black);
  TextColor(White);
  case MenuOpt of
    1: begin
      GotoXY(35,5);
      Write('  LATWY');
    end;
    2: begin
      GotoXY(35,11);
      Write(' NORMALNY');
    end;
    3: begin
      GotoXY(35,17);
      Write('  TRUDNY');
    end;
  end;
end;

procedure SelectGD(MenuOpt: Integer);
begin
  TextBackground(Black);
  TextColor(Yellow);
  case MenuOpt of
    1: begin
      GotoXY(35,5);
      Write('  LATWY');
    end;
    2: begin
      GotoXY(35,11);
      Write(' NORMALNY');
    end;
    3: begin
      GotoXY(35,17);
      Write('  TRUDNY');
    end;
  end;
end;

procedure ExecuteOptionGD(Opt: Integer);
begin
  case Opt of
    1: begin
      GameSpeed:=NormalEasy;
    end;
    2: begin
      GameSpeed:=NormalNormal;
    end;
    3: begin
      GameSpeed:=NormalHard;
    end;
  end;
end;

procedure GDProcess;
var
  Chr: Char;
  MenuOpt: Integer;
begin
  MenuOpt:=1;
  repeat
    Chr:=ReadKey;
    if(Ord(Chr)=9)then Chr:=#80;
    if(Chr=' ')then Chr:=#13;
    case Ord(Chr) of
      72: begin    // UP
        DeSelectGD(MenuOpt);
        if(MenuOpt=1)then
          MenuOpt:=3
        else
          Dec(MenuOpt);
        SelectGD(MenuOpt);
      end;
      80: begin  // Down
        DeSelectGD(MenuOpt);
        if(MenuOpt=3)then
          MenuOpt:=1
        else
          Inc(MenuOpt);
        SelectGD(MenuOpt);
      end;
      13: begin
        ExecuteOptionGD(MenuOpt);
      end;
    end;
  until(Ord(Chr)=13);
end;

procedure GameDifficulty;
begin
  DrawGameDifficulty;
  GDProcess;
end;

procedure DeSelectGameMenu(MenuOpt: Integer);
begin
  TextBackground(Black);
  TextColor(White);
  case MenuOpt of
    1: begin
      GotoXY(35,9);
      Write(' SURVIVAL');
    end;
    2: begin
     GotoXY(35,16);
     Write(' NORMALNY');
    end;
  end;
end;

procedure SelectGameMenu(MenuOpt: Integer);
begin
  TextBackground(Black);
  TextColor(Yellow);
  case MenuOpt of
    1: begin
      GotoXY(35,9);
      Write(' SURVIVAL');
    end;
    2: begin
      GotoXY(35,16);
      Write(' NORMALNY');
    end;
  end;
end;

procedure ExecuteOptionEx(Opt: Integer);
begin
  case Opt of
    1: begin
      SurvivalMode:=True;
    end;
    2: begin
      SurvivalMode:=False;
      GameDifficulty;
    end;
  end;
end;

procedure GameMenuProcess;
var
  Chr: Char;
  MenuOpt: Integer;
begin
  MenuOpt:=1;
  repeat
    Chr:=ReadKey;
    case Ord(Chr) of
      72: begin    // UP
        DeSelectGameMenu(MenuOpt);
        if(MenuOpt=1)then
          MenuOpt:=2
        else
          Dec(MenuOpt);
        SelectGameMenu(MenuOpt);
      end;
      80: begin  // Down
        DeSelectGameMenu(MenuOpt);
        if(MenuOpt=2)then
          MenuOpt:=1
        else
          Inc(MenuOpt);
        SelectGameMenu(MenuOpt);
      end;
      13: begin
        ExecuteOptionEx(MenuOpt);
      end;
    end;
  until(Ord(Chr)=13);
end;

procedure DrawGameModeMenu;
begin
  TextBackGround(Black);
  ClrScr;
  TextBackground(White);
  TextColor(Black);
  Fill(1,1,20,_MAXY+1);
  Fill(61,1,20,_MAXY+1);

  TextBackground(Black);

  Fill(21,1,39,_MAXY+1);
  //TextColor(White);

  TextBackground(White);
  Fill(20,1,41,5);

  TextBackground(White);
  Fill(21,_MAXY-4,41,_MAXY+1);

  GotoXY(1,1);
  TextBackground(Black);

  TextColor(Yellow);
  GotoXY(35,9);
  Write(' SURVIVAL');
  GotoXY(22,12);
  TextColor(DarkGray);
  Write(StringOfChar('_',38));
  TextColor(White);
  GotoXY(35,16);
  Write(' NORMALNY');
end;

procedure GameModeMenu;
begin
  DrawGameModeMenu;
  GameMenuProcess;
end;

procedure SPSettings;
begin
  MaxX:=_MaxX;
  MaxY:=_MaxY;
  LowX:=_LowX;
  LowY:=_LowY;
  StartX:=_StartX;
  StartY:=_StartY;
  GameSpeed:=GameSpeedBegin;
  GameTime:=0;
  AppleCollected:=0;
  Quit:=False;
  Lose:=False;
  Direction:=Right;
  StartLen:=_StartLen;
  DefaultGameColors;
end;

procedure SingleGame;
var
  tmp: dword;
  Chr: Integer;
begin
  GameModeMenu;
  TextBackground(GBGColor);
  ClrScr;
  InitSnake;
  DrawFrame;
  DrawScore;
  DrawApple;
  if(SurvivalMode)then
    DrawGameSpeed;
  DrawTime;
  DrawScoreCount;
  GotoXY(1,1);
  CreateThread(nil,0,@GameThread,nil,0,tmp);
  CreateThread(nil,0,@TimeThread,nil,0,tmp);
  chr:=0;
  repeat
    if(chr=72)then if not(Direction=Down)then
      Direction:=Up;
    if(chr=80)then if not(Direction=Up)then
      Direction:=Down;
    if(chr=75)then if not(Direction=Right)then
      Direction:=Left;
    if(chr=77)then if not(Direction=Left)then
      Direction:=Right;
    if(chr=$20)then
      Pause:=not Pause;
    if(chr=$1B)then begin
      Quit:=True;
      Sleep(500);
      Break;
    end;
    Chr:=Ord(ReadKey);
    ShowCursor(false);
    Sleep(GetProcentEx(65,GameSpeed));
    if(Lose)then begin
      Sleep(500);
      repeat
        if(ReadKey=#13)then Break;
      until(false);
      Break;
    end;
  until(false);
  GameSpeed:=GameSpeedBegin;
  GameTime:=0;
  AppleCollected:=0;
  Quit:=False;
  Lose:=False;
  Direction:=Right;
  StartLen:=_StartLen;
  Score:=0;
  ShowCursor(false);
end;

procedure IntroColors;
begin
  HeadColor:=LightRed;
  BodyColor:=Red;
end;

procedure IntroSettings;
begin
  SPSettings;
  IntroColors;
  StartY:=14;
  StartX:=1;
  MaxX:=80;
  LowX:=1;
  MaxY:=15;
  LowY:=1;
  StartLen:=8;
  Direction:=Right;
  Trace:=False;
end;

procedure IntroEat;
var
  Del: Boolean;
begin
  IntroSettings;
  InitSnake;
  Del:=False;
  repeat
    DrawSnake;
    if(Del)then begin
      TextColor(Black);
      TextBackground(Black);
      GotoXY(1,14);
      Write(StringOfChar(' ',Snake[0].X+10));
    end;
    Sleep(20);
    if(Snake[0].X=__MAXX)then
      Del:=True;
    if(Snake[Length(Snake)-1].X=__MAXX)then begin
      GotoXY(1,14);
      ClrEol;
      Sleep(350);
      Break;
    end;
  until(not IncPosition);
end;

procedure Intro;
begin
  TextBackground(Black);
  ClrScr;
  GotoXY(35,14);
  TextColor(LightBlue);
  Write('BY TSCRIPTER');
  ShowCursor(False);
  Sleep(600);
  IntroEat;
  SPSettings;
  ClrScr;
end;

procedure DrawMenuSnakes;
begin

end;

procedure DrawMenu;
begin

  TextBackground(White);
  TextColor(Black);
  Fill(1,1,20,_MAXY+1);
  Fill(61,1,20,_MAXY+1);

  TextBackground(Black);
  TextColor(Black);
  Fill(21,1,39,_MAXY+1);

  TextBackground(White);
  Fill(20,1,41,3);

  TextBackground(White);
  Fill(21,_MAXY,41,_MAXY+1);

  DrawMenuSnakes;

  GotoXY(1,1);
  TextBackground(Black);

  GotoXY(35,6);
  TextColor(Yellow);
  Write('SINGLE PLAYER');
  GotoXY(22,8);
  TextColor(DarkGray);
  Write(StringOfChar('_',38));

  TextColor(White);
  GotoXY(35,11);
  Write(' MULTIPLAYER');
  GotoXY(22,13);
  TextColor(DarkGray);
  Write(StringOfChar('_',38));

  TextColor(White);
  GotoXY(35,16);
  Write('    OPCJE');
  GotoXY(22,18);
  TextColor(DarkGray);
  Write(StringOfChar('_',38));

  TextColor(White);
  GotoXY(35,21);
  Write('   WYJSCIE');
  GotoXY(22,23);
  //TextColor(DarkGray);
  //Write(StringOfChar('_',38));

end;

procedure DeSelectMenu(MenuOpt: Integer);
begin
  TextBackground(Black);
  TextColor(White);
  case MenuOpt of
    1: begin
      GotoXY(35,6);
      Write('SINGLE PLAYER');
    end;
    2: begin
      GotoXY(35,11);
      Write(' MULTIPLAYER');
    end;
    3: begin
      GotoXY(35,16);
      Write('    OPCJE');
    end;
    4: begin
      GotoXY(35,21);
      Write('   WYJSCIE');
    end;
  end;
end;

procedure SelectMenu(MenuOpt: Integer);
begin
  TextBackground(Black);
  TextColor(Yellow);
  case MenuOpt of
    1: begin
      GotoXY(35,6);
      Write('SINGLE PLAYER');
    end;
    2: begin
      GotoXY(35,11);
      Write(' MULTIPLAYER');
    end;
    3: begin
      GotoXY(35,16);
      Write('    OPCJE');
    end;
    4: begin
      GotoXY(35,21);
      Write('   WYJSCIE');
    end;
  end;
end;

procedure ExecuteOption(Opt: Integer);
begin
  case Opt of
    1: begin
      SingleGame;
    end;
    4: begin
      Halt(0);
    end;
  end;
end;

procedure Menu;
label
  Rep;
var
  MenuOpt: Integer;
  Chr: Char;
begin
  Rep:
  DrawMenu;
  MenuOpt:=1;
  repeat
    Chr:=ReadKey;
    if(Ord(Chr)=9)then Chr:=#80;
    if(Chr=' ')then Chr:=#13;
    case Ord(Chr) of
      72: begin    // UP
        DeSelectMenu(MenuOpt);
        if(MenuOpt=1)then
          MenuOpt:=4
        else
          Dec(MenuOpt);
        SelectMenu(MenuOpt);
      end;
      80: begin  // Down
        DeSelectMenu(MenuOpt);
        if(MenuOpt=4)then
          MenuOpt:=1
        else
          Inc(MenuOpt);
        SelectMenu(MenuOpt);
      end;
      13: begin // Execute
        ExecuteOption(MenuOpt);
        goto Rep;
      end;
    end;

  until(false);
end;

begin
  ConHandle := GetConOutputHandle;
  HighVideo;
  Intro;
  SPSettings;
  repeat
    SingleGame;
  until(false);
  //Menu;
end.
