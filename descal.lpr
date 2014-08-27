program descal;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Windows, Forms, SysUtils,
  descal_unit, declu, dwm_unit, frmColorU, gdip_gfx, GDIPAPI,
  notifieru, setsu, toolu, frmsetsu;

{$R *.res}

//------------------------------------------------------------------------------
function AWindowItemProc(wnd: HWND; message: uint; wParam: integer; lParam: integer): integer; stdcall;
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
    wndClass.lpfnWndProc    := @AWindowItemProc;
    wndClass.cbClsExtra     := 0;
    wndClass.cbWndExtra     := 0;
    wndClass.hInstance      := hInstance;
    wndClass.hIcon          := 0;
    wndClass.hCursor        := LoadCursor(0, idc_Arrow);
    wndClass.hbrBackground  := 0;
    wndClass.lpszMenuName   := nil;
    wndClass.lpszClassName  := WINITEM_CLASS;
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
  Application.Title:='Descal';
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

  AddLog('--------------------------------------');
  AddLog('AppInitialize');
  Application.Initialize;

  AddLog('Sets');
  sets := _Sets.Create;
  sets.Load;

  AddLog('AppWindowStyle');
  WinHandle := FindWindow('Window', 'descal');
  if IsWindow(WinHandle) then SetWindowLong(WinHandle, GWL_EXSTYLE, GetWindowLong(WinHandle, GWL_EXSTYLE) or WS_EX_LAYERED or WS_EX_TOOLWINDOW);

  AddLog('MainWindowStyle');
  Application.ShowMainForm := false;
  Application.CreateForm(Tfrmdescal, frmdescal);
  SetWindowLong(frmdescal.handle, GWL_EXSTYLE, GetWindowLong(frmdescal.handle, GWL_EXSTYLE) or WS_EX_LAYERED or WS_EX_TOOLWINDOW);
  frmdescal.Caption := 'DescalApp';

  AddLog('RegisterWindowItemClass');
  RegisterWindowItemClass;
  AddLog('Notifier');
  Notifier := _Notifier.Create;
  AddLog('Init');
  frmdescal.Init;
  Application.ShowMainForm := true;
  AddLog('AppRun');
  Application.Run;

  if assigned(Notifier) then Notifier.Free;
  CloseHandle(hMutex);
  AddLog('EndProgram');
end.

