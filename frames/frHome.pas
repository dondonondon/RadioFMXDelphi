unit frHome;

interface

uses
  System.SysUtils, System.Variants, System.Classes, System.Types, System.UITypes,
  System.Rtti, FMX.Forms, FMX.Dialogs, FMX.Types, FMX.Layouts, FMX.Styles, FMX.StdCtrls,
  FMX.ListBox, FMX.Objects, FMX.Controls, FMX.Edit, FMX.Effects, FMX.Graphics,
  FMX.Controls.Presentation, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client, System.Threading,
  FMX.ImgList, System.IOUtils, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.DialogService, System.Permissions;

type
  TFHome = class(TFrame)
    loMain: TLayout;
    background: TRectangle;
    lbMain: TListBox;
    loHeader: TLayout;
    Rectangle1: TRectangle;
    seHeader: TShadowEffect;
    lbiRadio: TListBoxItem;
    Label1: TLabel;
    Label2: TLabel;
    lbiFavorite: TListBoxItem;
    Label3: TLabel;
    Label4: TLabel;
    lbiListenerToday: TListBoxItem;
    Label5: TLabel;
    Label6: TLabel;
    lbiListenerAll: TListBoxItem;
    Label7: TLabel;
    Label8: TLabel;
    lbRadio: TListBox;
    lbFavorite: TListBox;
    lbListenerToday: TListBox;
    lbListenerAll: TListBox;
    ListBoxItem17: TListBoxItem;
    CornerButton1: TCornerButton;
    btnFind: TCornerButton;
    lbiMyFavorite: TListBoxItem;
    Label9: TLabel;
    Label10: TLabel;
    lbMyFavorite: TListBox;
    memFavorite: TFDMemTable;
    memData: TFDMemTable;
    memListener: TFDMemTable;
    memListenerAll: TFDMemTable;
    memRadio: TFDMemTable;
    memMyFavorite: TFDMemTable;
    tempImg: TImage;
    loReload: TLayout;
    Rectangle2: TRectangle;
    btnReload: TCornerButton;
    lblPesan: TLabel;
    CornerButton2: TCornerButton;
    Memo1: TMemo;
    procedure FirstShow;
    procedure btnBackClick(Sender: TObject);
    procedure Rectangle1Click(Sender: TObject);
    procedure CornerButton1Click(Sender: TObject);
    procedure btnFindClick(Sender: TObject);
    procedure lbRadioItemClick(const Sender: TCustomListBox;
      const Item: TListBoxItem);
    procedure btnReloadClick(Sender: TObject);
    procedure fnClickSeeAll(Sender : TObject);
    procedure CornerButton2Click(Sender: TObject);
  private
    statF : Boolean;
    procedure setFrame;
    procedure addItem(FLB : TListBox; FNama, FURLStream : String; FFavorite, FID : Integer);
    procedure addData(FLB : TListBox; FMemData : TFDMemTable);
    procedure fnDownloadImages(FMemData : TFDMemTable);
    procedure fnLoadData;
    procedure fnClickFavorite(Sender : TObject);
    procedure fnProsesFavorite(FCorner : TCornerButton);
    procedure fnBannerFail(Sender: TObject; const Error: string);
    procedure fnSetBanner;
  public
    isReload : Boolean;
    procedure ReleaseFrame;
    procedure fnGoBack;
  end;

var
  FHome : TFHome;

implementation

{$R *.fmx}

uses BFA.Func, BFA.GoFrame, BFA.Helper.Control, BFA.Helper.Main, BFA.Main,
  BFA.OpenUrl, BFA.Rest, frMain, uDM, BFA.HelperMemTable, frDetail, BFA.Admob,
  BFA.Permission;


{ TFTemp }

const
  spc = 10;
  pad = 8;

procedure TFHome.addData(FLB: TListBox; FMemData: TFDMemTable);
var
  ii : Integer;
begin
  TThread.Synchronize(nil, procedure begin
    FLB.Items.Clear;
    for var i := 0 to FMemData.RecordCount - 1 do begin
      if FMemData.Tag = 1 then
        ii := 0
      else
        ii := FMemData.FieldByName('favorite').AsInteger;

      addItem(FLB, FMemData.FieldByName('radio_name').AsString,
        fnReplaceStr(FMemData.FieldByName('stream_url').AsString, '\', ''),
        ii,
        FMemData.FieldByName('id').AsInteger
      );
      FMemData.Next;
    end;
  end);
end;

procedure TFHome.addItem(FLB : TListBox; FNama, FURLStream: String; FFavorite, FID: Integer);
var
  lb : TListBoxItem;
begin
  lb := TListBoxItem.Create(nil);
  lb.Selectable := False;

  lb.Width := 147;

  lb.Text := FURLStream;
  lb.Tag := FID;

  lb.StyleLookup := 'lbTempRadio';

  lb.StylesData['lblText.Text'] := fnReplaceStr(FNama, '\', '-');;
  lb.StylesData['glFavorite.Images'] := FMain.img;
  if FFavorite = 1 then
    lb.StylesData['glFavorite.ImageIndex'] := 5
  else
    lb.StylesData['glFavorite.ImageIndex'] := 6;

  try
    if FileExists(fnLoadFile(FID.ToString + '.png')) then
      lb.StylesData['img'] := fnLoadFile(FID.ToString + '.png')
    else
      lb.StylesData['img'] := fnLoadFile('noImage.png');

    if FileExists(fnLoadFile(FID.ToString + '.png')) then
      lb.StylesData['img_blur'] := fnLoadFile(FID.ToString + '.png')
    else
      lb.StylesData['img_blur'] := fnLoadFile('noImage.png');
  except
    lb.StylesData['img'] := fnLoadFile('noImage.png');
    lb.StylesData['img_blur'] := fnLoadFile('noImage.png');
  end;

  lb.StylesData['reFavorite.onClick'] := TValue.From<TNotifyEvent>(fnClickFavorite);
  lb.StylesData['reFavorite.TagString'] := FID.ToString;

  FLB.AddObject(lb);
end;

procedure TFHome.btnBackClick(Sender: TObject);
begin
  fnGoBack;
end;

procedure TFHome.btnFindClick(Sender: TObject);
begin
  fnGoFrame(C_HOME, C_SEARCH);
end;

procedure TFHome.btnReloadClick(Sender: TObject);
begin
  FirstShow;
end;

procedure TFHome.CornerButton1Click(Sender: TObject);
begin
  fnGoFrame(C_HOME, C_DETAIL);
end;

procedure TFHome.CornerButton2Click(Sender: TObject);
begin
  HelperPermission.SetPermission(
    [
      GetPermission.READ_EXTERNAL_STORAGE, GetPermission.WRITE_EXTERNAL_STORAGE
    ],
    procedure begin
      Memo1.Lines.Clear;
      fnCheckLibrary;
    end);
end;

procedure TFHome.FirstShow;
begin
  setFrame;

  fnSetBanner;

  if isReload then
    Exit;

  lbMain.Visible := False;

  TTask.Run(procedure begin
    Sleep(CIdle);
    fnLoadData;
  end).Start;

end;

procedure TFHome.fnBannerFail(Sender: TObject; const Error: string);
begin
  if Assigned(TImage(FLayoutBanner.FindStyleResource('banner_image'))) then begin
    TImage(FLayoutBanner.FindStyleResource('banner_image')).Visible := True;
  end;
end;

procedure TFHome.fnClickFavorite(Sender: TObject);
begin
  TTask.Run(procedure begin
    fnProsesFavorite(TCornerButton(Sender));
  end);
end;

procedure TFHome.fnClickSeeAll(Sender: TObject);
begin
  FDetail.FJenis := TLabel(Sender).Hint;
  fnGoFrame(C_HOME, C_DETAIL);
end;

procedure TFHome.fnDownloadImages(FMemData: TFDMemTable);
begin
  for var i := 0 to FMemData.RecordCount - 1 do begin
    if FMemData.FieldByName('radio_img').AsString <> '' then
      if not FileExists(fnLoadFile(FMemData.FieldByName('id').AsString + '.png')) then
        fnDownloadFile(URLImage + FMemData.FieldByName('id').AsString + '.png',
          FMemData.FieldByName('id').AsString + '.png'
        );

    FMemData.Next;
  end;

  FMemData.First;
end;

procedure TFHome.fnGoBack;
begin
  fnGoFrame(GoFrame, FromFrame);
end;

procedure TFHome.fnLoadData;
var
  req : String;
begin
  fnLoadLoading(True);
  try
    req := 'loadHome';
    DM.RReq.AddParameter('id_device', FToken);
    if not fnParsingJSON(req, memData) then begin
      fnShowMessage(memData.FieldByName('pesan').AsString);

      TThread.Synchronize(nil, procedure begin
        loReload.Visible := True;
        loReload.BringToFront;

        lblPesan.Text := memData.FieldByName('pesan').AsString;
      end);

      isReload := False;

      Exit;
    end;

    if memData.FieldByName('radio_status').AsInteger = 1 then
      if memRadio.FillDataFromString(memData.FieldByName('radio').AsString) then
        fnDownloadImages(memRadio);

    if memData.FieldByName('my_favorite_status').AsInteger = 1 then
      if memMyFavorite.FillDataFromString(memData.FieldByName('my_favorite').AsString) then
        fnDownloadImages(memMyFavorite);

    if memData.FieldByName('favorite_status').AsInteger = 1 then
      if memFavorite.FillDataFromString(memData.FieldByName('favorite').AsString) then
        fnDownloadImages(memFavorite);

    if memData.FieldByName('listener_status').AsInteger = 1 then
      if memListener.FillDataFromString(memData.FieldByName('listener').AsString) then
        fnDownloadImages(memListener);

    if memData.FieldByName('listener_all_status').AsInteger = 1 then
      if memListenerAll.FillDataFromString(memData.FieldByName('listener_all').AsString) then
        fnDownloadImages(memListenerAll);



    if memData.FieldByName('radio_status').AsInteger = 1 then begin
      if memRadio.FillDataFromString(memData.FieldByName('radio').AsString) then begin
        addData(lbRadio, memRadio);
      end;
    end else
      lbiRadio.Visible := False;

    if memData.FieldByName('my_favorite_status').AsInteger = 1 then begin
      if memMyFavorite.FillDataFromString(memData.FieldByName('my_favorite').AsString) then begin
        addData(lbMyFavorite, memMyFavorite);
      end;
    end else
      lbiMyFavorite.Visible := False;

    if memData.FieldByName('favorite_status').AsInteger = 1 then begin
      if memFavorite.FillDataFromString(memData.FieldByName('favorite').AsString) then begin
        addData(lbFavorite, memFavorite);
      end;
    end else
      lbiFavorite.Visible := False;

    if memData.FieldByName('listener_status').AsInteger = 1 then begin
      if memListener.FillDataFromString(memData.FieldByName('listener').AsString) then begin
        addData(lbListenerToday, memListener);
      end;
    end else
      lbiListenerToday.Visible := False;

    if memData.FieldByName('listener_all_status').AsInteger = 1 then begin
      if memListenerAll.FillDataFromString(memData.FieldByName('listener_all').AsString) then begin
        addData(lbListenerAll, memListenerAll);
      end;
    end else
      lbiListenerAll.Visible := False;


    isReload := True;
  finally
    fnLoadLoading(False);
    TThread.Synchronize(nil, procedure begin
      lbMain.Visible := True;
    end);
  end;
end;

procedure TFHome.fnProsesFavorite(FCorner : TCornerButton);
var
  req : String;
  lb : TListBoxItem;
  gl : TGlyph;
begin
  try
    req := 'updateFavorite';
    DM.RReq.AddParameter('id_radio', FCorner.TagString);
    DM.RReq.AddParameter('id_device', FToken);
    if not fnParsingJSON(req, DM.memData) then begin
      fnShowMessage(DM.memData.FieldByName('pesan').AsString);
      Exit;
    end;

    lb := TListBoxItem(FCorner.Parent);
    gl := TGlyph(lb.FindStyleResource('glFavorite'));

    if DM.memData.FieldByName('status').AsInteger = 1 then begin
      fnShowMessage('Berhasil Ditambahkan di Favorite');
      gl.Images := DM.img;
      gl.ImageIndex := 5;
    end else begin
      fnShowMessage('Berhasil Dihapus dari Favorite');
      gl.Images := DM.img;
      gl.ImageIndex := 6;
    end;

    isReload := False;

  finally

  end;
end;

procedure TFHome.fnSetBanner;
begin
  if FIsAdmob then begin
    fnDisposeBanner;
    TThread.Synchronize(nil, procedure begin
      if Assigned(FLayoutBanner) then begin
        FLayoutBanner.DisposeOf;
        FLayoutBanner := nil;
      end;

      FLayoutBanner := TLayout.Create(nil);
      FLayoutBanner.Width := Self.Width;
      FLayoutBanner.Height := 66;
      FLayoutBanner.Position.X := 0;
      FLayoutBanner.setPosYAfter(loHeader);
    end);

    fnCreateBanner(vIDBanner, FLayoutBanner, fnBannerFail, FPosBannerCenter);

    TThread.Synchronize(nil, procedure begin
      Self.AddObject(FLayoutBanner);

      lbMain.setPosYAfter(FLayoutBanner);
      lbMain.Height := Self.Height - (FLayoutBanner.Height + loHeader.Height);
    end);
  end else begin
    TThread.Synchronize(nil, procedure begin
      lbMain.setPosYAfter(loHeader);
      lbMain.Height := Self.Height - loHeader.Height;
    end);
  end;
end;

procedure TFHome.lbRadioItemClick(const Sender: TCustomListBox;
  const Item: TListBoxItem);
var
  req : String;
begin
  if DM.Radio.IsOpening then begin
    fnShowMessage('Mohon Tunggu, Sedang Menghubungkan');
    Exit;
  end;

  DM.Radio.Stop;
  fnSetPlay(Item.Tag.ToString, TLabel(Item.FindStyleResource('lblText')).Text);

  TTask.Run(procedure begin
    fnShowMessage('Menghubungkan ' + TLabel(Item.FindStyleResource('lblText')).Text);
    fnSetText('Menghubungkan...');
    //fnLoadLoading(True);
    try
      Sleep(100);
      DM.Radio.StreamURL := Item.Text;
      if not DM.Radio.Play then begin
        fnShowMessage('Radio Sedang Offline');
        fnSetText('Channel Offline');
        fnIsPlay(False);
      end else begin
        fnSetText('Sedang Dimainkan');
        fnIsPlay;
      end;

      req := 'updateListener';
      DM.RReq.AddParameter('id_radio', Item.Tag.ToString);
      DM.RReq.AddParameter('id_device', FToken);

      fnParsingJSON(req, DM.memData);

    finally
      fnLoadLoading(False);
    end;
  end).Start;
end;

procedure TFHome.Rectangle1Click(Sender: TObject);
begin
  fnGoFrame(C_HOME, C_DETAIL);
end;

procedure TFHome.ReleaseFrame;
begin
  DisposeOf;
end;

procedure TFHome.setFrame;
begin
  Self.setAnchorContent;

  FMain.loNowPlaying.Visible := True;
  loReload.Visible := False;

  if statF then
    Exit;

  statF := True;

end;

end.
