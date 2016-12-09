program descal;

{$mode Delphi}{$H+}

uses
  Interfaces,
  Windows, Forms, SysUtils,
  loggeru, descal_unit, declu, dwm_unit, frmColorU, gfx, GDIPAPI,
  notifieru, setsu, toolu, frmsetsu;

{$R *.res}
//------------------------------------------------------------------------------
function WindowProc(wnd: HWND; message: uint; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
begin
  result := DefWindowProc(wnd, message, wParam, lParam);
end;
//------------------------------------------------------------------------------
procedure RegisterWindowItemClass;
var
  wndClass: windows.TWndClass;
begin
  try
    wndClass.style          := CS_DBLCLKS;
    wndClass.lpfnWndProc    := @WindowProc;
    wndClass.cbClsExtra     := 0;
    wndClass.cbWndExtra     := 0;
    wndClass.hInstance      := hInstance;
    wndClass.hIcon          := 0;
    wndClass.hCursor        := LoadCursor(0, idc_Arrow);
    wndClass.hbrBackground  := 0;
    wndClass.lpszMenuName   := nil;
    wndClass.lpszClassName  := 'DescalWClass';
    if windows.RegisterClass(wndClass) = 0 then raise Exception.Create('Can not register window class');
  except
    on e: Exception do messagebox(0, pchar('RegisterWindowItemClass'#10#13 + e.message), nil, 0);
  end;
end;
//------------------------------------------------------------------------------
var
  WinHandle: THandle;
  hMutex: uint;
begin
  loggeru.SetLogFileName(ChangeFileExt(ParamStr(0), '.log'));

  Application.Title := 'Descal';
  RequireDerivedFormResource := True;

  //
  hMutex := CreateMutex(nil, false, 'Global\' + declu.GUID);
  if GetLastError = ERROR_ALREADY_EXISTS then
  begin
    WinHandle := FindWindow('Window', 'DescalApp');
    if IsWindow(WinHandle) then
    begin
      sendmessage(WinHandle, wm_user, wm_activate, 0);
      SetForegroundWindow(WinHandle);
    end;
    halt;
  end;

  AddLog('>>>-------------------');
  Application.Initialize;
  sets := _Sets.Create;
  sets.Load;

  WinHandle := FindWindow('Window', 'descal');
  if IsWindow(WinHandle) then SetWindowLongPtr(WinHandle, GWL_EXSTYLE, GetWindowLongPtr(WinHandle, GWL_EXSTYLE) or WS_EX_TOOLWINDOW);
  Application.ShowMainForm := false;
  Application.CreateForm(Tfrmdescal, frmdescal);
  SetWindowLongPtr(frmdescal.handle, GWL_EXSTYLE, GetWindowLongPtr(frmdescal.handle, GWL_EXSTYLE) or WS_EX_LAYERED or WS_EX_TOOLWINDOW);
  frmdescal.Caption := 'DescalApp';

  RegisterWindowItemClass;
  Notifier := TNotifier.Create;
  frmdescal.Init;
  Application.ShowMainForm := true;
  Application.Run;

  if assigned(Notifier) then Notifier.Free;
  CloseHandle(hMutex);
  AddLog('<<<-------------------');
end.

