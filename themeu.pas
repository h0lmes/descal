unit themeu;

interface

uses Windows, Classes, SysUtils, Forms, Dialogs, StdCtrls, IniFiles,
  ActiveX, GDIPAPI, declu, gdip_gfx;

type
  PLayer = ^TLayer;
  TLayer = record
    Image: Pointer;
    W: uint;
    H: uint;
    Margins: Windows.TRect;
    StretchStyle: TStretchStyle;
    Area: Windows.TRect;
  end;

  TLayerSep = record
    Image: Pointer;
    W: uint;
    H: uint;
    Margins: Windows.TRect;
  end;

  TLayerImage = record
    Image: Pointer;
    W: uint;
    H: uint;
  end;

  _Theme = class
  private
    BaseCmd: TBaseCmd;
  public
    is_default: boolean;
    Background: TLayer;
    Separator: TLayerSep;
    Indicator: TLayerImage;
    Stack: TLayerImage;
    DropIndicatorAdd: TLayerImage;
    DropIndicatorRun: TLayerImage;
    ReflectionSize: integer;
    MinHeight: integer;
    ItemArea: Windows.TRect;
    VResize: boolean;
    BlurArea: Windows.TRect;
    BlurR: Windows.TSize;
    Blur: boolean;
    Path: string;

    constructor Create(ABaseCmd: TBaseCmd);
    destructor Destroy; override;
    procedure Clear;
    procedure ClearGraphics;
    procedure DoThemeChanged;
    procedure DoBaseDraw;
    function Load: boolean;

    procedure ReloadGraphics;
    function Save: boolean;
    procedure ImageAdjustRotate(image: Pointer);
    procedure SetTheme(atheme: string);
    function CorrectMargins(margins: Windows.TRect): Windows.TRect;
    function CorrectSize(size: Windows.TSize): Windows.TSize;
    procedure DrawBackground(hGDIPGraphics: Pointer; r: GDIPAPI.TRect; color_data: integer);
    function GetBackgroundRgn(r: GDIPAPI.TRect): HRGN;

    procedure MakeDefaultTheme;
    procedure CheckExtractFileFromResource(ResourceName: PChar; Filename: string);
    procedure ExtractFileFromResource(ResourceName: PChar; Filename: string);
    procedure SearchThemes(ThemeName: string; cb: TComboBox);
  end;

var
  theme: _Theme;

implementation

uses setsu, toolu;
//------------------------------------------------------------------------------
constructor _Theme.Create(ABaseCmd: TBaseCmd);
begin
  BaseCmd := ABaseCmd;
  Clear;
  ClearGraphics;

  CheckExtractFileFromResource('DEFAULT_ICON', UnzipPath('%pp%\default.png'));
  CheckExtractFileFromResource('DEFAULT_BACKGROUND', UnzipPath('%pp%\themes\background.png'));
  CheckExtractFileFromResource('DEFAULT_SEPARATOR', UnzipPath('%pp%\themes\separator.png'));
  CheckExtractFileFromResource('DEFAULT_INDICATOR', UnzipPath('%pp%\themes\indicator.png'));
  CheckExtractFileFromResource('DEFAULT_DROPINDICATOR_ADD', UnzipPath('%pp%\themes\dropindicator_add.png'));
  CheckExtractFileFromResource('DEFAULT_DROPINDICATOR_RUN', UnzipPath('%pp%\themes\dropindicator_run.png'));
  CheckExtractFileFromResource('DEFAULT_STACK', UnzipPath('%pp%\themes\stack.png'));
end;
//------------------------------------------------------------------------------
procedure _Theme.Clear;
begin
  ItemArea := rect(0, 0, 0, 0);
  ReflectionSize := 0;
  MinHeight := 0;
  Separator.Margins := rect(0, 0, 0, 0);
end;
//------------------------------------------------------------------------------
procedure _Theme.ClearGraphics;
begin
  if Indicator.image <> nil then
  begin
    try GdipDisposeImage(Indicator.image);
    except end;
    Indicator.image := nil;
  end;

  if Separator.image <> nil then
  begin
    try GdipDisposeImage(Separator.image);
    except end;
    Separator.image := nil;
  end;

  if Stack.image <> nil then
  begin
    try GdipDisposeImage(Stack.image);
    except end;
    Stack.image := nil;
  end;

  if DropIndicatorAdd.image <> nil then
  begin
    try GdipDisposeImage(DropIndicatorAdd.image);
    except end;
    DropIndicatorAdd.image := nil;
  end;

  if DropIndicatorRun.image <> nil then
  begin
    try GdipDisposeImage(DropIndicatorRun.image);
    except end;
    DropIndicatorRun.image := nil;
  end;

  if Background.image <> nil then
  begin
    try GdipDisposeImage(Background.image);
    except end;
    Background.image := nil;
  end;
end;
//------------------------------------------------------------------------------
procedure _Theme.DoThemeChanged;
begin
  BaseCmd(tcThemeChanged, 0);
end;
//------------------------------------------------------------------------------
procedure _Theme.DoBaseDraw;
begin
  BaseCmd(tcRepaintBase, 1);
end;
//------------------------------------------------------------------------------
procedure _Theme.SetTheme(aTheme: string);
begin
  StrCopy(sets.container.ThemeName, PChar(aTheme));
  Load;
  DoThemeChanged;
end;
//------------------------------------------------------------------------------
function _Theme.Load: boolean;
var
  ini: TIniFile;
begin
  Result := false;
  is_default := false;

  Clear;

  // default theme //

  if not DirectoryExists(toolu.UnzipPath('%pp%\themes\') + PChar(@sets.container.ThemeName) + '\') then StrCopy(sets.container.ThemeName, 'Aero');
  if not DirectoryExists(toolu.UnzipPath('%pp%\themes\') + PChar(@sets.container.ThemeName) + '\') then
  begin
    MakeDefaultTheme;
    Result := True;
    exit;
  end;

  // loading theme data //

  try
    Path := toolu.UnzipPath('%pp%\themes\') + PChar(@sets.container.ThemeName) + '\';

    ini := TIniFile.Create(Path + 'theme.ini');
    // general //
    ItemArea := StringToRect(ini.ReadString('general', 'items_area', ''));
    ReflectionSize := StrToInt(ini.ReadString('general', 'reflection_size', '0'));
    MinHeight := ini.ReadInteger('general', 'min_height', 0);
    VResize := ini.ReadInteger('general', 'vresize', 1) <> 0;
    Separator.Margins := StringToRect(ini.ReadString('general', 'separator_margins', ''));
    // aero //
    Blur := boolean(ini.ReadInteger('aero', 'enabled', 0));
    BlurArea := StringToRect(ini.ReadString('aero', 'area', ''));
    BlurR := StringToSize(ini.ReadString('aero', 'radius', ''));
    // background //
    Background.StretchStyle := StringToStretchStyle(ini.ReadString('background', 'style', ''));
    Background.Margins := StringToRect(ini.ReadString('background', 'margins', ''));
    Background.Area := StringToRect(ini.ReadString('background', 'area', ''));

    ini.Free;
    ReloadGraphics;
    Result := True;
  except
    on e: Exception do raise Exception.Create('Error loading theme'#13#10#13#10 + e.message);
  end;
end;
//------------------------------------------------------------------------------
procedure _Theme.ReloadGraphics;
var
  img: Pointer;
begin
  ClearGraphics;

  try
    // background image //
    try
      if FileExists(Path + 'background.png') then
        GdipLoadImageFromFile(PWideChar(WideString(Path + 'background.png')), Background.Image);
      if Background.image = nil then
        GdipLoadImageFromFile(PWideChar(WideString(UnzipPath('%pp%\themes\background.png'))), Background.Image);
      if Background.image <> nil then
      begin
        ImageAdjustRotate(Background.Image);
        GdipGetImageWidth(Background.Image, Background.W);
        GdipGetImageHeight(Background.Image, Background.H);
        GdipCloneBitmapAreaI(0, 0, Background.W, Background.H, PixelFormat32bppPARGB, Background.Image, img);
        GdipDisposeImage(Background.Image);
        Background.Image := img;
        img := nil;
      end;
    except
      on e: Exception do raise Exception.Create('Error loading background: ' + Path + 'background.png' + #13#10#13#10 + e.message);
    end;

    // separator //
    try
      if FileExists(Path + 'separator.png') then
        GdipLoadImageFromFile(PWideChar(WideString(Path + 'separator.png')), Separator.Image);
      { no default image. maybe it should be }
      if Separator.Image <> nil then
      begin
        ImageAdjustRotate(Separator.Image);
        GdipGetImageWidth(Separator.Image, Separator.W);
        GdipGetImageHeight(Separator.Image, Separator.H);
      end;
    except
      on e: Exception do raise Exception.Create('Error loading separator: ' + Path + 'separator.png' + #13#10#13#10 + e.message);
    end;

    // stack default icon //
    try
      if FileExists(Path + 'stack.png') then
        GdipLoadImageFromFile(PWideChar(WideString(Path + 'stack.png')), Stack.Image);
      if Stack.image = nil then
        GdipLoadImageFromFile(PWideChar(WideString(UnzipPath('%pp%\themes\stack.png'))), Stack.Image);
      if Stack.Image <> nil then
      begin
        GdipGetImageWidth(Stack.Image, Stack.W);
        GdipGetImageHeight(Stack.Image, Stack.H);
      end;
    except
      on e: Exception do raise Exception.Create('Error loading stack icon: ' + Path + 'stack.png' + #13#10#13#10 + e.message);
    end;

    // running indicator //
    try
      if FileExists(Path + 'indicator.png') then
        GdipLoadImageFromFile(PWideChar(WideString(Path + 'indicator.png')), Indicator.Image);
      if Indicator.image = nil then
        GdipLoadImageFromFile(PWideChar(WideString(UnzipPath('%pp%\themes\indicator.png'))), Indicator.Image);
      if Indicator.Image <> nil then
      begin
        ImageAdjustRotate(Indicator.Image);
        GdipGetImageWidth(Indicator.Image, Indicator.W);
        GdipGetImageHeight(Indicator.Image, Indicator.H);
      end;
    except
      on e: Exception do raise Exception.Create('Error loading indicator: ' + Path + 'indicator.png' + #13#10#13#10 + e.message);
    end;

    // drop indicator add //
    try
      if FileExists(Path + 'dropindicator_add.png') then
        GdipLoadImageFromFile(PWideChar(WideString(Path + 'dropindicator_add.png')), DropIndicatorAdd.Image);
      if DropIndicatorAdd.image = nil then
        GdipLoadImageFromFile(PWideChar(WideString(UnzipPath('%pp%\themes\dropindicator_add.png'))), DropIndicatorAdd.Image);
      if DropIndicatorAdd.Image <> nil then
      begin
        GdipGetImageWidth(DropIndicatorAdd.Image, DropIndicatorAdd.W);
        GdipGetImageHeight(DropIndicatorAdd.Image, DropIndicatorAdd.H);
      end;
    except
      on e: Exception do raise Exception.Create('Error loading drop indicator add: ' + Path + 'dropindicator_add.png' + #13#10#13#10 + e.message);
    end;

    // drop indicator run //
    try
      if FileExists(Path + 'dropindicator_run.png') then
        GdipLoadImageFromFile(PWideChar(WideString(Path + 'dropindicator_run.png')), DropIndicatorRun.Image);
      if DropIndicatorRun.image = nil then
        GdipLoadImageFromFile(PWideChar(WideString(UnzipPath('%pp%\themes\dropindicator_run.png'))), DropIndicatorRun.Image);
      if DropIndicatorRun.Image <> nil then
      begin
        GdipGetImageWidth(DropIndicatorRun.Image, DropIndicatorRun.W);
        GdipGetImageHeight(DropIndicatorRun.Image, DropIndicatorRun.H);
      end;
    except
      on e: Exception do raise Exception.Create('Error loading drop indicator run: ' + Path + 'dropindicator_run.png' + #13#10#13#10 + e.message);
    end;

  except
    on e: Exception do raise Exception.Create('Error loading theme files. ' + e.message);
  end;
end;
//------------------------------------------------------------------------------
function _Theme.Save: boolean;
var
  ini: TIniFile;
  themes_path: string;
begin
  result := false;
  themes_path := toolu.UnzipPath('%pp%\themes\');

  if not DirectoryExists(themes_path) then CreateDirectory(PChar(themes_path), nil);

  if PChar(@sets.container.ThemeName) = '' then StrCopy(sets.container.ThemeName, 'Aero');
  if not DirectoryExists(themes_path + PChar(@sets.container.ThemeName) + '\') then
    CreateDirectory(PChar(themes_path + PChar(@sets.container.ThemeName) + '\'), nil);

  try
    windows.DeleteFile(PChar(themes_path + PChar(@sets.container.ThemeName) + '\theme.ini'));

    ini := TIniFile.Create(themes_path + PChar(@sets.container.ThemeName) + '\theme.ini');
    // general //
    ini.WriteString('general', 'items_area', RectToString(ItemArea));
    ini.WriteString('general', 'reflection_size', IntToStr(ReflectionSize));
    ini.WriteInteger('general', 'min_height', MinHeight);
    ini.WriteInteger('general', 'vresize', integer(VResize));
    ini.WriteString('general', 'separator_margins', RectToString(Separator.Margins));
    // aero //
    ini.WriteInteger('aero', 'enabled', integer(Blur));
    ini.WriteString('aero', 'area', RectToString(BlurArea));
    ini.WriteString('aero', 'radius', SizeToString(BlurR));
    // background //
    ini.WriteString('background', 'margins', RectToString(Background.Margins));
    ini.WriteString('background', 'area', RectToString(Background.Area));
    ini.WriteString('background', 'style', gdip_gfx.StretchStyleToString(Background.StretchStyle));

    ini.Free;
    result := true;
  except
    on e: Exception do raise Exception.Create('Error saving theme'#13#10#13#10 + e.message);
  end;
end;
//------------------------------------------------------------------------------
procedure _Theme.ImageAdjustRotate(image: Pointer);
begin
  if image <> nil then
  begin
    if sets.container.site = bsLeft then GdipImageRotateFlip(image, Rotate90FlipNone)
    else if sets.container.site = bsTop then GdipImageRotateFlip(image, Rotate180FlipX)
    else if sets.container.site = bsRight then GdipImageRotateFlip(image, Rotate270FlipNone);
  end;
end;
//------------------------------------------------------------------------------
function _Theme.CorrectMargins(margins: Windows.TRect): Windows.TRect;
var
  tmpSite: TBaseSite;
begin
  Result := margins;

  tmpSite := sets.container.site;
  if tmpSite = bsLeft then
  begin
    Result.Left := margins.Bottom;
    Result.Top := margins.Left;
    Result.Right := margins.Top;
    Result.Bottom := margins.Right;
  end
  else if tmpSite = bsTop then
  begin
    Result.Top := margins.Bottom;
    Result.Bottom := margins.Top;
  end
  else if tmpSite = bsRight then
  begin
    Result.Left := margins.Top;
    Result.Top := margins.Right;
    Result.Right := margins.Bottom;
    Result.Bottom := margins.Left;
  end;
end;
//------------------------------------------------------------------------------
function _Theme.CorrectSize(size: Windows.TSize): Windows.TSize;
begin
  Result := size;
  if (sets.container.site = bsLeft) or (sets.container.site = bsRight) then
  begin
    Result.cx := size.cy;
    Result.cy := size.cx;
  end;
end;
//------------------------------------------------------------------------------
procedure _Theme.DrawBackground(hGDIPGraphics: Pointer; r: GDIPAPI.TRect; color_data: integer);
var
  area: Windows.TRect;
  marg: Windows.TRect;
begin
  area := CorrectMargins(Background.Area);
  marg := CorrectMargins(Background.Margins);
  gdip_gfx.DrawEx(hGDIPGraphics, Background.Image, Background.W, Background.H,
    rect(r.X + area.left, r.Y + area.top, r.Width - area.right - area.left, r.Height - area.bottom - area.top),
    marg, Background.StretchStyle, color_data);
end;
//------------------------------------------------------------------------------
function _Theme.GetBackgroundRgn(r: GDIPAPI.TRect): HRGN;
var
  ba: Windows.TRect;
  br: Windows.TSize;
begin
  Result := 0;
  if Blur then
  begin
    ba := CorrectMargins(BlurArea);
    br := CorrectSize(BlurR);
    Result := CreateRoundRectRgn(r.x + ba.Left, r.y + ba.Top, r.x + r.Width - ba.Right, r.y + r.Height - ba.Bottom, br.cx, br.cy);
  end;
end;
//------------------------------------------------------------------------------
procedure _Theme.MakeDefaultTheme;
begin
  is_default := True;

  Background.Margins := rect(15, 15, 15, 2);
  Background.Area := rect(0, 0, 0, 0);
  Background.StretchStyle := ssStretch;

  Separator.Margins := rect(0, 0, 0, 0);

  ItemArea := rect(16, 11, 16, 3);
  ReflectionSize := 0;
  MinHeight := 0;

  Path := '';
  ReloadGraphics;
end;
//------------------------------------------------------------------------------
procedure _Theme.CheckExtractFileFromResource(ResourceName: PChar; filename: string);
begin
  if not FileExists(filename) then ExtractFileFromResource(ResourceName, filename);
end;
//------------------------------------------------------------------------------
procedure _Theme.ExtractFileFromResource(ResourceName: PChar; filename: string);
var
  rs: TResourceStream;
  fs: TFileStream;
  irs: IStream;
  ifs: IStream;
  Read, written: int64;
begin
  rs := TResourceStream.Create(hInstance, ResourceName, RT_RCDATA);
  fs := TFileStream.Create(filename, fmCreate);
  irs := TStreamAdapter.Create(rs, soReference) as IStream;
  ifs := TStreamAdapter.Create(fs, soReference) as IStream;
  irs.CopyTo(ifs, rs.Size, Read, written);
  if (Read <> written) or (Read <> rs.Size) then
    messagebox(application.mainform.handle, 'Error writing file from resource', 'Terry.Theme.ExtractFileFromResource', 0);
  rs.Free;
  fs.Free;
end;
//------------------------------------------------------------------------------
procedure _Theme.SearchThemes(ThemeName: string; cb: TComboBox);
var
  ThemesDir: string;
  fhandle: HANDLE;
  f: TWin32FindData;
  i: integer;
begin
  ThemesDir := toolu.UnzipPath('%pp%\themes\');
  cb.items.BeginUpdate;
  cb.items.Clear;
  ThemesDir := IncludeTrailingPathDelimiter(ThemesDir);

  fhandle := FindFirstFile(PChar(ThemesDir + '*.*'), f);
  if not (fhandle = HANDLE(-1)) then
    if ((f.dwFileAttributes and 16) = 16) then cb.items.add(AnsiToUTF8(f.cFileName));
  while FindNextFile(fhandle, f) do
    if ((f.dwFileAttributes and 16) = 16) then cb.items.add(AnsiToUTF8(f.cFileName));
  if not (fhandle = HANDLE(-1)) then Windows.FindClose(fhandle);

  i := 0;
  while i < cb.items.Count do
    if (cb.items.strings[i] = '.') or (cb.items.strings[i] = '..') or
      not FileExists(ThemesDir + UTF8ToAnsi(cb.items.strings[i]) + '\theme.ini') then
      cb.items.Delete(i)
    else
      Inc(i);

  cb.ItemIndex := cb.items.indexof(AnsiToUTF8(ThemeName));
  cb.items.EndUpdate;
end;
//------------------------------------------------------------------------------
destructor _Theme.Destroy;
begin
  Clear;
  ClearGraphics;
  inherited;
end;
//------------------------------------------------------------------------------
end.

