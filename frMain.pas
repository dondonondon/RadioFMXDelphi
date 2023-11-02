unit frMain;

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
  FMX.BASS.Classes, FMX.Player, FMX.BassComponents, FMX.Edit
  {$IF Defined(ANDROID)}
    ,Androidapi.JNI.AdMob, Androidapi.Helpers, FMX.Platform.Android,
    FMX.Helpers.Android, Androidapi.JNI.PlayServices, Androidapi.JNI.Os,
    Androidapi.JNI.JavaTypes, Androidapi.JNIBridge, FMX.PushNotification.Android, Androidapi.JNI.Embarcadero;
  {$ELSEIF Defined(MSWINDOWS)}
    ;
  {$ENDIF}

type
  TFMain = class(TForm)
    loMain: TLayout;
    faFromX: TFloatAnimation;
    faGoX: TFloatAnimation;
    vsMain: TVertScrollBox;
    loFrame: TLayout;
    NotificationCenter: TNotificationCenter;
    loNowPlaying: TLayout;
    reNowPlaying: TRectangle;
    seNowPlaying: TShadowEffect;
    lblStatus: TLabel;
    lblNama: TLabel;
    reImgNowPlaying: TRectangle;
    SB: TStyleBook;
    loLoad: TLayout;
    reLoad: TRectangle;
    aniLoad: TFMXLoadingIndicator;
    lblLoad: TLabel;
    TM: TToastManager;
    btnNowPlaying: TCornerButton;
    imgNowPlaying: TImage;
    seImgNowPlaying: TShadowEffect;
    img: TImageList;
    procedure FormVirtualKeyboardHidden(Sender: TObject;
      KeyboardVisible: Boolean; const Bounds: TRect);
    procedure FormVirtualKeyboardShown(Sender: TObject;
      KeyboardVisible: Boolean; const Bounds: TRect);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure faFromXFinish(Sender: TObject);
    procedure faGoXFinish(Sender: TObject);
    procedure faFromXProcess(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnNowPlayingClick(Sender: TObject);
  private
    {Keyboard}
    FService1 : IFMXVirtualKeyboardToolbarService;
    FKBBounds: TRectF;
    FNeedOffset: Boolean;
    {Keyboard}
    {$IFDEF ANDROID}
    PushService: TPushService;
    ServiceConnection: TPushServiceConnection;
    DeviceId: string;
    DeviceToken: string;

    procedure DoServiceConnectionChange(Sender: TObject; PushChanges: TPushService.TChanges);
    procedure DoReceiveNotificationEvent(Sender: TObject; const ServiceNotification: TPushServiceNotification);
    function AppEventProc(AAppEvent: TApplicationEvent; AContext: TObject): Boolean;
    procedure CancelarNotificacao(nome : string);
    {$ENDIF}
    {Keyboard}
    procedure CalcContentBoundsProc(Sender: TObject;
                                    var ContentBounds: TRectF);
    procedure RestorePosition;
    procedure UpdateKBBounds;
    {Keyboard}
  public
    { Public declarations }
  end;

var
  FMain: TFMain;

implementation

{$R *.fmx}

uses BFA.Func, BFA.Helper.Control, BFA.GoFrame, BFA.Main, uDM;

{ TFMain }

{$IFDEF ANDROID}
function TFMain.AppEventProc(AAppEvent: TApplicationEvent;
  AContext: TObject): Boolean;
begin
    if (AAppEvent = TApplicationEvent.BecameActive) then
        CancelarNotificacao('');
end;

procedure TFMain.CancelarNotificacao(nome: string);
begin
  if nome = '' then
      NotificationCenter.CancelAll
  else
      NotificationCenter.CancelNotification(nome);
end;

procedure TFMain.DoReceiveNotificationEvent(Sender: TObject;
  const ServiceNotification: TPushServiceNotification);
var
  MessageText: string;
  x: Integer;

  NotificationCenter: TNotificationCenter;
  Notification: TNotification;
begin
  MessageText := '';
  try
    for x := 0 to ServiceNotification.DataObject.Count - 1 do begin
      //IOS
      if ServiceNotification.DataKey = 'aps' then
      begin
        if ServiceNotification.DataObject.Pairs[x].JsonString.Value = 'alert' then
          MessageText := ServiceNotification.DataObject.Pairs[x].JsonValue.Value;
      end;

      // Android...
      if ServiceNotification.DataKey = 'fcm' then
      begin
        // Firebase console...
        if ServiceNotification.DataObject.Pairs[x].JsonString.Value = 'gcm.notification.body' then
          MessageText := ServiceNotification.DataObject.Pairs[x].JsonValue.Value;

        // Nosso server...
        if ServiceNotification.DataObject.Pairs[x].JsonString.Value = 'mensagem' then
          MessageText := ServiceNotification.DataObject.Pairs[x].JsonValue.Value;
      end;

      if Length(MessageText) > 0 then
          break;

    end;

  except on ex:exception do
          //showmessage(ex.Message);
  end;

  NotificationCenter := TNotificationCenter.Create(nil);
  try
    Notification := NotificationCenter.CreateNotification;
    try
      Notification.Name := MessageText;
      Notification.AlertBody := MessageText;
      Notification.Title := MessageText;
      Notification.EnableSound := False;
      NotificationCenter.PresentNotification(Notification);
    finally
      Notification.DisposeOf;
    end;
  finally
    NotificationCenter.DisposeOf;
  end;
end;

procedure TFMain.DoServiceConnectionChange(Sender: TObject;
  PushChanges: TPushService.TChanges);
begin
  if TPushService.TChange.DeviceToken in PushChanges then
  begin
    DeviceId := PushService.DeviceIDValue[TPushService.TDeviceIDNames.DeviceId];
    DeviceToken := PushService.DeviceTokenValue[TPushService.TDeviceTokenNames.DeviceToken];
    //MemLog.Lines.Add('DEVICE_ID = ' + DeviceId);
    //MemLog.Lines.Add('DEVICE_TOKEN = ' + DeviceToken);
    FToken := DeviceToken;
  end;
end;
{$ENDIF}

procedure TFMain.btnNowPlayingClick(Sender: TObject);
begin
  if DM.Radio.IsOpening then begin
    fnShowMessage('Mohon Tunggu, Sedang Menghubungkan');
    Exit;
  end;

  if btnNowPlaying.ImageIndex = 8 then begin
    DM.Radio.Stop;

    btnNowPlaying.ImageIndex := 9;

    TTask.Run(procedure begin
      try
        if DM.Radio.StreamURL = '' then
          Exit;

        fnShowMessage('Menghubungkan ' + lblNama.Text);
        fnSetText('Menghubungkan...');

        if not DM.Radio.Play then begin
          fnShowMessage('Radio Sedang Offline');
          fnSetText('Channel Offline');
          fnIsPlay(False);
        end else begin
          fnSetText('Sedang Dimainkan');
          fnIsPlay;
        end;
      finally
        fnLoadLoading(False);
      end;
    end).Start;
  end else begin
    fnIsPlay(False);
  end;
end;

procedure TFMain.CalcContentBoundsProc(Sender: TObject;
  var ContentBounds: TRectF);
begin
if FNeedOffset and (FKBBounds.Top > 0) then
  begin
    ContentBounds.Bottom := Max(ContentBounds.Bottom,
                                2 * ClientHeight - FKBBounds.Top);
  end;
end;

procedure TFMain.faFromXFinish(Sender: TObject);
begin
  TFloatAnimation(Sender).Enabled := False;
end;

procedure TFMain.faFromXProcess(Sender: TObject);
begin
  Application.ProcessMessages;
end;

procedure TFMain.faGoXFinish(Sender: TObject);
var
  FLayout : TLayout;
begin
  TFloatAnimation(Sender).Enabled := False;
  FLayout := TLayout(VFRGo.FindComponent('loMain'));
  if Assigned(FLayout) then
    if goFrame <> C_LOADING then
      FLayout.Visible := True;

  fnHideFrame(fromFrame);
end;

procedure TFMain.FormCreate(Sender: TObject);
var
  FormatBr: TFormatSettings;
  AppEvent : IFMXApplicationEventService;
begin
  {$IF DEFINED(IOS) or DEFINED(ANDROID)}
    if TPlatformServices.Current.SupportsPlatformService(IFMXVirtualKeyboardToolbarService, IInterface(FService1)) then
    begin
      FService1.SetToolbarEnabled(True);
      FService1.SetHideKeyboardButtonVisibility(True);
    end;

//    if TPlatformServices.Current.SupportsPlatformService(IFMXApplicationEventService, IInterface(AppEvent)) then
//        AppEvent.SetApplicationEventHandler(AppEventProc);
//
//    {$IFDEF IOS}
//      PushService := TPushServiceManager.Instance.GetServiceByName(TPushService.TServiceNames.APS);
//    {$ELSE}
//      PushService := TPushServiceManager.Instance.GetServiceByName(TPushService.TServiceNames.FCM);
//    {$ENDIF}
//
//    ServiceConnection := TPushServiceConnection.Create(PushService);
//    ServiceConnection.OnChange := DoServiceConnectionChange;
//    ServiceConnection.OnReceiveNotification := DoReceiveNotificationEvent;
//
//    FPermissionReadExternalStorage := JStringToString(TJManifest_permission.JavaClass.READ_EXTERNAL_STORAGE);      //permission
//    FPermissionWriteExternalStorage := JStringToString(TJManifest_permission.JavaClass.WRITE_EXTERNAL_STORAGE);     //permission
//    FAccess_Coarse_Location := JStringToString(TJManifest_permission.JavaClass.ACCESS_COARSE_LOCATION);
//    FAccess_Fine_Location := JStringToString(TJManifest_permission.JavaClass.ACCESS_FINE_LOCATION);

    TAndroidHelper.Activity.getWindow.setStatusBarColor($FF3E424F);
    TAndroidHelper.Activity.getWindow.setNavigationBarColor($FF3E424F);
  {$ELSE}

  {$ENDIF}

  try
    FormatBr                     := TFormatSettings.Create;
    FormatBr.DecimalSeparator    := '.';
    FormatBr.ThousandSeparator   := ',';
    FormatBr.DateSeparator       := '-';
    FormatBr.ShortDateFormat     := 'yyyy-mm-dd';
    FormatBr.LongDateFormat      := 'yyyy-mm-dd hh:nn:ss';

    System.SysUtils.FormatSettings := FormatBr;
  except
  end;

  FListGo := TStringList.Create;

  vsMain.OnCalcContentBounds := CalcContentBoundsProc;
end;

procedure TFMain.FormDestroy(Sender: TObject);
begin
  if Assigned(FListGo) then
    FListGo.DisposeOf;
end;

procedure TFMain.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
  Shift: TShiftState);
var
  FService: IFMXVirtualKeyboardService;
begin
  if Key = vkHardwareBack  then
  begin
    TPlatformServices.Current.SupportsPlatformService(IFMXVirtualKeyboardService, IInterface(FService));
    if (FService <> nil) and (TVirtualKeyboardState.Visible in FService.VirtualKeyBoardState) then
    begin
      FService.HideVirtualKeyboard;
    end
    else
    begin
      Key := 0;

      fnBack;
    end;
  end
  else
  if Key = vkReturn then
  begin
    if (FService <> nil) and (TVirtualKeyboardState.Visible in FService.VirtualKeyBoardState) then
    begin
      FService.HideVirtualKeyboard;
    end;
  end;
end;

procedure TFMain.FormShow(Sender: TObject);
begin
  FToken := LoadSettingString('token', 'token_temporary', '');

  loNowPlaying.Visible := False;
//  {$IF DEFINED (ANDROID) OR DEFINED(IOS)}
//  ServiceConnection.Active := True;
//  {$ELSE}
//    FToken := 'jkasdhkjadsh98uada9sduasjio';
//  {$ENDIF}

  FIsAdmob := True;

  createFrame;
  fnGoFrame('', C_LOADING);
end;

procedure TFMain.FormVirtualKeyboardHidden(Sender: TObject;
  KeyboardVisible: Boolean; const Bounds: TRect);
begin
  FKBBounds.Create(0, 0, 0, 0);
  FNeedOffset := False;
  RestorePosition;
end;

procedure TFMain.FormVirtualKeyboardShown(Sender: TObject;
  KeyboardVisible: Boolean; const Bounds: TRect);
begin
  FKBBounds := TRectF.Create(Bounds);
  FKBBounds.TopLeft := ScreenToClient(FKBBounds.TopLeft);
  FKBBounds.BottomRight := ScreenToClient(FKBBounds.BottomRight);
  UpdateKBBounds;
end;

procedure TFMain.RestorePosition;
begin
  vsMain.ViewportPosition := PointF(vsMain.ViewportPosition.X, 0);
  loMain.Align := TAlignLayout.Contents;
  vsMain.Align := TAlignLayout.Contents;
  vsMain.RealignContent;
end;

procedure TFMain.UpdateKBBounds;
var
  LFocused : TControl;
  LFocusRect: TRectF;
begin
  FNeedOffset := False;
  if Assigned(Focused) then
  begin
    LFocused := TControl(Focused.GetObject);
    LFocusRect := LFocused.AbsoluteRect;
    LFocusRect.Offset(vsMain.ViewportPosition);
    if FullScreen = True then
      LFocusRect.Bottom := LFocusRect.Bottom + 50;
    if (LFocusRect.IntersectsWith(TRectF.Create(FKBBounds))) and
       (LFocusRect.Bottom > FKBBounds.Top) then
    begin
      FNeedOffset := True;
      loMain.Align := TAlignLayout.Horizontal;
      vsMain.RealignContent;
      Application.ProcessMessages;
      vsMain.ViewportPosition :=
        PointF(vsMain.ViewportPosition.X,
               LFocusRect.Bottom - FKBBounds.Top);
    end;
  end;
  if not FNeedOffset then
    RestorePosition;
end;

end.
