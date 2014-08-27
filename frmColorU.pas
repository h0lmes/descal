unit frmColorU;

interface

uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, EColor;

type
  _proc = procedure (color: uint) of object;

  {TfrmColor}

  TfrmColor = class(TForm)
    btnok: TButton;
    btncancel: TButton;
    edr: TEdit;
    edg: TEdit;
    edb: TEdit;
    edh: TEdit;
    edl: TEdit;
    eds: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    rbrgb: TRadioButton;
    rbhls: TRadioButton;
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure cbarChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnokClick(Sender: TObject);
    procedure btncancelClick(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure edrgbChange(Sender: TObject);
    procedure edhlsChange(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    cbar: TEColor;
    FColor: uint;
    FFirstColor: uint;
    FCallback: _proc;
    procedure SetColor(AColor: uint);
    procedure updrgb;
    procedure updhls;
  public
    class function StartForm(AColor: uint; callback_proc: _proc): boolean;
  end;

var
  frmColor: TfrmColor;

{$t+}
implementation
uses gdip_gfx, toolu;
{$R *.lfm}
//------------------------------------------------------------------------------
class function TfrmColor.StartForm(AColor: uint; callback_proc: _proc): boolean;
begin
  if not assigned(frmColor) then Application.CreateForm(self, frmColor);
  with frmColor do
  begin
    FCallback := callback_proc;
    FFirstColor := AColor;
    FColor := AColor;
    result := showmodal = mrOk;
  end;
end;
//------------------------------------------------------------------------------
procedure TfrmColor.FormCreate(Sender: TObject);
begin
  try
    cbar := TEColor.Create(self);
    with cbar do
    begin
      Left := 5;
      Top := 5;
      Width := 281;
      Height := 241;
      Hue := 0;
      Lightness := 0;
      Saturation := 0;
      BorderColor := clBlack;
      VSpace := 8;
      HSpace := 8;
      SplitWidth := 0;
      OnChange := cbarChange;
      Parent := self;
    end;
  except
    on e: Exception do messagebox(handle, pchar('frmFont.FormCreate'#10#13 + e.message), pchar(application.title), 0);
  end;
end;
//------------------------------------------------------------------------------
procedure TfrmColor.FormPaint(Sender: TObject);
begin
  cbar.Paint;
end;
//------------------------------------------------------------------------------
procedure TfrmColor.FormShow(Sender: TObject);
begin
  font.name := GetFont;
  font.size := GetFontSize;
  SetColor(FColor);
end;
//------------------------------------------------------------------------------
procedure TfrmColor.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FCallback := nil;
end;
//------------------------------------------------------------------------------
procedure TfrmColor.SetColor(AColor: uint);
begin
  FColor := AColor;
  cbar.OnChange:= nil;
  cbar.Color:= gdip_gfx.SwapColor(FColor);
  cbar.OnChange:= cbarChange;
  updrgb;
  updhls;
end;
//------------------------------------------------------------------------------
procedure TfrmColor.cbarChange(Sender: TObject);
begin
  updrgb;
  updhls;
  FColor:= $ff000000 or gdip_gfx.swapcolor(cbar.Color);
  if assigned(FCallback) then FCallback(FColor);
end;
//------------------------------------------------------------------------------
procedure TfrmColor.btnokClick(Sender: TObject);
begin
  close;
end;
//------------------------------------------------------------------------------
procedure TfrmColor.btncancelClick(Sender: TObject);
begin
  if assigned(FCallback) then FCallback(FFirstColor);
  close;
end;
//------------------------------------------------------------------------------
procedure TfrmColor.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (key = 27) and (shift = []) then close;
end;
//------------------------------------------------------------------------------
procedure TfrmColor.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  releasecapture;
  perform($a1, 2, 0);
end;
//------------------------------------------------------------------------------
procedure TfrmColor.updhls;
begin
  edh.OnChange := nil;
  edl.OnChange := nil;
  eds.OnChange := nil;
  edh.text := inttostr(cbar.Hue);
  edl.text := inttostr(cbar.Lightness);
  eds.text := inttostr(cbar.Saturation);
  edh.OnChange := edhlsChange;
  edl.OnChange := edhlsChange;
  eds.OnChange := edhlsChange;
end;
//------------------------------------------------------------------------------
procedure TfrmColor.updrgb;
begin
  edr.OnChange := nil;
  edg.OnChange := nil;
  edb.OnChange := nil;
  edr.text := inttostr(FColor shr 16 and $ff);
  edg.text := inttostr(FColor shr 8 and $ff);
  edb.text := inttostr(FColor and $ff);
  edr.OnChange := edrgbChange;
  edg.OnChange := edrgbChange;
  edb.OnChange := edrgbChange;
end;
//------------------------------------------------------------------------------
procedure TfrmColor.edrgbChange(Sender: TObject);
begin
  rbrgb.checked := true;
  try
    FColor := $ff000000 + cardinal(strtoint(edr.text)) and $ff shl 16 + cardinal(strtoint(edg.text)) and $ff shl 8 + cardinal(strtoint(edb.text)) and $ff;
    cbar.Color := gdip_gfx.swapcolor(FColor);
  except end;
end;
//------------------------------------------------------------------------------
procedure TfrmColor.edhlsChange(Sender: TObject);
begin
  rbhls.checked := true;
  try
    cbar.Hue := strtoint(edh.text);
    cbar.Lightness := strtoint(edl.text);
    cbar.Saturation := strtoint(eds.text);
  except end;
end;
//------------------------------------------------------------------------------
end.
