unit BFA.Admob;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Ani, FMX.Controls.Presentation, FMX.Layouts, FMX.Objects, FMX.DialogService,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.LoadingIndicator,
  FMX.ListView, FMX.ScrollBox, FMX.Memo, FMX.TabControl, System.ImageList, System.Math,
  FMX.ImgList, FMX.MultiView, FMXTee.Engine, FMXTee.Series, FMX.VirtualKeyboard,
  FMXTee.Procs, FMXTee.Chart, REST.Types, REST.Client, Data.Bind.Components,
  Data.Bind.ObjectScope, FMX.Gestures, FMX.Effects, FMX.Platform,
  FMX.ListBox, FMX.Advertising, System.Threading, System.Generics.Collections
  {$IF Defined(ANDROID)}
    ,Androidapi.JNI.AdMob, Androidapi.Helpers, FMX.Platform.Android,
    FMX.Helpers.Android, Androidapi.JNI.PlayServices, Androidapi.JNI.Os,
    Androidapi.JNI.JavaTypes, Androidapi.JNIBridge, Androidapi.JNI.Embarcadero;
  {$ELSEIF Defined(MSWINDOWS)}
    ;
  {$ENDIF}

type
    HelperObject = class
      public
        class procedure fnClickImage(ASender : TObject);
    end;
//  {$IFDEF ANDROID}
//
//    TMyAdViewListener = class(TJavaLocal, JIAdListener)
//    private
//      FAD : JInterstitialAd;
//    public
//      constructor Create(AAD : JInterstitialAd);
//      procedure onAdClosed; cdecl;
//      procedure onAdFailedToLoad(errorCode : Integer); cdecl;
//      procedure onAdLeftApplication; cdecl;
//      procedure onAdOpened; cdecl;
//      procedure onAdLoaded; cdecl;
//    end;
//  {$ENDIF}

//procedure fnLoadInterstitial(id : String);
procedure fnCreateBanner(id : String; AParent : TControl; FEvent : TAdDidFailEvent = nil; FPos : Integer = 0);
procedure fnDisposeBanner; overload;

const
  FPosBannerClient  = 0;
  FPosBannerTop     = 1;
  FPosBannerBottom  = 2;
  FPosBannerCenter  = 3;

var
  coAds, maxCoAds : Integer;

  FLayoutBanner : TLayout;
  ALabel : TLabel;
//{$IFDEF ANDROID}
//  LAdViewListener : TMyAdViewListener;
//  FInterStitial : JInterstitialAd;
//
//  ABanner : TBannerAd;
//  APanel : TPanel;
//{$ENDIF}

implementation

{ TMyAdViewListener }

uses BFA.Func, BFA.Main, BFA.Helper.Control, BFA.Helper.Main, BFA.OpenUrl;

procedure fnCreateBanner(id : String; AParent : TControl; FEvent : TAdDidFailEvent; FPos : Integer);
var
  FImage : TImage;
begin
  TThread.Synchronize(nil, procedure begin
    if id = '' then
      Exit;

    FImage := TImage.Create(nil);
    FImage.Visible := False;
    FImage.WrapMode := TImageWrapMode.Fit;
    FImage.StyleName := 'banner_image';
    FImage.HitTest := True;
    FImage.OnClick := HelperObject.fnClickImage;
    AParent.AddObject(FImage);

    FImage.setAnchorContent;
    FImage.LoadFromLoc('banner.png');

    ALabel := TLabel.Create(nil);
    ALabel.Parent := AParent;
    ALabel.setAnchorContent;
    ALabel.TextSettings.HorzAlign := TTextAlign.Center;
    ALabel.Text := 'load advertising';
    ALabel.Font.Size := 12.5;
    ALabel.FontColor := $FFFFFFFF;

    ALabel.StyledSettings := [];

    FImage.BringToFront;

//    {$IF DEFINED (ANDROID)}
//      APanel := TPanel.Create(AParent);
//      APanel.Parent := AParent;
//      APanel.ControlType := TControlType.Platform;
//      APanel.StyleLookup := 'pMain';
//      APanel.Width := AParent.Width;
//      APanel.Height := 50;
//      APanel.Position.X := 0;
//
//      if FPos = FPosBannerClient then begin
//        APanel.setAnchorContent;
//      end else if FPos = FPosBannerTop then begin
//        APanel.Position.Y := 0;
//      end else if FPos = FPosBannerBottom then begin
//        APanel.Position.Y := AParent.Height - APanel.Height;
//      end else if FPos = FPosBannerCenter then begin
//        APanel.Position.Y := (AParent.Height - APanel.Height) / 2;
//      end;
//
//      ABanner := TBannerAd.Create(APanel);
//      ABanner.Parent := APanel;
//      ABanner.TestMode := False;
//      ABanner.Align := TAlignLayout.Contents;
//      ABanner.AdSize := TBannerAdSize.Small;
//
//
//      ABanner.OnDidFail := FEvent;
//
//      ABanner.AdUnitID := id;
//      ABanner.LoadAd;
//    {$ELSEIF DEFINED (MSWINDOWS)}
//      //ALabel.Text := 'advertising';
//      FImage.Visible := True;
//    {$ENDIF}


      FImage.Visible := True;
  end);

end;

procedure fnDisposeBanner;
begin

  TThread.Synchronize(nil, procedure var i : Integer; begin
    if Assigned(ALabel) then begin
      ALabel.DisposeOf;
      ALabel := nil;
    end;
//    {$IFDEF ANDROID}
//      if Assigned(APanel) then begin
//        for i := 0 to APanel.ControlsCount - 1 do begin
//          TBannerAd(APanel.Controls[i]).DisposeOf;
//        end;
//
//        ABanner := nil;
//
//        APanel.DisposeOf;
//        APanel := nil;
//      end;
//    {$ENDIF}
  end);

end;

//procedure fnLoadInterstitial(id : String);
//{$IFDEF ANDROID}
//  var
//    LADRequestBuilder : JAdRequest_Builder;
//    LadRequest : JAdRequest;
//{$ENDIF}
//begin
//  {$IFDEF ANDROID}
//    if id = '' then
//      Exit;
//
//    fnLoadLoadingAds(True, 'Load Advertising');
//
//    coAds := maxCoAds;
//
//    FInterStitial := TJinterstitialAd.JavaClass.init(MainActivity);
//    FInterStitial.setAdUnitId
//      (StringToJString(id));
//
//    LADRequestBuilder := TJAdRequest_Builder.Create;
//
//    {LADRequestBuilder.addKeyword(StringToJString('Mesothelioma Law Firm'));
//    LADRequestBuilder.addKeyword(StringToJString('Donate Car to Charity California'));
//    LADRequestBuilder.addKeyword(StringToJString('Donate Car for Tax Credit'));
//    LADRequestBuilder.addKeyword(StringToJString('Donate Cars in MA'));
//    LADRequestBuilder.addKeyword(StringToJString('Donate Your Car Sacramento'));
//    LADRequestBuilder.addKeyword(StringToJString('How to Donate A Car in California'));
//    LADRequestBuilder.addKeyword(StringToJString('software untuk mengakses internet'));
//    LADRequestBuilder.addKeyword(StringToJString('plasa hosting'));
//    LADRequestBuilder.addKeyword(StringToJString('jasa pembuatan website iklan baris'));}
//
//    LadRequest := LADRequestBuilder.Build();
//
//
//    LAdViewListener := TMyAdViewListener.Create(FInterStitial);
//    CallInUIThread(
//    procedure
//    begin
//      FInterStitial.setAdListener(TJAdListenerAdapter.JavaClass.init
//      (LAdViewListener));
//      FInterStitial.LoadAd(LadRequest);
//    end
//    );
//  {$ENDIF}
//end;

//{$IFDEF ANDROID}
//constructor TMyAdViewListener.Create(AAD: JInterstitialAd);
//begin
//	inherited Create;
//	FAD := AAD;
//end;
//
//procedure TMyAdViewListener.onAdClosed;
//begin
//  fnLoadLoading(False);
//end;
//
//procedure TMyAdViewListener.onAdFailedToLoad(errorCode: Integer);
//begin
//  coAds := maxCoAds - Round(0.55 * maxCoAds);
//  fnLoadLoading(False);
//end;
//
//procedure TMyAdViewListener.onAdLeftApplication;
//begin
//
//end;
//
//procedure TMyAdViewListener.onAdLoaded;
//begin
//	FAD.Show;
//end;
//
//procedure TMyAdViewListener.onAdOpened;
//begin
//
//end;
//{$ENDIF}

{ HelperObject }

class procedure HelperObject.fnClickImage(ASender: TObject);
begin
  OpenUrl('https://saweria.co/dondonondon');
end;

end.
