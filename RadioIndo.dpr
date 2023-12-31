program RadioIndo;

{$R *.dres}

uses
  System.StartUpCopy,
  FMX.Forms,
  frMain in 'frMain.pas' {FMain},
  uDM in 'uDM.pas' {DM: TDataModule},
  BFA.GoFrame in 'sources\BFA.GoFrame.pas',
  BFA.OpenUrl in 'sources\BFA.OpenUrl.pas',
  BFA.Rest in 'sources\BFA.Rest.pas',
  BFA.Func in 'sources\BFA.Func.pas',
  BFA.Helper.Control in 'sources\BFA.Helper.Control.pas',
  BFA.Helper.Main in 'sources\BFA.Helper.Main.pas',
  BFA.Main in 'sources\BFA.Main.pas',
  frHome in 'frames\frHome.pas' {FHome: TFrame},
  frLoading in 'frames\frLoading.pas' {FLoading: TFrame},
  frDetail in 'frames\frDetail.pas' {FDetail: TFrame},
  BFA.HelperMemTable in 'sources\BFA.HelperMemTable.pas',
  frSearch in 'frames\frSearch.pas' {FSearch: TFrame},
  frTemp in 'frames\frTemp.pas' {FTemp: TFrame},
  BFA.Admob in 'sources\BFA.Admob.pas',
  BFA.Permission in 'sources\helper\BFA.Permission.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.FormFactor.Orientations := [TFormOrientation.Portrait, TFormOrientation.InvertedPortrait];
  Application.CreateForm(TFMain, FMain);
  Application.CreateForm(TDM, DM);
  Application.Run;
end.
