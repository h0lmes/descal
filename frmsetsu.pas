unit frmsetsu;

interface

uses
  Windows, SysUtils, Classes, Graphics, Controls, Forms, DefaultTranslator,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, Buttons,
  declu, gdip_gfx, dwm_unit, frmcoloru;

type

  { Tfrmsets }

  Tfrmsets = class(TForm)
    btnWeekendFontColor: TBitBtn;
    btnTodayMarkColor: TBitBtn;
    chbPrevMonth: TCheckBox;
    chbNextMonth: TCheckBox;
    chbFillToday: TCheckBox;
    Label1: TLabel;
    Label2: TLabel;
    lv: TListView;
    images: TImageList;
    pages: TPageControl;
    btn_ok: TBitBtn;
    btn_cancel: TBitBtn;
    tbCellSize: TTrackBar;
    tbBorder: TTrackBar;
    tsGeneral: TTabSheet;
    tsStyle: TTabSheet;
    tsAbout: TTabSheet;
    btnFont: TBitBtn;
    btnFontColor: TBitBtn;
    lblBackgroundTransparency: TLabel;
    lblCredits: TLabel;
    lblCredits1: TLabel;
    lblCredits3: TLabel;
    lblCredits4: TLabel;
    rgPosition: TRadioGroup;
    tbBaseAlpha: TTrackBar;
    lblTitle: TLabel;
    cbautorun: TCheckBox;
    chbBlur: TCheckBox;
    procedure btnFontClick(Sender: TObject);
    procedure btnFontColorClick(Sender: TObject);
    procedure btnTodayMarkColorClick(Sender: TObject);
    procedure btnWeekendFontColorClick(Sender: TObject);
    procedure chbFillTodayChange(Sender: TObject);
    procedure chbNextMonthChange(Sender: TObject);
    procedure chbPrevMonthChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btn_cancelClick(Sender: TObject);
    procedure chbBlurClick(Sender: TObject);
    procedure lvSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure rgPositionSelectionChanged(Sender: TObject);
    procedure tbBaseAlphaChange(Sender: TObject);
    procedure lbl_linkClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure cbautorunClick(Sender: TObject);
    procedure lblMailToClick(Sender: TObject);
    procedure btn_okClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tbBorderChange(Sender: TObject);
    procedure tbCellSizeChange(Sender: TObject);
  private
    procedure FontColorCallback(color: uint);
    procedure WeekendFontColorCallback(color: uint);
    procedure TodayMarkColorCallback(color: uint);
  public
    PageIndex: integer;
    class procedure StartForm(APageIndex: integer = 0);
    procedure Apply;
  end;

var
  frmsets: Tfrmsets;

implementation
uses setsu, descal_unit, toolu;
{$R *.lfm}
//------------------------------------------------------------------------------
class procedure Tfrmsets.StartForm(APageIndex: integer);
begin
  if not assigned(sets) then
  begin
    messagebox(application.mainform.handle, 'Settings container does not exist', 'Descal.frmSets.StartForm', mb_iconexclamation);
    exit;
  end;

  if not assigned(frmsets) then application.CreateForm(self, frmsets);
  sets.StoreSetsContainer;
  frmsets.PageIndex := APageIndex;
  frmsets.show;
end;
//------------------------------------------------------------------------------
procedure Tfrmsets.FormCreate(Sender: TObject);
begin
  font.name := GetFont;
  font.size := GetFontSize;
  lblTitle.Font.Size := 18;
  lblTitle.Font.Color := clGray;
  lblCredits.Font.Color := clGray;
  lblCredits1.Font.Color := clGray;
  lblCredits3.Font.Color := clGray;
  lblCredits4.Font.Color := clGray;

  lv.Items[0].Caption := XPageGeneral;
  lv.Items[1].Caption := XPageStyle;
  lv.Items[2].Caption := XPageAbout;

  rgPosition.Items.Add(XZOrderBottom);
  rgPosition.Items.Add(XZOrderNormal);
  rgPosition.Items.Add(XZOrderStayOnTop);
end;
//------------------------------------------------------------------------------
procedure Tfrmsets.FormShow(Sender: TObject);
var
  maj, min, rel, build: integer;
begin
  lv.ItemIndex := PageIndex;

  toolu.GetFileVersion(paramstr(0), maj, min, rel, build);
  lblTitle.Caption:= 'Descal  ' + inttostr(maj) + '.' + inttostr(min) + '.' + inttostr(rel);

  // general //
  cbAutoRun.checked := toolu.CheckAutoRun;
  rgPosition.ItemIndex := sets.container.Position;
  chbPrevMonth.OnChange := nil;
  chbPrevMonth.Checked := sets.container.PrevMonth;
  chbPrevMonth.OnChange := chbPrevMonthChange;
  chbNextMonth.OnChange := nil;
  chbNextMonth.Checked := sets.container.NextMonth;
  chbNextMonth.OnChange := chbNextMonthChange;

  // style
  chbBlur.Enabled := dwm.CompositingEnabled;
  chbBlur.OnClick := nil;
  chbBlur.checked := sets.container.Blur;
  chbBlur.OnClick := chbBlurClick;
  tbBaseAlpha.OnChange := nil;
  tbBaseAlpha.Position := sets.container.BaseAlpha;
  tbBaseAlpha.OnChange := tbBaseAlphaChange;
  tbCellSize.OnChange := nil;
  tbCellSize.Position := sets.container.CellSize;
  tbCellSize.OnChange := tbCellSizeChange;
  tbBorder.OnChange := nil;
  tbBorder.Position := sets.container.Border;
  tbBorder.OnChange := tbBorderChange;
  chbFillToday.OnChange := nil;
  chbFillToday.Checked := sets.container.FillToday;
  chbFillToday.OnChange := chbFillTodayChange;
end;
//------------------------------------------------------------------------------
procedure Tfrmsets.Apply;
begin
  frmdescal.Draw;
end;
//------------------------------------------------------------------------------
procedure Tfrmsets.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (key = 27) and (shift = []) then close;
end;
//------------------------------------------------------------------------------
procedure Tfrmsets.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  action := cahide;
end;
//------------------------------------------------------------------------------
procedure Tfrmsets.btn_okClick(Sender: TObject);
begin
  Close;
end;
//------------------------------------------------------------------------------
procedure Tfrmsets.btn_cancelClick(Sender: TObject);
begin
  try
    sets.RestoreSetsContainer;
    Apply;
    Close;
  except
    on e: Exception do frmdescal.err('frmSets.Cancel', e);
  end;
end;
//------------------------------------------------------------------------------
procedure Tfrmsets.lvSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  if lv.ItemIndex > -1 then pages.ActivePageIndex := lv.ItemIndex;
end;
//------------------------------------------------------------------------------
//
//
//
//  GENERAL
//
//
//
//------------------------------------------------------------------------------
procedure Tfrmsets.cbautorunClick(Sender: TObject);
begin
  toolu.setautorun(cbautorun.checked);
end;
//------------------------------------------------------------------------------
procedure Tfrmsets.rgPositionSelectionChanged(Sender: TObject);
begin
  sets.container.Position := rgPosition.ItemIndex;
  Apply;
end;
//------------------------------------------------------------------------------
procedure Tfrmsets.chbPrevMonthChange(Sender: TObject);
begin
  sets.container.PrevMonth := chbPrevMonth.Checked;
  Apply;
end;
//------------------------------------------------------------------------------
procedure Tfrmsets.chbNextMonthChange(Sender: TObject);
begin
  sets.container.NextMonth := chbNextMonth.Checked;
  Apply;
end;
//------------------------------------------------------------------------------
//
//
//
//  THEMES
//
//
//
//------------------------------------------------------------------------------
procedure Tfrmsets.chbBlurClick(Sender: TObject);
begin
  sets.container.Blur := chbBlur.checked;
  Apply;
end;
//------------------------------------------------------------------------------
procedure Tfrmsets.tbBaseAlphaChange(Sender: TObject);
begin
  sets.container.BaseAlpha := tbBaseAlpha.Position;
  Apply;
end;
//------------------------------------------------------------------------------
procedure Tfrmsets.tbBorderChange(Sender: TObject);
begin
  sets.container.Border := tbBorder.Position;
  Apply;
end;
//------------------------------------------------------------------------------
procedure Tfrmsets.tbCellSizeChange(Sender: TObject);
begin
  sets.container.CellSize := tbCellSize.Position;
  Apply;
end;
//------------------------------------------------------------------------------
procedure Tfrmsets.btnFontClick(Sender: TObject);
var
  dlg: TFontDialog;
begin
  try
    dlg := TFontDialog.Create(self);
    dlg.Font.Name := strpas(pchar(@sets.container.Font.name));
    dlg.Font.Size := sets.container.Font.size;
    dlg.Font.Bold := sets.container.Font.bold;
    dlg.Font.Italic := sets.container.Font.italic;
    dlg.Options := [fdTrueTypeOnly, fdNoSimulations, fdForceFontExist, fdScalableOnly];
    if dlg.Execute then
    begin
      if Trim(dlg.Font.Name) <> '' then
      begin
        StrCopy(sets.container.Font.name, pchar(dlg.Font.Name));
        sets.container.Font.size:= dlg.Font.Size;
        sets.container.Font.bold:= dlg.Font.Bold;
        sets.container.Font.italic:= dlg.Font.Italic;
        Apply;
      end;
    end;
  finally
    dlg.free;
    dlg := nil;
  end;
end;
//------------------------------------------------------------------------------
procedure Tfrmsets.btnFontColorClick(Sender: TObject);
begin
  TfrmColor.StartForm(sets.container.Font.color, FontColorCallback);
end;
//------------------------------------------------------------------------------
procedure Tfrmsets.btnWeekendFontColorClick(Sender: TObject);
begin
  TfrmColor.StartForm(sets.container.Font.color2, WeekendFontColorCallback);
end;
//------------------------------------------------------------------------------
procedure Tfrmsets.btnTodayMarkColorClick(Sender: TObject);
begin
  TfrmColor.StartForm(sets.container.TodayMarkColor, TodayMarkColorCallback);
end;
//------------------------------------------------------------------------------
procedure Tfrmsets.FontColorCallback(color: uint);
begin
  sets.container.Font.color := color;
  Apply;
end;
//------------------------------------------------------------------------------
procedure Tfrmsets.WeekendFontColorCallback(color: uint);
begin
  sets.container.Font.color2 := color;
  Apply;
end;
//------------------------------------------------------------------------------
procedure Tfrmsets.TodayMarkColorCallback(color: uint);
begin
  sets.container.TodayMarkColor := color;
  Apply;
end;
//------------------------------------------------------------------------------
procedure Tfrmsets.chbFillTodayChange(Sender: TObject);
begin
  sets.container.FillToday := chbFillToday.Checked;
  Apply;
end;
//------------------------------------------------------------------------------
//
//
//
//  ABOUT ///
//
//
//
//------------------------------------------------------------------------------
procedure Tfrmsets.lblMailToClick(Sender: TObject);
begin
  //frmterry.Run('mailto:roman.holmes@gmail.com?subject=descal');
end;
//------------------------------------------------------------------------------
procedure Tfrmsets.lbl_linkClick(Sender: TObject);
begin
  //frmterry.Run(TLabel(sender).caption);
end;
//------------------------------------------------------------------------------
end.
