unit toolu;

interface

uses Windows, jwaWindows, SysUtils, Variants, Classes,
  Graphics, Controls, Forms, Dialogs, Registry, ComObj, ShlObj;

function IsWindowsVista: boolean;
function IsWin64: boolean;
function GetFont: string;
function GetContentFont: string;
function GetFontSize: integer;
function GetContentFontSize: integer;
function CreateAFont(Name: string; size: integer): HFont;
function cut(itext, ch: string): string;
function cutafter(itext, ch: string): string;
function ReplaceEx(strSrc, strWhat, strWith: string): string;
function fetch(var itext: string; delim: string; adelete: boolean = False): string;
function FetchValue(itext: string; Value, delim: string): string;
function PosEx(Value, atext: string; startpos: integer): integer;
function cuttolast(itext, ch: string): string;
function cutafterlast(itext, ch: string): string;
function StringToRect(str: string): Windows.Trect;
function RectToString(r: Windows.Trect): string;
function StringToSize(str: string): Windows.TSize;
function SizeToString(r: Windows.TSize): string;
function StringToPoint(str: string): Windows.Tpoint;
function SetRange(value, min, max: integer): integer;
procedure searchfiles(path, mask: string; list: TStrings);
procedure searchfolders(path: string; list: TStrings);
procedure searchfilesrecurse(path, mask: string; list: TStrings;
  level: cardinal = 0; maxlevel: cardinal = 255; maxcount: integer = $7fffffff);
function ReadIniString(IniFile, IniSection, KeyName, Default: string): string;
function ReadIniInteger(IniFile, IniSection, KeyName: string; Default: integer): integer;
function CheckAutoRun: boolean;
procedure SetAutoRun(enable: boolean);
function GetWinVersion: string;
procedure GetFileVersion(filename: string; var maj, min, Release, build: integer);
function GetEnvVar(VarName: string): string;
function UnzipPath(path: string): string;
function ZipPath(path: string): string;
function GetSystemDir: string;
function GetWinDir: string;
function GetSystemPath(path: string): string;
function BrowseFolder(hWnd: THandle; title, default: string): string;
procedure FreeAndNil(var Obj);
procedure SetClipboard(Text: string);
function GetClipboard: string;
function ColorToString(Color: uint): string;
function StringToColor(const str: string): uint;
function confirm(handle: cardinal; Text: string = ''): boolean;
procedure AddLog(LogString: string);
procedure TruncLog(fs: TFileStream);

implementation
//------------------------------------------------------------------------------
function IsWindowsVista: boolean;
var
  VerInfo: TOSVersioninfo;
begin
  VerInfo.dwOSVersionInfoSize := sizeof(TOSVersionInfo);
  GetVersionEx(@VerInfo);
  Result := VerInfo.dwMajorVersion >= 6;
end;
//------------------------------------------------------------------------------
function IsWin64: boolean;
var
  IsWow64Process: function(Handle: THandle; var Res: boolean): boolean; stdcall;
  res: boolean;
begin
  res := False;
  IsWow64Process := GetProcAddress(GetModuleHandle(Kernel32), 'IsWow64Process');
  if assigned(IsWow64Process) then IsWow64Process(GetCurrentProcess, res);
  Result := res;
end;
//------------------------------------------------------------------------------
function GetFont: string;
begin
  Result := 'tahoma';
  try
    if IsWindowsVista then Result := 'segoe ui';
  except
  end;
end;
//------------------------------------------------------------------------------
function GetContentFont: string;
begin
  Result := 'verdana';
  try
    if IsWindowsVista then Result := 'calibri';
  except
  end;
end;
//------------------------------------------------------------------------------
function GetFontSize: integer;
begin
  Result := 8;
  try
    if IsWindowsVista then Result := 9;
  except
  end;
end;
//------------------------------------------------------------------------------
function GetContentFontSize: integer;
begin
  Result := 8;
  try
    if IsWindowsVista then Result := 10;
  except
  end;
end;
//------------------------------------------------------------------------------
function CreateAFont(Name: string; size: integer): HFont;
begin
  Result := CreateFont(size, 0, 0, 0, 0, 0, 0, 0, DEFAULT_CHARSET, 0,
    0, PROOF_QUALITY, 0, PChar(Name));
end;
//------------------------------------------------------------------------------
function cut(itext, ch: string): string;
var
  ipos: integer;
begin
  ipos := pos(AnsiLowerCase(ch), AnsiLowerCase(itext));
  if ipos > 0 then
    Result := copy(itext, 1, ipos - 1)
  else
    Result := itext;
end;
//------------------------------------------------------------------------------
function cutafter(itext, ch: string): string;
var
  ipos: integer;
begin
  ipos := pos(AnsiLowerCase(ch), AnsiLowerCase(itext));
  if ipos > 0 then
    Result := copy(itext, ipos + length(ch), length(itext))
  else
    Result := '';
end;
//------------------------------------------------------------------------------
function ReplaceEx(strSrc, strWhat, strWith: string): string;
var
  ipos: integer;
begin
  ipos := pos(AnsiLowerCase(strWhat), AnsiLowerCase(strSrc));
  while ipos > 0 do
  begin
    strSrc := copy(strSrc, 1, ipos - 1) + strWith + copy(strSrc,
      ipos + length(strWhat), length(strSrc));
    ipos := pos(AnsiLowerCase(strWhat), AnsiLowerCase(strSrc));
  end;
  Result := strSrc;
end;
//------------------------------------------------------------------------------
function fetch(var itext: string; delim: string; adelete: boolean = False): string;
var
  ipos: integer;
begin
  ipos := pos(AnsiLowerCase(delim), AnsiLowerCase(itext));
  if ipos > 0 then
  begin
    Result := system.copy(itext, 1, ipos - 1);
    if adelete then
      system.Delete(itext, 1, ipos - 1 + length(delim));
  end
  else
  begin
    Result := itext;
    itext := '';
  end;
end;
//------------------------------------------------------------------------------
function FetchValue(itext: string; Value, delim: string): string;
var
  ipos, ipos2: integer;
begin
  ipos := pos(AnsiLowerCase(Value), AnsiLowerCase(itext));
  if ipos > 0 then
  begin
    ipos2 := posex(delim, itext, ipos + length(Value));
    Result := system.copy(itext, ipos + length(Value), ipos2 - ipos - length(Value));
  end
  else
    Result := '';
end;
//------------------------------------------------------------------------------
function PosEx(Value, atext: string; startpos: integer): integer;
begin
  Result := startpos;
  if Value = '' then exit;

  while Result <= length(atext) do
  begin
    if AnsiLowerCase(atext[Result]) = AnsiLowerCase(Value[1]) then
      if AnsiLowerCase(copy(atext, Result, length(Value))) = AnsiLowerCase(Value) then
        exit;
    Inc(Result);
  end;
end;
//------------------------------------------------------------------------------
function cuttolast(itext, ch: string): string;
var
  i, len: integer;
begin
  Result := '';
  if itext = '' then
    exit;

  i := length(itext);
  len := length(ch);
  while i > 0 do
  begin
    if AnsiLowerCase(copy(itext, i, len)) = AnsiLowerCase(ch) then
    begin
      Result := copy(itext, 1, i - 1);
      exit;
    end;
    Dec(i);
  end;
  Result := itext;
end;
//------------------------------------------------------------------------------
function cutafterlast(itext, ch: string): string;
var
  i, ilen, len: integer;
begin
  Result := '';
  if itext = '' then
    exit;

  ilen := length(itext);
  i := ilen;
  len := length(ch);
  while i > 0 do
  begin
    if AnsiLowerCase(copy(itext, i, len)) = AnsiLowerCase(ch) then
    begin
      Result := copy(itext, i + len, ilen);
      exit;
    end;
    Dec(i);
  end;
  Result := itext;
end;
//------------------------------------------------------------------------------
function StringToRect(str: string): Windows.Trect;
begin
  Result := rect(0, 0, 0, 0);
  try
    Result.left := StrToInt(trim(fetch(str, ',', True)));
  except
  end;
  try
    Result.top := StrToInt(trim(fetch(str, ',', True)));
  except
  end;
  try
    Result.right := StrToInt(trim(fetch(str, ',', True)));
  except
  end;
  try
    Result.bottom := StrToInt(trim(fetch(str, ')')));
  except
  end;
end;
//------------------------------------------------------------------------------
function RectToString(r: Windows.Trect): string;
begin
  Result := IntToStr(r.left) + ',' + IntToStr(r.top) + ',' + IntToStr(r.right) +
    ',' + IntToStr(r.bottom);
end;
//------------------------------------------------------------------------------
function StringToSize(str: string): Windows.TSize;
begin
  Result.cx := 0;
  Result.cy := 0;
  try
    Result.cx := StrToInt(trim(cut(str, ',')));
    Result.cy := StrToInt(trim(cutafter(str, ',')));
  except
  end;
end;
//------------------------------------------------------------------------------
function SizeToString(r: Windows.TSize): string;
begin
  Result := IntToStr(r.cx) + ',' + IntToStr(r.cy);
end;
//------------------------------------------------------------------------------
function StringToPoint(str: string): Windows.Tpoint;
begin
  Result := point(0, 0);
  try
    Result.x := StrToInt(trim(cut(str, ',')));
    Result.y := StrToInt(trim(cutafter(str, ',')));
  except
  end;
end;
//------------------------------------------------------------------------------
function SetRange(value, min, max: integer): integer;
begin
  if value < min then value := min;
  if value > max then value := max;
  result := value;
end;
//------------------------------------------------------------------------------
procedure searchfiles(path, mask: string; list: TStrings);
var
  fhandle: HANDLE;
  f: TWin32FindData;
begin
  list.Clear;
  path := IncludeTrailingPathDelimiter(path);
  fhandle := FindFirstFile(PChar(path + mask), f);
  if fhandle = INVALID_HANDLE_VALUE then exit;
  if (f.dwFileAttributes and $18) = 0 then list.addobject(f.cFileName, tobject(0));
  while FindNextFile(fhandle, f) do
    if (f.dwFileAttributes and $18) = 0 then list.addobject(f.cFileName, tobject(0));
  if not (fhandle = INVALID_HANDLE_VALUE) then Windows.FindClose(fhandle);
end;
//------------------------------------------------------------------------------
procedure searchfolders(path: string; list: TStrings);
var
  fhandle: THandle;
  filename: string;
  f: TWin32FindData;
begin
  list.Clear;
  path := IncludeTrailingPathDelimiter(path);
  fhandle := FindFirstFile(PChar(path + '*.*'), f);
  if not (fhandle = INVALID_HANDLE_VALUE) then
  begin
    filename := strpas(f.cFileName);
    if ((f.dwFileAttributes and 16) = 16) and (filename <> '.') and (filename <> '..') then
      list.addobject(filename, tobject(0));
    while FindNextFile(fhandle, f) do
    begin
      filename := strpas(f.cFileName);
      if ((f.dwFileAttributes and 16) = 16) and (filename <> '.') and (filename <> '..') then
        list.addobject(filename, tobject(0));
    end;
  end;
  if not (fhandle = INVALID_HANDLE_VALUE) then Windows.FindClose(fhandle);
end;
//------------------------------------------------------------------------------
procedure searchfilesrecurse(path, mask: string; list: TStrings;
  level: cardinal = 0; maxlevel: cardinal = 255; maxcount: integer = $7fffffff);
var
  fhandle: THandle;
  filename: string;
  f: TWin32FindData;
begin
  if level = 0 then list.Clear;
  path := IncludeTrailingPathDelimiter(path);

  // folders //
  fhandle := FindFirstFile(PChar(path + '*.*'), f);
  if not (fhandle = INVALID_HANDLE_VALUE) then
  begin
    filename := strpas(f.cFileName);
    if ((f.dwFileAttributes and 16) = 16) and (filename <> '.') and (filename <> '..') and (level < maxlevel) then
      searchfilesrecurse(path + filename, mask, list, level + 1);
    while FindNextFile(fhandle, f) do
    begin
      filename := strpas(f.cFileName);
      if ((f.dwFileAttributes and 16) = 16) and (filename <> '.') and (filename <> '..') and (level < maxlevel) then
        searchfilesrecurse(path + filename, mask, list, level + 1, maxlevel);
    end;
  end;
  if not (fhandle = INVALID_HANDLE_VALUE) then Windows.FindClose(fhandle);

  // files //
  fhandle := FindFirstFile(PChar(path + mask), f);
  if not (fhandle = INVALID_HANDLE_VALUE) then
  begin
    if ((f.dwFileAttributes and $18) = 0) and (list.Count < maxcount) then list.addobject(path + f.cFileName, tobject(0));
    while FindNextFile(fhandle, f) do
      if ((f.dwFileAttributes and $18) = 0) and (list.Count < maxcount) then list.addobject(path + f.cFileName, tobject(0));
  end;
  if not (fhandle = INVALID_HANDLE_VALUE) then Windows.FindClose(fhandle);
end;
//------------------------------------------------------------------------------
function ReadIniString(IniFile, IniSection, KeyName, Default: string): string;
var
  buf: array [0..1023] of char;
begin
  GetPrivateProfileString(pchar(IniSection), pchar(KeyName), pchar(Default), pchar(@buf), 1024, pchar(IniFile));
  result:= strpas(pchar(@buf));
end;
//------------------------------------------------------------------------------
function ReadIniInteger(IniFile, IniSection, KeyName: string; Default: integer): integer;
var
  buf: array [0..15] of char;
begin
  result:= Default;
  GetPrivateProfileString(pchar(IniSection), pchar(KeyName), pchar(inttostr(Default)), pchar(@buf), 16, pchar(IniFile));
  try result:= strtoint(strpas(pchar(@buf)));
  except end;
end;
//------------------------------------------------------------------------------
function CheckAutoRun: boolean;
var
  reg: Treginifile;
begin
  reg := Treginifile.Create;
  reg.RootKey := HKEY_current_user;
  result := (reg.ReadString('Software\Microsoft\Windows\CurrentVersion\Run', application.title, '') = ParamStr(0));
  reg.Free;
end;
//----------------------------------------------------------------------
procedure SetAutoRun(enable: boolean);
var
  reg: Treginifile;
begin
  reg := Treginifile.Create;
  reg.RootKey := HKEY_current_user;
  reg.lazywrite := False;
  if reg.ReadString('Software\Microsoft\Windows\CurrentVersion\Run', application.title, '') <> '' then
    reg.DeleteKey('Software\Microsoft\Windows\CurrentVersion\Run', application.title);
  if enable then reg.WriteString('Software\Microsoft\Windows\CurrentVersion\Run', application.title, ParamStr(0));
  reg.Free;
end;
//----------------------------------------------------------------------
function GetWinVersion: string;
var
  VersionInfo: Windows.TOSVersionInfo;
begin
  VersionInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
  if Windows.GetVersionEx(VersionInfo) then
  begin
    with VersionInfo do
    begin
      case dwPlatformId of
        VER_PLATFORM_WIN32s: Result := 'Win32s';
        VER_PLATFORM_WIN32_WINDOWS: Result := 'Windows 95';
        VER_PLATFORM_WIN32_NT: Result := 'Windows NT';
      end;
      Result := Result + ' Version ' + IntToStr(dwMajorVersion) + '.' +
        IntToStr(dwMinorVersion) + ' (Build ' + IntToStr(dwBuildNumber) +
        ': ' + szCSDVersion + ')';
    end;
  end
  else
    Result := '';
end;
//----------------------------------------------------------------------
procedure GetFileVersion(filename: string; var maj, min, Release, build: integer);
var
  Info: Pointer;
  InfoSize: DWORD;
  FileInfo: PVSFixedFileInfo;
  FileInfoSize: DWORD;
  Tmp: DWORD;
begin
  maj := 0;
  min := 0;
  Release := 0;
  build := 0;

  filename := UnzipPath(filename);
  InfoSize := GetFileVersionInfoSize(PChar(FileName), Tmp);
  if InfoSize <> 0 then
  begin
    GetMem(Info, InfoSize);
    try
      GetFileVersionInfo(PChar(FileName), 0, InfoSize, Info);
      VerQueryValue(Info, '\', Pointer(FileInfo), FileInfoSize);
      maj := FileInfo.dwFileVersionMS shr 16;
      min := FileInfo.dwFileVersionMS and $FFFF;
      Release := FileInfo.dwFileVersionLS shr 16;
      build := FileInfo.dwFileVersionLS and $FFFF;
    finally
      FreeMem(Info, FileInfoSize);
    end;
  end;
end;
//------------------------------------------------------------------------------
function GetEnvVar(VarName: string): string;
var
  i: integer;
begin
  Result := '';
  try
    i := Windows.GetEnvironmentVariable(PChar(VarName), nil, 0);
    if i > 0 then
    begin
      SetLength(Result, i);
      Windows.GetEnvironmentVariable(PChar(VarName), PChar(Result), i);
    end;
  except
  end;
end;
//------------------------------------------------------------------------------
function UnzipPath(path: string): string;
var
  pp: string;
begin
  if trim(path) = '' then
    exit;
  Result := path;
  if length(Result) > 3 then
    if (Result[2] = ':') and (Result[3] = '\') then
      if fileexists(Result) or directoryexists(Result) then
        exit;
  pp := ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  if fileexists(pp + '\' + Result) then
  begin
    Result := pp + '\' + Result;
    exit;
  end;

  // path vars //
  Result := ReplaceEx(Result, '%pp%', pp);
  Result := ReplaceEx(Result, '%windir%', GetWinDir);
  Result := ReplaceEx(Result, '%systemroot%', getwindir);
  Result := ReplaceEx(Result, '%sysdir%', getsystemdir);
  Result := ReplaceEx(Result, '%doc%', getsystempath('personal'));
  Result := ReplaceEx(Result, '%desktop%', getsystempath('desktop'));
  Result := ReplaceEx(Result, '%startmenu%', getsystempath('start menu'));
  Result := ReplaceEx(Result, '%commonstartmenu%', getsystempath('common start menu'));
  Result := ReplaceEx(Result, '%pf%', getwindir[1] + ':\Program Files');
  Result := ReplaceEx(Result, '%programfiles%', getwindir[1] + ':\Program Files');

  // non-path vars //

  Result := ReplaceEx(Result, '%date%', formatdatetime('dddddd', now));
  Result := ReplaceEx(Result, '%time%', formatdatetime('tt', now));
  Result := ReplaceEx(Result, '%win_version%', GetWinVersion);
  Result := ReplaceEx(Result, '%uptime%', formatdatetime('hh hour nn min ss sec', gettickcount / MSecsPerDay));
  Result := ReplaceEx(Result, '%crlf%', #10#13);
end;
//------------------------------------------------------------------------------
function ZipPath(path: string): string;
var
  windir: string;
begin
  windir := getwindir;
  path := ReplaceEx(path, IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))), '');
  path := ReplaceEx(path, getsystemdir, '%sysdir%');
  path := ReplaceEx(path, windir, '%windir%');
  path := ReplaceEx(path, getsystempath('personal'), '%doc%');
  path := ReplaceEx(path, getsystempath('desktop'), '%desktop%');
  path := ReplaceEx(path, getsystempath('start menu'), '%startmenu%');
  path := ReplaceEx(path, getsystempath('common start menu'), '%commonstartmenu%');
  path := ReplaceEx(path, windir[1] + ':\program files', '%pf%');
  Result := path;
end;
//----------------------------------------------------------------------
function GetSystemDir: string;
var
  SysDir: array [0..MAX_PATH - 1] of char;
begin
  SetString(Result, SysDir, GetSystemDirectory(SysDir, MAX_PATH));
  Result := ExcludeTrailingPathDelimiter(Result);
end;
//----------------------------------------------------------------------
function GetWinDir: string;
var
  WinDir: array [0..MAX_PATH - 1] of char;
begin
  SetString(Result, WinDir, GetWindowsDirectory(WinDir, MAX_PATH));
  Result := ExcludeTrailingPathDelimiter(Result);
end;
//------------------------------------------------------------------------------
function GetSystemPath(path: string): string;
var
  reg: TRegIniFile;
begin
  reg := TRegIniFile.Create;
  if pos('common', path) > 0 then reg.RootKey := hkey_local_machine else reg.RootKey := hkey_current_user;
  Result := ExcludeTrailingPathDelimiter(reg.ReadString('Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders', path, ''));
  reg.Free;
end;
//--------------------------------------------------------------------------------------------------
function BrowseFolder(hWnd: THandle; title, default: string): string;
var
  lpItemID: PItemIDList;
  BrowseInfo: Windows.TBrowseInfo;
  DisplayName: array[0..MAX_PATH] of char;
  path: array [0..MAX_PATH] of char;
begin
  zeroMemory(@BrowseInfo, sizeof(TBrowseInfo));
  BrowseInfo.hwndOwner := hWnd;
  BrowseInfo.pszDisplayName := @DisplayName;
  BrowseInfo.lpszTitle := PChar(title);
  BrowseInfo.ulFlags := BIF_RETURNONLYFSDIRS or BIF_NEWDIALOGSTYLE;
  lpItemID := SHBrowseForFolder(@BrowseInfo);
  if lpItemId <> nil then
  begin
    SHGetPathFromIDList(lpItemID, path);
    result := strpas(path);
    result := IncludeTrailingPathDelimiter(Result);
    GlobalFreePtr(lpItemID);
  end
  else
    Result := default;
end;
//------------------------------------------------------------------------------
procedure FreeAndNil(var Obj);
var
  p: TObject;
begin
  p := TObject(Obj);
  TObject(Obj) := nil;
  p.Free;
end;
//------------------------------------------------------------------------------
procedure SetClipboard(Text: string);
var
  Data: cardinal;
  dataPtr: pointer;
  pch: PChar;
begin
  if not OpenClipboard(application.mainform.handle) then
  begin
    ShowMessage('Cannot open clipboard');
    exit;
  end;
  EmptyClipboard;
  Data := GlobalAlloc(GMEM_MOVEABLE + GMEM_DDESHARE, length(Text) + 1);
  dataPtr := GlobalLock(Data);
  pch := PChar(Text);
  move(pch^, dataPtr^, length(Text) + 1);
  SetClipboardData(CF_TEXT, Data);
  GlobalUnlock(Data);
  CloseClipboard;
end;
//------------------------------------------------------------------------------
function GetClipboard: string;
var
  Data: cardinal;
  dataptr: pointer;
  pch: PChar;
begin
  Result := '';
  if not OpenClipboard(application.mainform.handle) then
  begin
    ShowMessage('Cannot open clipboard');
    exit;
  end;
  try
    Data := GetClipboardData(CF_TEXT);
    if Data > 32 then
    begin
      dataptr := GlobalLock(Data);
      if dataptr <> nil then
      begin
        GetMem(pch, GlobalSize(Data));
        move(dataPtr^, pch^, GlobalSize(Data));
        Result := strpas(pch);
        FreeMem(pch, GlobalSize(Data));
      end;
      GlobalUnlock(Data);
    end
    else
      Result := '';
  except
  end;
  CloseClipboard;
end;
//------------------------------------------------------------------------------
function ColorToString(Color: uint): string;
begin
  FmtStr(Result, '%s%.8x', [HexDisplayPrefix, Color]);
end;
//------------------------------------------------------------------------------
function StringToColor(const str: string): uint;
begin
  Result := StrToInt(str);
end;
//------------------------------------------------------------------------------
function confirm(handle: cardinal; Text: string = ''): boolean;
begin
  if Text = '' then Text := 'Confirm action';
  Result := messagebox(handle, PChar(Text), 'Confirm', mb_yesno or mb_iconexclamation or mb_defbutton2) = idYes;
end;
//------------------------------------------------------------------------------
procedure AddLog(LogString: string);
var
  LogFileName: string;
  faccess: dword;
  PStr: PChar;
  LengthLogString: integer;
  fs: TFileStream;
begin
  try
    // prepare log string
    LogString := formatdatetime('yyMMdd-hhnnss', now) + '  ' + LogString + #13#10;
    LengthLogString := Length(LogString);
    PStr := StrAlloc(LengthLogString + 1);
    StrPCopy(PStr, LogString);

    // open log
    LogFileName := UnzipPath('%pp%\log.log');
    if FileExists(LogFileName) then faccess := fmOpenReadWrite else faccess := fmCreate;
    fs := TFileStream.Create(LogFileName, faccess);
    fs.Position := fs.Size;

    // write string
    fs.Write(PStr^, LengthLogString);
    StrDispose(PStr);

    // truncate file if needed
    TruncLog(fs);

    fs.Free;
  except
  end;
end;
//------------------------------------------------------------------------------
procedure TruncLog(fs: TFileStream);
const
  LOG_SIZE_MAX = 1024 * 20;
var
  buf: char;
  TruncBy: integer;
  ms: TMemoryStream;
begin
  try
    // how many bytes to delete from the beginning of the stream
    TruncBy := fs.Size - LOG_SIZE_MAX;

    if TruncBy > 0 then
    begin
      // skip TruncBy bytes
      fs.Position := TruncBy;

      // skip bytes until end-of-line found
      fs.Read(buf, 1);
      inc(TruncBy);
      fs.Position := TruncBy;
      while (TruncBy < fs.Size) and (buf <> #10) and (buf <> #13) do
      begin
        fs.Read(buf, 1);
        inc(TruncBy);
        fs.Position := TruncBy;
      end;
      inc(TruncBy);
      fs.Position := TruncBy;
      TruncBy := fs.Size - TruncBy;

      // copy data to buffer stream
      ms := TMemoryStream.Create;
      ms.Size := TruncBy;
      ms.Position := 0;
      ms.CopyFrom(fs, TruncBy);
      ms.Position := 0;

      // copy buffer back to file
      fs.Size := TruncBy;
      fs.Position := 0;
      fs.CopyFrom(ms, TruncBy);

      ms.free;
    end;
  except
  end;
end;
//------------------------------------------------------------------------------
end.

