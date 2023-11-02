unit BFA.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Objects,
  System.ImageList, FMX.ImgList, System.Rtti, FMX.Grid.Style, FMX.ScrollBox,
  FMX.Grid,FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListBox, FMX.Ani, System.Threading,
  FMX.ListView.Adapters.Base, FMX.ListView, FMX.Memo, FMX.Edit, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, REST.Client, REST.Response.Adapter, FMX.LoadingIndicator,
  {$IFDEF ANDROID}
    Androidapi.Helpers, FMX.Platform.Android, System.Android.Service, System.IOUtils,
    FMX.Helpers.Android, Androidapi.JNI.PlayServices, Androidapi.JNI.Os,
  {$ELSEIF Defined(MSWINDOWS)}
   System.IOUtils,
  {$ENDIF}
  System.Generics.Collections, System.Net.URLClient, System.Net.HttpClient,
  System.Net.HttpClientComponent, Rest.Types;

const
  //FRAME
  C_LOADING = 'LOADING';
  C_HOME = 'HOME';
  C_LOGIN = 'LOGIN';
  C_DETAIL = 'DETAIL';
  C_SEARCH = 'SEARCH';

  CIdle = 400;
  CFontS = 12.5;

procedure fnShowMessage(FMessage : String);
procedure fnTransitionFrame(FFrom, FGo : TControl; FFAFrom, FFAGo : TFloatAnimation; isBack : Boolean);
procedure fnGoFrame(FFrom, FGo : String; isBack : Boolean = False);
procedure fnHideFrame(FFrom : String);
procedure fnBack(FProc : TProc = nil);

procedure fnLoadLoading(lo : TLayout; ani : TFMXLoadingIndicator; stat : Boolean); overload;  //ganti ini
procedure fnLoadLoading(stat : Boolean); overload;
procedure fnLoadLoadingAds(stat : Boolean; FText : String = ''); overload;

function fnParsingJSON(req : String; mem : TFDMemTable; FMethod : TRESTRequestMethod = TRESTRequestMethod.rmPOST): Boolean; overload;
function fnParsingJSON(req : String; FMethod : TRESTRequestMethod = TRESTRequestMethod.rmPOST): Boolean; overload;

procedure fnDownloadFile(FURL, nmFile : String);
procedure fnDownloadLib(FURL, nmFile : String);

procedure fnSetPlay(FID, FNama : String);
procedure fnIsPlay(isPlay : Boolean = True);
procedure fnSetText(FText : String);

procedure fnCheckLibrary;

var
  FListGo : TStringList;
  goFrame, fromFrame, FToken, vIDBanner, vIDInterstitial : String;
  tabCount : Integer;
  FPopUp, FIsAdmob : Boolean;
  FPermissionReadExternalStorage, FAccess_Coarse_Location, FAccess_Fine_Location,
  FPermissionWriteExternalStorage: string;

implementation

uses BFA.Func, BFA.GoFrame, BFA.Rest, frMain, uDM, BFA.Admob, frHome;

procedure fnShowMessage(FMessage : String);
begin
  TThread.Synchronize(nil, procedure
  begin
    FMain.TM.Toast(FMessage);
  end);
end;

procedure fnTransitionFrame(FFrom, FGo : TControl; FFAFrom, FFAGo : TFloatAnimation; isBack : Boolean);
var
  FLayout : TLayout;
begin
  with FMain do begin
    if Assigned(FFrom) then begin
      FFrom.Visible := True;
    end;

    {FLayout := TLayout(FGo.FindComponent('loMain'));
    if Assigned(FLayout) then
      if goFrame <> C_LOADING then
        FLayout.Visible := False;}

    if isBack then begin
      FFAGo.Inverse := True;
      FFAFrom.Inverse := True;

      FGo.SendToBack;

      FFAGo.Parent := FFrom;
      FFAFrom.Parent := FFrom;
    end else begin
      FFAGo.Inverse := False;
      FFAFrom.Inverse := False;

      FGo.BringToFront;

      FFAGo.Parent := FGo;
      FFAFrom.Parent := FGo;
    end;

    FGo.Visible := True;

    FFAGo.PropertyName := 'Position.Y';
    FFAFrom.PropertyName := 'Opacity';

    FFAGo.StartValue := 75;
    FFAGo.StopValue := 0;

    FFAFrom.StartValue := 0.035;
    FFAFrom.StopValue := 1;

    FFAGo.Duration := 0.25;
    FFAFrom.Duration := 0.2;

    FFAFrom.Interpolation := TInterpolationType.Quadratic;
    FFAGo.Interpolation := TInterpolationType.Quadratic;

    fnShowFrame;

    Sleep(100);

    FFAGo.Enabled := True;
    FFAFrom.Enabled := True;
  end;
end;

procedure fnGoFrame(FFrom, FGo : String; isBack : Boolean = False);
begin
  fnGetFrame(C_FROM, FFrom);
  fnGetFrame(C_DESTINATION, FGo);

  if not Assigned(VFRGo) then begin
    fnShowMessage('Mohon maaf, terjadi kesalahan');
    Exit;
  end;

  fnDisposeBanner;
  if Assigned(FLayoutBanner) then begin
    FLayoutBanner.DisposeOf;
    FLayoutBanner := nil;
  end;

  coAds := coAds - 1;

  if coAds <= 0 then
//    if FIsAdmob then
//      fnLoadInterstitial(vIDInterstitial);

  fromFrame := FFrom;
  goFrame := FGo;

  {FMain.loFooter.Visible := True;
  if (goFrame = C_LOADING) or (goFrame = C_LOGIN) or (goFrame = C_CHAT) or (goFrame = C_PREDIKSI) or (goFrame = C_SEARCH) or (goFrame = C_NEWS_DETAIL) then
    FMain.loFooter.Visible := False;}

  tabCount := 0;

  if isBack then
    FListGo.Delete(FListGo.Count - 1)
  else
    FListGo.Add(goFrame);

  fnTransitionFrame(VFRFrom, VFRGo, FMain.faFromX, FMain.faGoX, isBack);
end;

procedure fnHideFrame(FFrom : String);
begin
  if fromFrame <> '' then
    VFRFrom.Visible := False;

  VFRFrom := nil;
  VFRGo := nil;
end;

procedure fnBack(FProc : TProc = nil);
begin
  try
    if goFrame = C_LOADING then
      Exit;

    if FListGo.Count <= 2 then begin
      if (goFrame = C_HOME) or (goFrame = C_HOME) then begin
        if tabCount < 1 then
          fnShowMessage('Tap Dua Kali Untuk Keluar')
        else
          fnShowMessage('Sampai Jumpa Kembali');

        Inc(TabCount);
      end;
    end;

    if FPopUp then begin
      if Assigned(FProc) then
        FProc;
    end else begin
      if Assigned(FProc) then
        FProc;

      if FListGo.Count > 2 then begin
        fnGoFrame(FListGo[FListGo.Count - 1], FListGo[FListGo.Count - 2], True)
      end;
    end;

    if ((goFrame = C_HOME) or (goFrame = C_HOME)) AND (TabCount >= 2) then
    begin
      Application.Terminate;
    end;
  except

  end;
end;

procedure fnLoadLoading(lo : TLayout; ani : TFMXLoadingIndicator; stat : Boolean);
begin
  TThread.Synchronize(nil, procedure
  begin
    if stat = True then
      lo.BringToFront;
    lo.Visible := stat;
    //ani.Kind := TLoadingIndicatorKind.Wave;
    ani.Enabled := stat;
  end);
end;

procedure fnLoadLoading(stat : Boolean);
begin
  with FMain do begin
    lblLoad.Text := '';
    fnLoadLoading(loLoad, aniLoad, stat);
  end;
end;

procedure fnLoadLoadingAds(stat : Boolean; FText : String);
begin
  with FMain do begin
    fnLoadLoading(loLoad, aniLoad, stat);

    lblLoad.Text := FText;

    if FText <> '' then begin
      reLoad.Visible := True;
      reLoad.SendToBack;
    end else begin
      reLoad.Visible := False;
    end;
  end;
end;

function fnParsingJSON(req : String; mem : TFDMemTable; FMethod : TRESTRequestMethod = TRESTRequestMethod.rmPOST) : Boolean;
begin
  Result := fnParseJSON(DM.RClient, DM.RReq, DM.RResp, DM.rRespAdapter, req, mem, FMethod);
end;

function fnParsingJSON(req : String; FMethod : TRESTRequestMethod = TRESTRequestMethod.rmPOST): Boolean;
begin
  Result := fnParseJSON(DM.RClient, DM.RReq, DM.RResp, DM.rRespAdapter, req, DM.memData, FMethod);
end;

procedure fnDownloadFile(FURL, nmFile : String);
var
  HTTP : TNetHTTPClient;
  Stream : TMemoryStream;
begin
  HTTP := TNetHTTPClient.Create(nil);
  try
    Stream := TMemoryStream.Create;
    try
      try
        HTTP.Get(FURL, Stream);
        TThread.Synchronize(nil, procedure begin
          Stream.SaveToFile(fnLoadFile(nmFile));
        end);
      except

      end;
    finally
      Stream.DisposeOf;
    end;
  finally
    HTTP.DisposeOf;
  end;
end;

procedure fnDownloadLib(FURL, nmFile : String);
var
  HTTP : TNetHTTPClient;
  Stream : TMemoryStream;
begin
  HTTP := TNetHTTPClient.Create(nil);
  try
    Stream := TMemoryStream.Create;
    try
      try
        HTTP.Get(FURL, Stream);
        TThread.Synchronize(nil, procedure begin
          Stream.SaveToFile(IncludeTrailingPathDelimiter(System.IOUtils.TPath.GetLibraryPath) + nmFile);
          FHome.Memo1.Lines.Add('Save To : ' + IncludeTrailingPathDelimiter(System.IOUtils.TPath.GetLibraryPath) + nmFile);
        end);
      except
        on E : Exception do
          FHome.Memo1.Lines.Add(E.Message + ''#13 + E.ClassName);
      end;
    finally
      Stream.DisposeOf;
    end;
  finally
    HTTP.DisposeOf;
  end;
end;

procedure fnSetPlay(FID, FNama : String);
begin
  TThread.Synchronize(nil, procedure begin
    with FMain do begin
      btnNowPlaying.ImageIndex := 9;
      lblNama.Text := FNama;
      if FileExists(fnLoadFile(FID + '.png')) then begin
        reImgNowPlaying.Fill.Bitmap.Bitmap.LoadFromFile(fnLoadFile(FID + '.png'));
        imgNowPlaying.Bitmap.LoadFromFile(fnLoadFile(FID + '.png'));
      end else begin
        reImgNowPlaying.Fill.Bitmap.Bitmap.LoadFromFile(fnLoadFile('noImage.png'));
        imgNowPlaying.Bitmap.LoadFromFile(fnLoadFile('noImage.png'));
      end;
    end;
  end);
end;

procedure fnIsPlay(isPlay : Boolean = True);
begin
  TThread.Synchronize(nil, procedure begin
    with FMain do begin
      if isPlay then begin
        if DM.Radio.StreamURL <> '' then
          btnNowPlaying.ImageIndex := 9;
          if not DM.Radio.Play then begin
            btnNowPlaying.ImageIndex := 8;
          end;
      end else begin
        DM.Radio.Stop;
        btnNowPlaying.ImageIndex := 8;
      end;
    end;
  end);
end;

procedure fnSetText(FText : String);
begin
  TThread.Synchronize(nil, procedure begin
    with FMain do begin
      lblStatus.Text := FText;
    end;
  end);
end;

procedure fnCheckLibrary;
const
  FLib : array[0..7] of string =
    (
      'libbass.so', 'libbass_ssl.so', 'libbassenc.so', 'libbassflac_so',
      'libbassenc_flac.so', 'libbassenc_mp3.so', 'libbassenc_ogg.so', 'libbassenc_opus.so'
    );
var
  delim : TStringList;
  FText : String;
  req : String;
begin
  delim := TStringList.Create;
  try
    FText := IncludeTrailingPathDelimiter(System.IOUtils.TPath.GetLibraryPath);
    {$IF DEFINED (ANDROID)}
      delim.Delimiter := '/';
    {$ELSE}
      delim.Delimiter := '\';
    {$ENDIF}
    delim.DelimitedText := FText;
    FText := delim[delim.Count - 2];
  finally
    delim.DisposeOf;
  end;

  {$IF DEFINED (ANDROID)}
  try
    for var i := 0 to Length(FLib) - 1 do begin
      if not FileExists(System.IOUtils.TPath.GetLibraryPath + FLib[i]) then begin
        FHome.Memo1.Lines.Add('File Not Exist : ' + IncludeTrailingPathDelimiter(System.IOUtils.TPath.GetLibraryPath) + FLib[i]);
        fnDownloadLib(URLImage + FText + '/' + FLib[i], FLib[i]);
      end else begin
        FHome.Memo1.Lines.Add('File Exist : ' + IncludeTrailingPathDelimiter(System.IOUtils.TPath.GetLibraryPath) + FLib[i]);
      end;
    end;
  except
    on E : Exception do
      FHome.Memo1.Lines.Add(E.Message + ''#13 + E.ClassName);
  end;

  {$ENDIF}

end;


end.
