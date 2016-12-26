program descal;

{$mode Delphi}{$H+}
uses
  Windows, Forms, SysUtils, Interfaces, interfacebase,
  loggeru, descal_unit, declu, dwm_unit, frmColorU, gfx, GDIPAPI,
  notifieru, setsu, toolu, frmsetsu;

{$R *.res}
//------------------------------------------------------------------------------
var
  WinHandle: THandle;
  hMutex: uint;
begin
  loggeru.SetLogFileName(ChangeFileExt(ParamStr(0), '.log'));

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
  Application.Title := 'Descal';
  sets := _Sets.Create;
  sets.Load;

  WinHandle := WidgetSet.AppHandle;
  SetWindowLongPtr(WinHandle, GWL_EXSTYLE, GetWindowLongPtr(WinHandle, GWL_EXSTYLE) or WS_EX_TOOLWINDOW);
  Application.ShowMainForm := false;
  Application.CreateForm(Tfrmdescal, frmdescal);
  SetWindowLongPtr(frmdescal.handle, GWL_EXSTYLE, GetWindowLongPtr(frmdescal.handle, GWL_EXSTYLE) or WS_EX_LAYERED or WS_EX_TOOLWINDOW);
  frmdescal.Caption := 'DescalApp';

  Notifier := TNotifier.Create;
  frmdescal.Init;
  Application.ShowMainForm := true;
  Application.Run;

  if assigned(Notifier) then Notifier.Free;
  CloseHandle(hMutex);
  AddLog('<<<-------------------');
end.

