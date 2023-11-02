unit frTemp;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, System.Threading, FMX.Effects,
  FMX.Objects, FMX.ListBox;

type
  TFTemp = class(TFrame)
    loMain: TLayout;
    background: TRectangle;
    Layout1: TLayout;
    loHeader: TLayout;
    Rectangle1: TRectangle;
    seHeader: TShadowEffect;
    CornerButton1: TCornerButton;
    btnFind: TCornerButton;
    lbMain: TListBox;
    lb: TListBoxItem;
    procedure FirstShow;
  private
    statF : Boolean;
    procedure setFrame;
  public
    { Public declarations }
    procedure ReleaseFrame;
    procedure fnGoBack;
  end;

var
  FTemp : TFTemp;

implementation

{$R *.fmx}

uses BFA.Func, BFA.GoFrame, BFA.Helper.Control, BFA.Helper.Main, BFA.Main,
  BFA.OpenUrl, BFA.Rest;

{ TFTemp }

const
  spc = 10;
  pad = 8;

procedure TFTemp.FirstShow;
begin
  setFrame;
end;

procedure TFTemp.fnGoBack;
begin
  fnGoFrame(GoFrame, FromFrame);
end;

procedure TFTemp.ReleaseFrame;
begin
  DisposeOf;
end;

procedure TFTemp.setFrame;
begin
  Self.setAnchorContent;

  if statF then
    Exit;

  statF := True;

end;

end.
