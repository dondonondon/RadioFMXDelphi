unit frLoading;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls, System.Math,
  FMX.Ani, FMX.Controls.Presentation, FMX.Layouts, FMX.Objects, FMX.DialogService,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.Platform, FMX.ListView.Adapters.Base, FMX.VirtualKeyboard,
  System.ImageList, FMX.ImgList, FMX.ScrollBox, FMX.Memo, FMX.TabControl,
  UI.Toast, FMX.LoadingIndicator,
  System.Notification, System.PushNotification, System.Threading,
  FMX.Memo.Types, FMX.ListBox, FMX.MultiView, System.Permissions, FMX.Effects,
  FMX.BASS.Classes, FMX.Player, FMX.BassComponents
  {$IF Defined(ANDROID)}
    ,Androidapi.JNI.AdMob, Androidapi.Helpers, FMX.Platform.Android,
    FMX.Helpers.Android, Androidapi.JNI.PlayServices, Androidapi.JNI.Os,
    Androidapi.JNI.JavaTypes, Androidapi.JNIBridge, FMX.PushNotification.Android, Androidapi.JNI.Embarcadero;
  {$ELSEIF Defined(MSWINDOWS)}
    ;
  {$ENDIF}

type
  TFLoading = class(TFrame)
    background: TRectangle;
    tiMove: TTimer;
    loMain: TLayout;
    faOpa: TFloatAnimation;
    Label1: TLabel;
    imgLogo: TImage;
    seLogo: TShadowEffect;
    Image1: TImage;
    ShadowEffect1: TShadowEffect;
    procedure FirstShow;
    procedure faOpaFinish(Sender: TObject);
    procedure tiMoveTimer(Sender: TObject);
  private
    { Private declarations }
    procedure setFrame;
    procedure fnLoadSetting;
  public
    { Public declarations }
    procedure ReleaseFrame;
  end;

var
  FLoading : TFLoading;

implementation

{$R *.fmx}

uses BFA.Func, BFA.GoFrame, BFA.Helper.Control, BFA.Helper.Main, BFA.Main,
  BFA.OpenUrl, BFA.Rest, BFA.Admob, uDM;

{ TFTemp }

procedure TFLoading.faOpaFinish(Sender: TObject);
begin
  TFloatAnimation(Sender).Enabled := False;
end;

procedure TFLoading.FirstShow;
begin
  setFrame;
  loMain.Visible := False;
  TTask.Run(procedure begin
    Sleep(Round(CIdle * 1.5));
    TThread.Synchronize(TThread.CurrentThread, procedure begin
      Self.setAnchorContent;
      loMain.Opacity := 0;
      loMain.Visible := True;
      faOpa.Enabled := True;
    end);

    fnLoadSetting;
  end).Start;
end;

procedure TFLoading.ReleaseFrame;
begin
  DisposeOf;
end;

procedure TFLoading.fnLoadSetting;
var
  req : String;
begin
  try
    req := 'getSetting';
    DM.RReq.Params.Clear;

    if not fnParsingJSON(req, DM.memData) then begin
      Exit;
    end;

    FIsAdmob := False;
    if DM.memData.FieldByName('admob').AsString = 'Y' then
      FIsAdmob := True;

    vIDBanner := DM.memData.FieldByName('id_banner').AsString;
    vIDInterstitial := DM.memData.FieldByName('id_interstitial').AsString;

    maxCoAds := DM.memData.FieldByName('max_ads').AsInteger;
    coAds := maxCoAds - Round(maxCoAds * 0.55);

    fnDownloadFile(DM.memData.FieldByName('banner').AsString, 'banner.png');

  finally
    TThread.Synchronize(nil, procedure begin
      tiMove.Enabled := True;
    end);
  end;
end;

procedure TFLoading.setFrame;
begin

  if FToken = '' then begin
    for var i := 0 to 32 do
      FToken := FToken + Chr(ord('A') + Random(26));

    SaveSettingString('token', 'token_temporary', FToken);
  end;

  Self.setAnchorContent;
end;

procedure TFLoading.tiMoveTimer(Sender: TObject);
begin
  tiMove.Enabled := False;

  {$IF DEFINED(IOS) or DEFINED(ANDROID)}
    TAndroidHelper.Activity.getWindow.setStatusBarColor($FF515766);
  {$ENDIF}

  fnGoFrame(C_LOADING, C_HOME);
end;

end.
