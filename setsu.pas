unit setsu;

interface
uses Windows, Controls, Forms, Classes, SysUtils, Registry, gfx, toolu;

type
  _SetsContainer = record
    CellSize: integer;
    Border: integer;
    Space: integer;
    Radius: integer;
    Columns: integer;
    PrevMonths: integer;
    NextMonths: integer;
    MonthShift: integer;
    BaseAlpha: integer;
    Blur: boolean;
    Position: integer;
    Font: _FontData;
    TodayMarkColor: cardinal;
    FillToday: boolean;
  end;

  _Sets = class
  public
    FirstRun: boolean;
    X: integer;
    Y: integer;
    container: _SetsContainer;
    cancel_container: _SetsContainer;
    constructor Create;
    procedure Load;
    procedure Save;
    procedure StoreSetsContainer;
    procedure RestoreSetsContainer;
    procedure CopySetsContainer(var dst: _SetsContainer; var src: _SetsContainer);
end;

var
  sets: _Sets;

implementation
//------------------------------------------------------------------------------
constructor _Sets.Create;
begin
  inherited Create;
end;
//------------------------------------------------------------------------------
procedure _Sets.Load;
var
  reg: TRegistry;
begin
  // defaults //
  FirstRun := true;
  X := -100;
  Y := -100;
  container.CellSize := 28;
  container.Border := 14;
  container.Space := 14;
  container.Radius := 0;
  container.Columns := 1;
  StrCopy(container.Font.name, pchar(toolu.GetFont));
  container.Font.size := 12;
  container.Font.color := $ffd0d0d0;
  container.Font.color2 := $ffff0000;
  container.Font.bold := true;
  container.Font.italic := false;
  container.BaseAlpha := 10;
  container.Blur := true;
  container.PrevMonths := 1;
  container.NextMonths := 1;
  container.MonthShift := 0;
  container.Position := 1;
  container.TodayMarkColor := $ff646464;
  container.FillToday := false;

  // load sets //
  reg := TRegistry.Create;
  reg.RootKey := HKEY_CURRENT_USER;
  if reg.OpenKey('Software\Holmes\Descal', false) then
  begin
    try
      X := SetRange(reg.ReadInteger('X'), -10000, 10000);
      Y := SetRange(reg.ReadInteger('Y'), -10000, 10000);
    except end;
    try
      container.CellSize := SetRange(reg.ReadInteger('CellSize'), 10, 50);
      container.Border := SetRange(reg.ReadInteger('Border'), 0, 40);
      container.Columns := SetRange(reg.ReadInteger('Columns'), 1, 12);
      container.BaseAlpha := SetRange(reg.ReadInteger('BaseAlpha'), 0, 255);
      container.Blur := reg.ReadBool('Blur');
      container.PrevMonths := SetRange(reg.ReadInteger('PrevMonths'), -11, 11);
      container.NextMonths := SetRange(reg.ReadInteger('NextMonths'), -11, 11);
      container.Position := SetRange(reg.ReadInteger('Position'), 0, 2);
      container.TodayMarkColor := uint(reg.ReadInteger('TodayMarkColor'));
      container.FillToday := reg.ReadBool('FillToday');
    except end;
    // font //
    try
      StrCopy(container.Font.name, pchar(reg.ReadString('FontName')));
      container.Font.size := SetRange(reg.ReadInteger('FontSize'), 6, 72);
      container.Font.color := uint(reg.ReadInteger('FontColor'));
      container.Font.color2 := uint(reg.ReadInteger('FontColor2'));
      container.Font.bold := reg.ReadBool('FontBold');
      container.Font.italic := reg.ReadBool('FontItalic');
    except end;
    FirstRun := false;
    reg.CloseKey;
  end;
  // finalization //
  reg.free;
end;
//------------------------------------------------------------------------------
procedure _Sets.Save;
var
  reg: TRegistry;
begin
  reg := TRegistry.Create;
  reg.RootKey := HKEY_CURRENT_USER;
  if reg.OpenKey('Software\Holmes\Descal', true) then
  begin
    reg.WriteInteger('X', X);
    reg.WriteInteger('Y', Y);
    reg.WriteInteger('CellSize', container.CellSize);
    reg.WriteInteger('Border', container.Border);
    reg.WriteInteger('Radius', container.Radius);
    reg.WriteInteger('Columns', container.Columns);
    reg.WriteBool('Blur', container.Blur);
    reg.WriteInteger('BaseAlpha', container.BaseAlpha);
    reg.WriteInteger('PrevMonths', container.PrevMonths);
    reg.WriteInteger('NextMonths', container.NextMonths);
    reg.WriteInteger('Position', container.Position);
    reg.WriteInteger('TodayMarkColor', container.TodayMarkColor);
    reg.WriteBool('FillToday', container.FillToday);
    // font //
    reg.WriteString('FontName', pchar(@container.Font.name[0]));
    reg.WriteInteger('FontSize', container.Font.size);
    reg.WriteInteger('FontColor', container.Font.color);
    reg.WriteInteger('FontColor2', container.Font.color2);
    reg.WriteBool('FontBold', container.Font.bold);
    reg.WriteBool('FontItalic', container.Font.italic);
    reg.CloseKey;
  end;
  reg.free;
end;
//------------------------------------------------------------------------------
procedure _Sets.StoreSetsContainer;
begin
  CopySetsContainer(cancel_container, container);
end;
//------------------------------------------------------------------------------
procedure _Sets.RestoreSetsContainer;
begin
  CopySetsContainer(container, cancel_container);
end;
//------------------------------------------------------------------------------
procedure _Sets.CopySetsContainer(var dst: _SetsContainer; var src: _SetsContainer);
begin
  dst.CellSize := src.CellSize;
  dst.Border := src.Border;
  dst.Space := src.Space;
  dst.Radius := src.Radius;
  dst.Columns := src.Columns;
  dst.BaseAlpha := src.BaseAlpha;
  dst.Blur := src.Blur;
  dst.PrevMonths := src.PrevMonths;
  dst.NextMonths := src.NextMonths;
  dst.MonthShift := src.MonthShift;
  dst.Position := src.Position;
  dst.TodayMarkColor := src.TodayMarkColor;
  dst.FillToday := src.FillToday;
  CopyFontData(src.Font, dst.Font);
end;
//------------------------------------------------------------------------------
end.
