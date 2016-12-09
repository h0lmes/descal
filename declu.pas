unit declu;

interface
uses Windows, DefaultTranslator;

type
  RAWMOUSE = packed record
    usFlags: USHORT;
    usButtonFlags: USHORT;
    usButtonData: USHORT;
    ulRawButtons: ULONG;
    lLastX: LONG;
    lLastY: LONG;
    ulExtraInformation: ULONG;
  end;

  RAWKEYBOARD = packed record
    MakeCode: USHORT;
    Flags: USHORT;
    Reserved: USHORT;
    VKey: USHORT;
    Message: UINT;
    ExtraInformation: ULONG;
  end;

  RAWHID = packed record
    dwSizeHid: DWORD;
    dwCount: DWORD;
    bRawData: array [0..0] of BYTE;
  end;

  RAWINPUTHEADER = packed record
    dwType: DWORD;
    dwSize: DWORD;
    hDevice: HANDLE;
    wParam: WPARAM;
  end;

  RAWINPUT = packed record
    header: RAWINPUTHEADER;
    case Integer of
      0: (mouse: RAWMOUSE);
      1: (keyboard: RAWKEYBOARD);
      2: (hid: RAWHID);
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
  PROGRAM_NAME = 'Descal';
  GUID = '{F4BA4D0C-B36F-4A4B-91F8-CAF7000AED49}';
  NoAll = swp_nosize + swp_nomove + swp_nozorder + swp_noreposition;
  ID_TIMER                  = 1;
  ID_SLOWTIMER              = 2;

resourcestring

  XErrorContactDeveloper = 'Contact developer if error is permanent.';
  XErrorIn = 'Error in';
  XStartButtonText = 'Start';
  XMsgFirstRun = 'Hello. This is the first time to run Descal.';
  XMsgAddAutostart = 'Would you like to run it every time Windows starts?';

  XShowPreviousMonths = 'Show previous months';
  XShowNextMonths = 'Show next months';
  XColumns = 'Columns';
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
