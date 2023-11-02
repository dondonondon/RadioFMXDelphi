unit frDetail;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, System.Threading, FMX.Objects,
  System.Actions, FMX.ActnList, FMX.TabControl, FMXTee.Series, FMXTee.Engine,
  FMXTee.Procs, FMXTee.Chart, FMX.Ani, FMX.ImgList, FMX.Memo.Types,
  FMX.ScrollBox, FMX.Memo, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  FMX.Edit, FMX.ListBox, FMX.Effects;

type
  TFDetail = class(TFrame)
    memData: TFDMemTable;
    loMain: TLayout;
    background: TRectangle;
    lbSearch: TListBox;
    loHeader: TLayout;
    reHeader: TRectangle;
    Label1: TLabel;
    reHeaderBtn: TRectangle;
    lblPos: TLabel;
    edSearch: TEdit;
    reSearch: TRectangle;
    btnSearch: TCornerButton;
    btnBack: TCornerButton;
    loTemp: TLayout;
    reTempBackground: TRectangle;
    imgTemp: TImage;
    lblTempNama: TLabel;
    imgTempBlur: TImage;
    seTempShadow: TShadowEffect;
    btnTempFavorite: TCornerButton;
    seHeader: TShadowEffect;
    procedure FirstShow;
    procedure btnBackClick(Sender: TObject);
    procedure lbSearchItemClick(const Sender: TCustomListBox;
      const Item: TListBoxItem);
    procedure lbSearchViewportPositionChange(Sender: TObject;
      const OldViewportPosition, NewViewportPosition: TPointF;
      const ContentSizeChanged: Boolean);
  private
    statF : Boolean;
    isProses : Boolean;
    procedure setFrame;
    procedure addItem(FLB : TListBox; FNama, FURLStream: String; FFavorite, FID: Integer);
    procedure fnLoadData;
    procedure fnDownloadImages(FMemData : TFDMemTable; FMin, FMax : Integer);
    procedure fnClickFavorite(Sender : TObject);
    procedure fnProsesFavorite(FCorner : TCornerButton);
    procedure fnLoadMore;
    procedure fnBannerFail(Sender: TObject; const Error: string);
    procedure fnSetBanner;
  public
    FJenis : String;
    procedure ReleaseFrame;
  end;

var
  FDetail : TFDetail;

implementation

{$R *.fmx}

uses BFA.Func, BFA.GoFrame, BFA.Helper.Control, BFA.Helper.Main, BFA.Main,
  BFA.OpenUrl, BFA.Rest, uDM, frHome, BFA.Admob, frMain;

{ TFTemp }

const
  spc = 10;
  pad = 8;

procedure TFDetail.addItem(FLB: TListBox; FNama, FURLStream: String; FFavorite,
  FID: Integer);
var
  lb : TListBoxItem;
  lo : TLayout;
begin
  lblTempNama.Text := FNama;
  if FFavorite = 1 then
    btnTempFavorite.ImageIndex := 5
  else
    btnTempFavorite.ImageIndex := 6;

  try
    if FileExists(fnLoadFile(FID.ToString + '.png')) then
      imgTemp.Bitmap.LoadFromFile(fnLoadFile(FID.ToString + '.png'))
    else
      imgTemp.Bitmap.LoadFromFile(fnLoadFile('noImage.png'));

    if FileExists(fnLoadFile(FID.ToString + '.png')) then
      imgTempBlur.Bitmap.LoadFromFile(fnLoadFile(FID.ToString + '.png'))
    else
      imgTempBlur.Bitmap.LoadFromFile(fnLoadFile('noImage.png'));
  except
    imgTemp.Bitmap.LoadFromFile(fnLoadFile('noImage.png'));
    imgTempBlur.Bitmap.LoadFromFile(fnLoadFile('noImage.png'));
  end;

  lb := TListBoxItem.Create(nil);
  lb.Selectable := False;
  lb.Width := lbSearch.Width;
  lb.Height := loTemp.Height + 12;
  lb.Text := FURLStream;
  lb.Tag := FID;
  lb.TagString := memData.RecNo.ToString;

  lb.FontColor := TAlphaColorRec.Null;
  lb.StyledSettings := [];

  lo := TLayout(loTemp.Clone(nil));
  lo.Width := lb.Width;
  lo.Position.X := 0;
  lo.Position.Y := 4;

  lo.Visible := True;

  TCornerButton(lo.FindStyleResource('btnTempFavorite')).OnClick := fnClickFavorite;

  lb.AddObject(lo);

  FLB.AddObject(lb);
end;

procedure TFDetail.btnBackClick(Sender: TObject);
begin
  fnBack();
end;

procedure TFDetail.FirstShow;
begin
  setFrame;

  fnSetBanner;

  lbSearch.OnViewportPositionChange := nil;
  lbSearch.Items.Clear;

  TTask.Run(procedure begin
    fnLoadLoading(True);
    try
      Sleep(CIdle);
      fnLoadData;
    finally
      fnLoadLoading(False);
    end;
  end).Start;
end;

procedure TFDetail.fnBannerFail(Sender: TObject; const Error: string);
begin
  if Assigned(TImage(FLayoutBanner.FindStyleResource('banner_image'))) then begin
    TImage(FLayoutBanner.FindStyleResource('banner_image')).Visible := True;
  end;
end;

procedure TFDetail.fnClickFavorite(Sender: TObject);
begin
  TTask.Run(procedure begin
    fnProsesFavorite(TCornerButton(Sender));
  end);
end;

procedure TFDetail.fnLoadData;
var
  req : String;
  lb : TListBoxItem;
begin
  lbSearch.OnViewportPositionChange := nil;
  try
    req := FJenis;
    DM.RReq.AddParameter('id_device', FToken);

    if not fnParsingJSON(req, memData) then begin
      fnShowMessage(memData.FieldByName('pesan').AsString);
      Exit;
    end;

    fnDownloadImages(memData, 1, memData.RecordCount);

    TThread.Synchronize(nil, procedure begin

      for var i := 0 to memData.RecordCount - 1 do begin
        addItem(lbSearch,
          memData.FieldByName('radio_name').AsString,
          fnReplaceStr(memData.FieldByName('stream_url').AsString, '\', ''),
          memData.FieldByName('favorite').AsInteger,
          memData.FieldByName('id').AsInteger
        );
        memData.Next;

        lbSearch.Tag := memData.RecNo;

        if i = 10 then
          Break;

        Application.ProcessMessages;
      end;

      var lb := TListBoxItem.Create(nil);
      lb.Width := lbSearch.Width;
      lb.Selectable := False;
      lb.Height := 80;
      lb.Text := '';

      lbSearch.AddObject(lb);
    end);

  finally
    lbSearch.OnViewportPositionChange := lbSearchViewportPositionChange;
  end;
end;

procedure TFDetail.fnDownloadImages(FMemData: TFDMemTable; FMin, FMax : Integer);
begin
  FMemData.RecNo := FMin;
  var ii := FMemData.RecNo - 1 + 11;

  for var i := FMin - 1 to FMax - 1 do begin
    if FMemData.FieldByName('radio_img').AsString <> '' then
      if not FileExists(fnLoadFile(FMemData.FieldByName('id').AsString + '.png')) then
        fnDownloadFile(URLImage + FMemData.FieldByName('id').AsString + '.png',
          FMemData.FieldByName('id').AsString + '.png'
        );

    FMemData.Next;

    if i = ii then
      Break;
  end;

  FMemData.First;
end;

procedure TFDetail.fnLoadMore;
begin
  lbSearch.OnViewportPositionChange := nil;
  isProses := True;

  fnLoadLoading(True);
  try
    fnDownloadImages(memData, lbSearch.Tag, memData.RecordCount);

    TThread.Synchronize(nil, procedure begin
      lbSearch.ItemByIndex(lbSearch.Items.Count - 1).DisposeOf;

      memData.RecNo := lbSearch.Tag;
      var ii := memData.RecNo - 1 + 10;
      for var i := memData.RecNo - 1 to memData.RecordCount - 1 do begin
        addItem(lbSearch,
          memData.FieldByName('radio_name').AsString,
          fnReplaceStr(memData.FieldByName('stream_url').AsString, '\', ''),
          memData.FieldByName('favorite').AsInteger,
          memData.FieldByName('id').AsInteger
        );
        memData.Next;

        lbSearch.Tag := memData.RecNo;

        if i = ii then
          Break;

        Application.ProcessMessages;
      end;

      var lb := TListBoxItem.Create(nil);
      lb.Width := lbSearch.Width;
      lb.Selectable := False;
      lb.Height := 80;
      lb.Text := '';

      lbSearch.AddObject(lb);
    end);
  finally
    fnLoadLoading(False);
    lbSearch.OnViewportPositionChange := lbSearchViewportPositionChange;

    isProses := False;
  end;
end;

procedure TFDetail.fnProsesFavorite(FCorner: TCornerButton);
var
  req : String;
  lb : TListBoxItem;
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

    if DM.memData.FieldByName('status').AsInteger = 1 then begin
      fnShowMessage('Berhasil Ditambahkan di Favorite');
      FCorner.Images := DM.img;
      FCorner.ImageIndex := 5;
    end else begin
      fnShowMessage('Berhasil Dihapus dari Favorite');
      FCorner.Images := DM.img;
      FCorner.ImageIndex := 6;
    end;

    FHome.isReload := False;

  finally

  end;
end;

procedure TFDetail.fnSetBanner;
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

      lbSearch.setPosYAfter(FLayoutBanner);
      lbSearch.Height := Self.Height - (FLayoutBanner.Height + loHeader.Height);
    end);
  end else begin
    TThread.Synchronize(nil, procedure begin
      lbSearch.setPosYAfter(loHeader);
      lbSearch.Height := Self.Height - loHeader.Height;
    end);
  end;
end;

procedure TFDetail.lbSearchItemClick(const Sender: TCustomListBox;
  const Item: TListBoxItem);
var
  req : String;
begin
  if DM.Radio.IsOpening then begin
    fnShowMessage('Mohon Tunggu, Sedang Menghubungkan');
    Exit;
  end;

  memData.RecNo := StrToIntDef(Item.TagString, 1);

  DM.Radio.Stop;
  fnSetPlay(Item.Tag.ToString, memData.FieldByName('radio_name').AsString);

  TTask.Run(procedure begin
    fnShowMessage('Menghubungkan ' + memData.FieldByName('radio_name').AsString);
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

procedure TFDetail.lbSearchViewportPositionChange(Sender: TObject;
  const OldViewportPosition, NewViewportPosition: TPointF;
  const ContentSizeChanged: Boolean);
begin
  if Round(lbSearch.ViewportPosition.Y + 0.4999) >= (lbSearch.ContentBounds.Size.cy - lbSearch.Height) then begin
    if isProses then
      Exit;

    if lbSearch.Tag >= memData.RecordCount then
      Exit;

    TTask.Run(procedure begin
      fnLoadMore;
    end).Start;
  end;
end;

procedure TFDetail.ReleaseFrame;
begin
  DisposeOf;
end;

procedure TFDetail.setFrame;
begin
  Self.setAnchorContent;

  loTemp.Visible := False;

  if statF then
    Exit;

  statF := True;

end;

end.
