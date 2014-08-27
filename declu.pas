unit declu;

interface
uses Windows, DefaultTranslator;

type
  TBaseSite = (bsLeft, bsTop, bsRight, bsBottom);
  TBaseOrientation = (boHorizontal, boVertical);

  RAWMOUSE = packed record
    usFlags: USHORT;
    usButtonFlags: USHORT;
    usButtonData: USHORT;
    ulRawButtons: ULONG;
    lLastX: LONG;
    lLastY: LONG;
    ulExtraInformation: ULONG;
  end;

  RAWINPUTHEADER = packed record
    dwType: DWORD;
    dwSize: DWORD;
    hDevice: DWORD;
    wParam: WPARAM;
  end;

  RAWINPUT = packed record
    header: RAWINPUTHEADER;
    mouse: RAWMOUSE;
  end;
  PRAWINPUT = ^RAWINPUT;

  MONITORINFO = record
    cbSize: dword;
    rcMonitor: TRect;
    rcWork: TRect;
    dwFlags: dword;
  end;

  function MonitorFromWindow(HWND: hwnd; dwFlags: DWORD): THandle; stdcall; external 'user32.dll';
  function GetMonitorInfoA(hMonitor: THandle; lpmi: pointer): bool; stdcall; external 'user32.dll';


const
  WINITEM_CLASS = 'Descal::WinItem';
  GUID = '{F4BA4D0C-B36F-4A4B-91F8-CAF7000AED49}';
  RollStep = 4;
  NoAll = swp_nosize + swp_nomove + swp_nozorder + swp_noreposition;
  NOT_AN_ITEM = $ffff; // result const in case when item (items[]) not found

  // system timer event ID's //
  ID_TIMER                  = 1;
  ID_SLOWTIMER              = 2;

resourcestring

  XErrorContactDeveloper = 'Contact developer if error is permanent.';
  XErrorIn = 'Error in';
  XStartButtonText = 'Start';
  XMsgFirstRun = 'Hello. This is the first time to run Descal.';
  XMsgAddAutostart = 'Would you like to run it every time Windows starts?';

  XProgramSettings = 'Program settings';
  XExit = 'Exit';

  XPageGeneral = 'General';
  XPageStyle = 'Style';
  XPageAbout = 'About';

  XZOrderBottom = 'Stay at the bottom (desktop)';
  XZOrderNormal = 'As normal window';
  XZOrderStayOnTop = 'Stay at the top of other windows';

implementation
end.
