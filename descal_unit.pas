unit descal_unit;

{$mode Delphi}{$H+}

interface

uses
  jwaWindows, Windows, Messages, Classes, SysUtils, LCLType,
  FileUtil, DateUtils, Math, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  declu, toolu, loggeru, GDIPAPI, gfx, dwm_unit, setsu, frmsetsu, notifieru;

type
  TMonth = record
    Visible: boolean;
    TheDate: TDateTime;
    X: integer;
    Y: integer;
    Width: integer;
    Height: integer;
  end;

  { Tfrmdescal }

  Tfrmdescal = class(TForm)
    trayicon: TTrayIcon;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure trayiconMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  private
    FPrevWndProc: WNDPROC;
    LastMouseHookPoint: TPoint;
    MouseOver: boolean;
    FW: integer;
    FH: integer;
    AllowClose: boolean;
    hMenu: THandle;
    months: array [-11..12] of TMonth;
    FRowCount: integer;
    FColCount: integer;
    FRowHeight: integer;
    procedure GetMonthSize(dte: TDate; out w, h: integer);
    procedure DrawMonth(dte: TDate; hgdip: pointer; x, y: integer);
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
    function GetHMenu: THandle;
  public
    procedure Init;
    procedure Draw;
    procedure err(where: string; e: Exception);
    procedure notify(message: string; silent: boolean = False);
  end;

var
  frmdescal: Tfrmdescal;

implementation
{$R *.lfm}
//------------------------------------------------------------------------------
function MainWindowProc(wnd: HWND; message: uint; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  inst: Tfrmdescal;
  msg: TMessage;
begin
  inst := Tfrmdescal(GetWindowLongPtr(wnd, GWL_USERDATA));
  if assigned(inst) then
  begin
    msg.msg := message;
    msg.wParam := wParam;
    msg.lParam := lParam;
    inst.NativeWndProc(msg);
    result := msg.Result;
  end
  else
    result := DefWindowProc(wnd, message, wParam, lParam);
end;
//------------------------------------------------------------------------------
procedure Tfrmdescal.Init;
begin
  AllowClose := false;
  trayicon.Icon := application.Icon;
  Application.OnException := AppException;
  Application.OnDeactivate := AppDeactivate;

  // workaround for Windows message handling in LCL //
  SetWindowLongPtr(Handle, GWL_USERDATA, PtrUInt(self));
  FPrevWndProc := Pointer(GetWindowLongPtr(Handle, GWL_WNDPROC));
  SetWindowLongPtr(Handle, GWL_WNDPROC, PtrInt(@MainWindowProc));
  dwm.ExcludeFromPeek(Handle);

  RegisterRawInput;
  if sets.X >= 0 then Left := sets.X;
  if sets.Y >= 0 then Top := sets.Y;
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
  function GetRow(i: integer): integer;
  begin
    result := floor((sets.container.PrevMonths + i) / sets.container.Columns);
  end;
  function GetCol(i: integer): integer;
  begin
    result := (sets.container.PrevMonths + i) mod sets.container.Columns;
  end;
var
  i: integer;
  hgdip: Pointer = nil;
  hbrush: Pointer = nil;
  hpen: Pointer;
  bmp: _SimpleBitmap;
  x: integer;
  y: integer;
  number: integer;
  row: integer;
begin
  // select visible months and calc dimensions
  for i := -11 to 12 do
  begin
    months[i].Visible := (-sets.container.PrevMonths <= i) and (i <= sets.container.NextMonths);
    if months[i].Visible then
    begin
      months[i].TheDate := IncMonth(Date, i);
      GetMonthSize(months[i].TheDate, months[i].Width, months[i].Height);
    end;
  end;
  FRowCount := ceil((sets.container.PrevMonths + 1 + sets.container.NextMonths) / sets.container.Columns);
  FColCount := min(sets.container.PrevMonths + 1 + sets.container.NextMonths, sets.container.Columns);

  // calc max month height
  FRowHeight := 0;
  for i := -11 to 12 do
    if months[i].Visible then
      if FRowHeight < months[i].Height then FRowHeight := months[i].Height;

  // arrange months
  x := sets.container.Border;
  y := sets.container.Border div 2;
  number := 1;
  for i := -11 to 12 do
    if months[i].Visible then
    begin
      months[i].X := x;
      months[i].Y := y + (FRowHeight - months[i].Height) div 2;
      if number mod sets.container.Columns = 0 then
      begin
        inc(y, FRowHeight + sets.container.Space);
        x := sets.container.Border;
      end
      else
        inc(x, months[i].Width + sets.container.Space * 3 div 2);
      inc(number);
    end;

  // calc overall size
  FW := FColCount * (months[0].Width + sets.container.Space * 3 div 2) - sets.container.Space * 3 div 2 + sets.container.Border * 2;
  FH := FRowCount * (FRowHeight      + sets.container.Space)           - sets.container.Space           + sets.container.Border;
  Width := FW;
  Height := FH;

  // prepare a bitmap //
  try
    bmp.topleft.x := Left;
    bmp.topleft.y := Top;
    bmp.Width := FW;
    bmp.Height := FH;
    if not gfx.CreateBitmap(bmp, Handle) then
    begin
      err('Draw.CreateBitmap failed', nil);
      exit;
    end;
    hgdip := CreateGraphics(bmp.dc, 0);
    if not assigned(hgdip) then
    begin
      err('Draw.CreateGraphics failed', nil);
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

  // draw background //
  try
    GdipCreateSolidFill($101010 + sets.container.BaseAlpha shl 24, hbrush);
    GdipFillRectangleI(hgdip, hbrush, 0, 0, FW, FH);
    GdipDeleteBrush(hbrush);
  except
    on e: Exception do err('Draw.Backgroud failed', e);
  end;

  // draw months //
  for i := -11 to 12 do
    if months[i].Visible then DrawMonth(months[i].TheDate, hgdip, months[i].X, months[i].Y);

  // draw horizontal lines //
  GdipCreatePen1($30ffffff, 1, UnitPixel, hpen);
  row := 1;
  while row < FRowCount do
  begin
    y := sets.container.Border div 2 + (FRowHeight + sets.container.Space) * row - sets.container.Space div 2;
    GdipDrawLineI(hgdip, hpen, sets.container.Border, y, FW - sets.container.Border, y);
    inc(row);
  end;
  GdipDeletePen(hpen);

  // update window //
  try
    gfx.UpdateLWindow(Handle, bmp, 255);
    if sets.container.Blur and dwm.IsCompositionEnabled then DWM.EnableBlurBehindWindow(Handle, 0)
    else DWM.DisableBlurBehindWindow(Handle);
  except
    on e: Exception do err('Draw.Show failed', e);
  end;

  // cleanup //
  try
    GdipDeleteGraphics(hgdip);
    gfx.DeleteBitmap(bmp);
  except
    on e: Exception do err('Draw.Cleanup failed', e);
  end;

  case sets.container.Position of
    1: SetWindowPos(Handle, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOMOVE + SWP_NOACTIVATE);
    2: SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOMOVE + SWP_NOACTIVATE);
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
procedure Tfrmdescal.DrawMonth(dte: TDate; hgdip: pointer; x, y: integer);
var
  hfont, hfont_family, hformat, hbrush, hpen: Pointer;
  cell: TRectF;
  i, ACol, ARow, h, w: integer;
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
  w := FCols * sets.container.CellSize + sets.container.CellSize;

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
  rid.usUsagePage := 1;
  rid.usUsage := 2;
  rid.dwFlags := RIDEV_INPUTSINK;
  rid.hwndTarget := Handle;
  if not RegisterRawInputDevices(@rid, 1, sizeof(rid)) then notify('RegisterRawInput failed!');
end;
//------------------------------------------------------------------------------
procedure Tfrmdescal.NativeWndProc(var message: TMessage);
var
  dwSize: DWORD;
  ri: RAWINPUT;
begin
  message.result := 0;

  if message.msg = WM_INPUT then
  begin
     dwSize := 0;
     GetRawInputData(message.lParam, RID_INPUT, nil, dwSize, sizeof(RAWINPUTHEADER));
     if GetRawInputData(message.lParam, RID_INPUT, @ri, dwSize, sizeof(RAWINPUTHEADER)) = dwSize then
     begin
       if ri.header.dwType = RIM_TYPEMOUSE then WHMouseMove(0);
     end
     else raise Exception.Create('in NativeWndProc. Invalid size of RawInputData');
     exit;
  end;

  case message.msg of
    WM_WINDOWPOSCHANGING:
      begin
        if sets.container.Position = 0 then PWINDOWPOS(message.lParam)^.hwndInsertAfter := HWND_BOTTOM;
        message.result := CallWindowProc(FPrevWndProc, Handle, message.Msg, message.wParam, message.lParam);
      end;
    WM_TIMER : WMTimer(message);
    WM_COMMAND : WMCommand(message);
    WM_QUERYENDSESSION : message.Result := CloseQuery;
    WM_DISPLAYCHANGE : WMDisplayChange(message);
    WM_SETTINGCHANGE : WMSettingChange(message);
    WM_DWMCOMPOSITIONCHANGED : WMCompositionChanged(message);
    else
      message.result := CallWindowProc(FPrevWndProc, Handle, message.Msg, message.wParam, message.lParam);
  end;
end;
//------------------------------------------------------------------------------
procedure Tfrmdescal.WMTimer(var msg: TMessage);
begin
  try
    if msg.WParam = ID_SLOWTIMER then Draw;
  except
    on e: Exception do err('WMTimer', e);
  end;
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
    on e: Exception do messagebox(handle, pchar(e.message), 'Close.Free', mb_iconexclamation);
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
  msg.WParam := WPARAM(TrackPopupMenuEx(hMenu, TPM_RETURNCMD, pt.x, pt.y, Handle, nil));
  WMCommand(msg);
  Result := true;
end;
//------------------------------------------------------------------------------
function Tfrmdescal.GetHMenu: THandle;
var
  i: integer;
  menuPrev, menuNext, menuCols: HMENU;
begin
  if IsMenu(hMenu) then DestroyMenu(hMenu);

  menuPrev := CreatePopupMenu;
  for i := 0 to 11 do
    AppendMenuW(menuPrev, MF_STRING + MF_CHECKED * integer(i = sets.container.PrevMonths), $f100 + i, pwchar(WideString(inttostr(i))));

  menuNext := CreatePopupMenu;
  for i := 0 to 12 do
    AppendMenuW(menuNext, MF_STRING + MF_CHECKED * integer(i = sets.container.NextMonths), $f200 + i, pwchar(WideString(inttostr(i))));

  menuCols := CreatePopupMenu;
  for i := 1 to 12 do
    AppendMenuW(menuCols, MF_STRING + MF_CHECKED * integer(i = sets.container.Columns), $f300 + i, pwchar(WideString(inttostr(i))));

  hMenu := CreatePopupMenu;
  AppendMenuW(hMenu, MF_STRING + MF_POPUP, menuPrev, pwchar(UTF8Decode(XShowPreviousMonths)));
  AppendMenuW(hMenu, MF_STRING + MF_POPUP, menuNext, pwchar(UTF8Decode(XShowNextMonths)));
  AppendMenuW(hMenu, MF_STRING + MF_POPUP, menuCols, pwchar(UTF8Decode(XColumns)));
  AppendMenuW(hMenu, MF_SEPARATOR, 0, '-');
  AppendMenuW(hMenu, MF_STRING, $f002, pwchar(UTF8Decode(XProgramSettings)));
  AppendMenuW(hMenu, MF_STRING, $f001, pwchar(UTF8Decode(XExit)));
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
        $f100..$f10c:
          begin
            sets.container.PrevMonths := msg.wparam - $f100;
            Draw;
          end;
        $f200..$f20c:
          begin
            sets.container.NextMonths := msg.wparam - $f200;
            Draw;
          end;
        $f301..$f30c:
          begin
            sets.container.Columns := msg.wparam - $f300;
            Draw;
          end;
      end;
    end;
  except
    on e: Exception do err('WMCommand', e);
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
var
  windowCenter: windows.TPoint;
begin
  windowCenter.x := Left + FW div 2;
  windowCenter.y := Top + FH div 2;
  if assigned(Notifier) then Notifier.Message(message, screen.MonitorFromPoint(windowCenter).WorkareaRect, False, silent)
  else if not silent then messagebox(handle, pchar(message), nil, mb_iconerror);
end;
//------------------------------------------------------------------------------
end.

