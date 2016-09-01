unit descal_unit;

{$mode Delphi}{$H+}

interface

uses
  jwaWindows, Windows, Messages, Classes, SysUtils, LCLType,
  FileUtil, DateUtils, Math, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  declu, toolu, GDIPAPI, gdip_gfx, dwm_unit, setsu, frmsetsu, notifieru;

type

  { Tfrmdescal }

  Tfrmdescal = class(TForm)
    trayicon: TTrayIcon;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure trayiconMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  private
    FWndInstance: TFarProc;
    FPrevWndProc: TFarProc;
    LastMouseHookPoint: TPoint;
    MouseOver: boolean;
    FW: integer;
    FH: integer;
    AllowClose: boolean;
    hMenu: cardinal;
    procedure GetMonthSize(dte: TDate; out w, h: integer);
    procedure DrawMonth(dte: TDate; hgdip: pointer; x, y: integer; DrawSplit: boolean);
    procedure RegisterRawInput;
    procedure NativeWndProc(var message: TMessage);
    function CloseQuery: integer;
    procedure SaveSets;
    procedure AppException(Sender: TObject; e: Exception);
    procedure AppDeactivate(Sender: TObject);
    procedure WMDisplayChange(var Message: TMessage);
    procedure WMSettingChange(var Message: TMessage);
    procedure WMCompositionChanged(var Message: TMessage);
    procedure WHMouseMove(LParam: LParam);
    procedure WMCommand(var msg: TMessage);
    procedure WMTimer(var msg: TMessage);
    procedure MouseEnter;
    procedure MouseLeave;
    function ContextMenu: boolean;
    function GetHMenu: uint;
  public
    procedure err(where: string; e: Exception);
    procedure notify(message: string; silent: boolean = False);
    procedure alert(message: string);
    procedure Init;
    procedure Draw;
  end;

var
  frmdescal: Tfrmdescal;

implementation
{$R *.lfm}
//------------------------------------------------------------------------------
procedure Tfrmdescal.Init;
begin
  AllowClose := false;
  trayicon.Icon := application.Icon;
  Application.OnException := AppException;
  Application.OnDeactivate := AppDeactivate;

  // workaround for Windows message handling in LCL //
  AddLog('Init.NativeWndProc');
  FWndInstance := MakeObjectInstance(NativeWndProc);
  FPrevWndProc := Pointer(GetWindowLong(Handle, GWL_WNDPROC));
  SetWindowLong(Handle, GWL_WNDPROC, LongInt(FWndInstance));

  DWM.ExcludeFromPeek(Handle);

  AddLog('Init.RegisterRawInput');
  RegisterRawInput;

  if sets.X >= 0 then Left := sets.X;
  if sets.Y >= 0 then Top := sets.Y;

  AddLog('Init.Draw');
  Draw;

  // timers //
  AddLog('Init.Timers');
  SetTimer(handle, ID_SLOWTIMER, 60000, nil);

  if sets.FirstRun and not toolu.CheckAutoRun then
    if idYes = MessageBox(Handle, pchar(UTF8ToAnsi(XMsgFirstRun) + #10#13 + UTF8ToAnsi(XMsgAddAutostart)), pchar(application.title), MB_YESNO) then
    begin
      toolu.SetAutoRun(true);
    end;
end;
//------------------------------------------------------------------------------
procedure Tfrmdescal.Draw;
var
  hgdip, hpath, hbrush: Pointer;
  bmp: _SimpleBitmap;
  rgn: HRGN;
  w, h1, h2, h3, y: integer;
begin
  h1 := 0;
  h3 := 0;
  GetMonthSize(Date, w, h2);
  FW := sets.container.Border * 2 + w;
  if sets.container.PrevMonth then GetMonthSize(IncMonth(Date, -1), w, h1);
  if sets.container.NextMonth then GetMonthSize(IncMonth(Date, 1), w, h3);

  FH := sets.container.Border;
  if sets.container.PrevMonth then inc(FH, h1 + sets.container.Space);
  inc(FH, h2);
  if sets.container.NextMonth then inc(FH, sets.container.Space + h3);
  Width := FW;
  Height := FH;

  // prepare drawing //
  try
    bmp.topleft.x := Left;
    bmp.topleft.y := Top;
    bmp.Width := FW;
    bmp.Height := FH;
    if not gdip_gfx.CreateBitmap(bmp) then
    begin
      err('Draw.Prepare CreateBitmap failed', nil);
      exit;
    end;
    hgdip := CreateGraphics(bmp.dc, 0);
    if not assigned(hgdip) then
    begin
      err('Draw.Prepare CreateGraphics failed', nil);
      exit;
    end;
    GdipSetTextRenderingHint(hgdip, TextRenderingHintAntiAlias);
    GdipSetSmoothingMode(hgdip, SmoothingModeAntiAlias);
  except
    on e: Exception do
    begin
      err('Draw.Prepare', e);
      exit;
    end;
  end;

  // background //
  try
    GdipCreatePath(FillModeAlternate, hpath);
    GdipStartPathFigure(hpath);

    GdipAddPathLine(hpath, sets.container.Radius, 0, FW - sets.container.Radius - 1, 0);
    GdipAddPathArc(hpath, FW - sets.container.Radius * 2 - 1, 0, sets.container.Radius * 2, sets.container.Radius * 2, 270, 90);

    GdipAddPathLine(hpath, FW - 1, sets.container.Radius, FW - 1, FH - sets.container.Radius - 1);
    GdipAddPathArc(hpath, FW - sets.container.Radius * 2 - 1, FH - sets.container.Radius * 2 - 1, sets.container.Radius * 2, sets.container.Radius * 2, 0, 90);

    GdipAddPathLine(hpath, FW - sets.container.Radius - 1, FH - 1, sets.container.Radius, FH - 1);
    GdipAddPathArc(hpath, 0, FH - sets.container.Radius * 2 - 1, sets.container.Radius * 2, sets.container.Radius * 2, 90, 90);

    GdipAddPathLine(hpath, 0, FH - sets.container.Radius - 1, 0, sets.container.Radius);
    GdipAddPathArc(hpath, 0, 0, sets.container.Radius * 2, sets.container.Radius * 2, 180, 90);

    GdipClosePathFigure(hpath);

    GdipCreateSolidFill($101010 + sets.container.BaseAlpha shl 24, hbrush);
    GdipFillPath(hgdip, hbrush, hpath);
    GdipDeleteBrush(hbrush);

    GdipDeletePath(hpath);
  except
    on e: Exception do err('Draw.Backgroud', e);
  end;

  // months //
  y := sets.container.Border div 2;
  if sets.container.PrevMonth then
  begin
    DrawMonth(IncMonth(Date, -1), hgdip, sets.container.Border, y, true);
    inc(y, h1 + sets.container.Space);
  end;
  DrawMonth(Date, hgdip, sets.container.Border, y, sets.container.NextMonth);
  inc(y, h2 + sets.container.Space);
  if sets.container.NextMonth then DrawMonth(IncMonth(Date, 1), hgdip, sets.container.Border, y, false);

  // update window //
  try
    gdip_gfx.UpdateLWindow(Handle, bmp, 255);
    if sets.container.Blur and dwm.IsCompositionEnabled then
    begin
      rgn := CreateRoundRectRgn(1, 1, FW, FH, sets.container.Radius * 2, sets.container.Radius * 2);
      DWM.EnableBlurBehindWindow(Handle, rgn);
      DeleteObject(rgn);
    end
    else
      DWM.DisableBlurBehindWindow(Handle);
  except
    on e: Exception do err('Draw.Show', e);
  end;

  // cleanup //
  try
    GdipDeleteGraphics(hgdip);
    gdip_gfx.DeleteBitmap(bmp);
  except
    on e: Exception do err('Draw.Cleanup', e);
  end;

  case sets.container.Position of
    1: SetWindowPos(Handle, HWND_NOTOPMOST, 0, 0, 0, 0, swp_nosize + swp_nomove + swp_noactivate);
    2: SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, swp_nosize + swp_nomove + swp_noactivate);
  end;
end;
//------------------------------------------------------------------------------
procedure Tfrmdescal.GetMonthSize(dte: TDate; out w, h: integer);
var
  cols, rows: integer;
begin
  cols := 7;
  rows := ceil((DayOfTheWeek(StartOfTheMonth(dte)) - 1 + DaysInMonth(dte)) / cols);
  w := cols * sets.container.CellSize + sets.container.CellSize;
  h := rows * sets.container.CellSize;
end;
//------------------------------------------------------------------------------
procedure Tfrmdescal.DrawMonth(dte: TDate; hgdip: pointer; x, y: integer; DrawSplit: boolean);
var
  hfont, hfont_family, hformat, hbrush, hpen: Pointer;
  cell: TRectF;
  i, ACol, ARow, h: integer;
  FSOM: TDateTime;
  FDIM: integer;
  FCurDay: integer;
  FCols, FRows: integer;
  FStartCol: integer;
begin
  FSOM := StartOfTheMonth(dte);
  FDIM := DaysInMonth(dte);
  FCurDay := DayOfTheMonth(dte);
  FStartCol := DayOfTheWeek(FSOM);
  FCols := 7;
  FRows := ceil((FStartCol - 1 + FDIM) / FCols);
  h := FRows * sets.container.CellSize;

  // init.fonts //
  try
    GdipCreateFontFamilyFromName(PWideChar(WideString(strpas(sets.container.Font.Name))), nil, hfont_family);
    GdipCreateFont(hfont_family, sets.container.Font.Size, ifthen(sets.container.Font.Bold, FontStyleBold, 0) + ifthen(sets.container.Font.Italic, FontStyleItalic, 0), 2, hfont);
    GdipCreateStringFormat(0, 0, hformat);
    GdipSetStringFormatAlign(hformat, StringAlignmentCenter);
    GdipSetStringFormatLineAlign(hformat, StringAlignmentCenter);
  except
    on e: Exception do
    begin
      err('DrawMonth.Fonts', e);
      exit;
    end;
  end;

  // "today" mark //
  if MonthOf(Date) = MonthOf(dte) then
  try
    ACol := (FStartCol - 1 + FCurDay) mod 7;
    if ACol = 0 then ACol := 7;
    dec(ACol);
    ARow := ceil((FStartCol - 1 + FCurDay) / FCols) - 1;
    cell.x := X + sets.container.CellSize * ACol;
    cell.y := Y + sets.container.CellSize * ARow;
    cell.Width := sets.container.CellSize;
    cell.Height := sets.container.CellSize;
    if sets.container.FillToday then
    begin
      GdipCreateSolidFill(sets.container.TodayMarkColor, hbrush);
      GdipFillRectangle(hgdip, hbrush, cell.x, cell.y, cell.width - 1, cell.height - 1);
      GdipDeleteBrush(hbrush);
    end;
    GdipCreatePen1($30ffffff, 1, UnitPixel, hpen);
    GdipDrawRectangle(hgdip, hpen, cell.x, cell.y, cell.width - 1, cell.height - 1);
    GdipDeletePen(hpen);
  except
    on e: Exception do
    begin
      err('DrawMonth.CurrentDay', e);
      exit;
    end;
  end;

  // days //
  try
    for i := 1 to FDIM do
    begin
      ACol := (FStartCol - 1 + i) mod 7;
      if ACol = 0 then ACol := 7;
      dec(ACol);
      ARow := ceil((FStartCol - 1 + i) / FCols) - 1;
      cell.x := X + sets.container.CellSize * ACol;
      cell.y := Y + sets.container.CellSize * ARow;
      cell.Width := sets.container.CellSize;
      cell.Height := sets.container.CellSize;
      if (ACol = 5) or (ACol = 6) then GdipCreateSolidFill(sets.container.Font.color2, hbrush) else GdipCreateSolidFill(sets.container.Font.color, hbrush);
      GdipDrawString(hgdip, PWideChar(WideString(inttostr(i))), -1, hfont, @cell, hformat, hbrush);
      GdipDeleteBrush(hbrush);
    end;
  except
    on e: Exception do
    begin
      err('DrawMonth.Text', e);
      exit;
    end;
  end;

  // month //
  try
    GdipTranslateWorldTransform(hgdip, X + sets.container.CellSize * FCols, Y + h, MatrixOrderPrepend);
    GdipRotateWorldTransform(hgdip, 270, MatrixOrderPrepend);
    cell.x := 0;
    cell.y := 0;
    cell.Width := h;
    cell.Height := sets.container.CellSize;
    GdipCreateSolidFill(sets.container.Font.color, hbrush);
    GdipDrawString(hgdip, PWideChar(WideString(formatDateTime('mmmm', dte))), -1, hfont, @cell, hformat, hbrush);
    GdipDeleteBrush(hbrush);
    GdipResetWorldTransform(hgdip);
  except
    on e: Exception do
    begin
      err('DrawMonth.Text', e);
      exit;
    end;
  end;

  // month split line //
  if DrawSplit then
  begin
    GdipCreatePen1($30ffffff, 1, UnitPixel, hpen);
    GdipDrawLineI(hgdip, hpen, sets.container.Border, Y + h + sets.container.Space div 2, FW - sets.container.Border, Y + h + sets.container.Space div 2);
    GdipDeletePen(hpen);
  end;

  // cleanup //
  try
    GdipDeleteStringFormat(hformat);
    GdipDeleteFont(hfont);
    GdipDeleteFontFamily(hfont_family);
  except
    on e: Exception do
    begin
      err('DrawMonth.Cleanup', e);
      exit;
    end;
  end;
end;
//------------------------------------------------------------------------------
procedure Tfrmdescal.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  ReleaseCapture;
  PostMessage(Handle, $a1, 2, 0);
end;
//------------------------------------------------------------------------------
procedure Tfrmdescal.FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if button = mbRight then ContextMenu;
end;
//------------------------------------------------------------------------------
procedure Tfrmdescal.trayiconMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  SetForegroundWindow(Handle);
  if button = mbRight then ContextMenu;
end;
//------------------------------------------------------------------------------
procedure Tfrmdescal.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if CloseQuery = 0 then CloseAction := caNone;
end;
//------------------------------------------------------------------------------
procedure Tfrmdescal.RegisterRawInput;
var
  rid: RAWINPUTDEVICE;
begin
  Rid.usUsagePage := 1;
  Rid.usUsage := 2;
  Rid.dwFlags := RIDEV_INPUTSINK;
  Rid.hwndTarget := Handle;
  if not RegisterRawInputDevices(@Rid, 1, sizeof(Rid)) then notify('RegisterRawInput failed!');
end;
//------------------------------------------------------------------------------
procedure Tfrmdescal.NativeWndProc(var message: TMessage);
var
  dwSize: uint;
  ri: RAWINPUT;
begin
  case message.msg of
    WM_WINDOWPOSCHANGING:
      if sets.container.Position = 0 then PWINDOWPOS(message.lParam)^.hwndInsertAfter := HWND_BOTTOM;
    WM_INPUT:
    begin
      dwSize := 0;
      GetRawInputData(message.lParam, RID_INPUT, nil, dwSize, sizeof(RAWINPUTHEADER));
      if GetRawInputData(message.lParam, RID_INPUT, @ri, dwSize, sizeof(RAWINPUTHEADER)) <> dwSize then
        raise Exception.Create('in Base.NativeWndProc. Invalid size of RawInputData');
      if (ri.header.dwType = RIM_TYPEMOUSE) then
      begin
        //if ri.mouse.usButtonData and RI_MOUSE_LEFT_BUTTON_DOWN <> 0 then WHButtonDown(1);
        //if ri.mouse.usButtonData and RI_MOUSE_RIGHT_BUTTON_DOWN <> 0 then WHButtonDown(2);
        //if ri.mouse.usButtonData and RI_MOUSE_Left_BUTTON_UP <> 0 then WHButtonUp(1);
        WHMouseMove(0);
      end;
    end;
    WM_TIMER : WMTimer(message);
    WM_COMMAND : WMCommand(message);
    WM_QUERYENDSESSION : message.Result := CloseQuery;
    WM_DISPLAYCHANGE : WMDisplayChange(message);
    WM_SETTINGCHANGE : WMSettingChange(message);
    WM_DWMCOMPOSITIONCHANGED : WMCompositionChanged(message);
  end;
  with message do result := CallWindowProc(FPrevWndProc, Handle, Msg, wParam, lParam);
end;
//------------------------------------------------------------------------------
function Tfrmdescal.CloseQuery: integer;
begin
  AddLog('CloseQuery');

  SaveSets;
  result := 0;
  if not AllowClose then exit;

  AddLog('CloseQuery.Free');
  try
    KillTimer(handle, ID_SLOWTIMER);
    if assigned(sets) then sets.Free;
  except
    on e: Exception do messagebox(handle, pchar(e.message), 'Base.Close.Free', mb_iconexclamation);
  end;
  result := 1;
end;
//------------------------------------------------------------------------------
procedure Tfrmdescal.SaveSets;
begin
  sets.X := Left;
  sets.Y := Top;
  sets.Save;
end;
//------------------------------------------------------------------------------
procedure Tfrmdescal.AppException(Sender: TObject; e: Exception);
begin
  notify('[AppException]'#13#10 + Sender.ClassName + #13#10 + e.message);
end;
//------------------------------------------------------------------------------
procedure Tfrmdescal.AppDeactivate(Sender: TObject);
begin
  // TODO
end;
//------------------------------------------------------------------------------
procedure Tfrmdescal.WMDisplayChange(var Message: TMessage);
begin
  Draw;
end;
//------------------------------------------------------------------------------
procedure Tfrmdescal.WMSettingChange(var Message: TMessage);
begin
  Draw;
end;
//------------------------------------------------------------------------------
procedure Tfrmdescal.WMCompositionChanged(var Message: TMessage);
begin
  Draw;
end;
//------------------------------------------------------------------------------
procedure Tfrmdescal.WHMouseMove(LParam: LParam);
var
  pt: Windows.Tpoint;
  frect: Windows.TRect;
  OldMouseOver: boolean;
begin
  Windows.GetCursorPos(pt);
  if (pt.x <> LastMouseHookPoint.x) or (pt.y <> LastMouseHookPoint.y) or (LParam = $fffffff) then
  begin
    LastMouseHookPoint.x := pt.x;
    LastMouseHookPoint.y := pt.y;

    // detect mouse enter/leave //
    OldMouseOver := MouseOver;
    frect.Left := Left;
    frect.Top := Top;
    frect.Right := Left + Width;
    frect.Bottom := Top + Height;
    MouseOver := PtInRect(frect, pt);

    if MouseOver and not OldMouseOver then MouseEnter;
    if not MouseOver and OldMouseOver then MouseLeave;
  end;
end;
//------------------------------------------------------------------------------
procedure Tfrmdescal.MouseEnter;
begin
  // TODO
end;
//------------------------------------------------------------------------------
procedure Tfrmdescal.MouseLeave;
begin
  // TODO
end;
//------------------------------------------------------------------------------
function Tfrmdescal.ContextMenu: boolean;
var
  pt: windows.TPoint;
  msg: TMessage;
begin
  Result := False;
  GetCursorPos(pt);
  GetHMenu;
  SetForegroundWindow(handle);
  msg.WParam := uint(TrackPopupMenuEx(hMenu, TPM_RETURNCMD, pt.x, pt.y, handle, nil));
  WMCommand(msg);
  Result := True;
end;
//------------------------------------------------------------------------------
function Tfrmdescal.GetHMenu: uint;
begin
  if IsMenu(hMenu) then DestroyMenu(hMenu);
  hMenu := CreatePopupMenu;
  AppendMenu(hMenu, MF_STRING, $f002, pchar(UTF8ToAnsi(XProgramSettings)));
  AppendMenu(hMenu, MF_STRING, $f001, pchar(UTF8ToAnsi(XExit)));
  result := hMenu;
end;
//------------------------------------------------------------------------------
procedure Tfrmdescal.WMCommand(var msg: TMessage);
begin
  try
    msg.Result := 0;
    if IsMenu(hMenu) then DestroyMenu(hMenu);
    if (msg.wparam > $f000) and (msg.wparam <= $ffff) then
    begin
      case msg.wparam of
        $f001:
          begin
            AllowClose := true;
            Close;
          end;
        $f002: Tfrmsets.StartForm(0);
      end;
    end;
  except
    on e: Exception do err('Base.WMCommand', e);
  end;
end;
//------------------------------------------------------------------------------
procedure Tfrmdescal.WMTimer(var msg: TMessage);
begin
  try
    if msg.WParam = ID_SLOWTIMER then Draw;
  except
    on e: Exception do err('Base.WMTimer', e);
  end;
end;
//------------------------------------------------------------------------------
procedure Tfrmdescal.err(where: string; e: Exception);
begin
  if assigned(e) then
  begin
    AddLog(where + #10#13 + e.message);
    messagebox(Handle, PChar(where + #10#13 + e.message), pchar(application.title), MB_ICONERROR)
  end else begin
    AddLog(where);
    messagebox(Handle, PChar(where), pchar(application.title), MB_ICONERROR);
  end;
end;
//------------------------------------------------------------------------------
procedure Tfrmdescal.notify(message: string; silent: boolean);
begin
  if assigned(Notifier) then Notifier.Message(message, 0, False, silent)
  else if not silent then messagebox(handle, pchar(message), nil, mb_iconerror);
end;
//------------------------------------------------------------------------------
procedure Tfrmdescal.alert(message: string);
begin
  if assigned(notifier) then notifier.message(message, 0, True, False)
  else messagebox(handle, pchar(message), nil, mb_iconerror);
end;
//------------------------------------------------------------------------------
end.

