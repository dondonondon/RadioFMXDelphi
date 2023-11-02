unit frSearch;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, System.Threading, FMX.Effects,
  FMX.Objects, FMX.ListBox, FMX.Edit, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client;

type
  TFSearch = class(TFrame)
    loMain: TLayout;
    background: TRectangle;
    loHeader: TLayout;
    reHeader: TRectangle;
    Label1: TLabel;
    reHeaderBtn: TRectangle;
    lblPos: TLabel;
    edSearch: TEdit;
    reSearch: TRectangle;
    btnSearch: TCornerButton;
    btnBack: TCornerButton;
    lbSearch: TListBox;
    lblTempNama: TLabel;
    reTempBackground: TRectangle;
    imgTempBlur: TImage;
    seTempShadow: TShadowEffect;
    imgTemp: TImage;
    loTemp: TLayout;
    btnTempFavorite: TCornerButton;
    memData: TFDMemTable;
    procedure FirstShow;
    procedure btnSearchClick(Sender: TObject);
    procedure btnBackClick(Sender: TObject);
    procedure lbSearchItemClick(const Sender: TCustomListBox;
      const Item: TListBoxItem);
  private
    statF : Boolean;
    procedure setFrame;
    procedure addItem(FLB : TListBox; FNama, FURLStream: String; FFavorite, FID: Integer);
    procedure fnFindData(FKeyword : String);
    procedure fnDownloadImages(FMemData : TFDMemTable);
    procedure fnClickFavorite(Sender : TObject);
    procedure fnProsesFavorite(FCorner : TCornerButton);
    procedure fnBannerFail(Sender: TObject; const Error: string);
    procedure fnSetBanner;
  public
    { Public declarations }
    procedure ReleaseFrame;
    procedure fnGoBack;
  end;

var
  FSearch : TFSearch;

implementation

{$R *.fmx}

uses BFA.Func, BFA.GoFrame, BFA.Helper.Control, BFA.Helper.Main, BFA.Main,
  BFA.OpenUrl, BFA.Rest, uDM, frHome, BFA.Admob, frMain;

{ TFTemp }

const
  spc = 10;
  pad = 8;

procedure TFSearch.addItem(FLB: TListBox; FNama, FURLStream: String; FFavorite,
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

procedure TFSearch.btnBackClick(Sender: TObject);
begin
  fnBack;
end;

procedure TFSearch.btnSearchClick(Sender: TObject);
begin
  if edSearch.Text = '' then
    Exit;

  lbSearch.Items.Clear;

  TTask.Run(procedure begin
    fnLoadLoading(True);
    try
      fnFindData(edSearch.Text);
    finally
      fnLoadLoading(False);
    end;
  end).Start;
end;

procedure TFSearch.FirstShow;
begin
  setFrame;

  fnSetBanner;
end;

procedure TFSearch.fnBannerFail(Sender: TObject; const Error: string);
begin
  if Assigned(TImage(FLayoutBanner.FindStyleResource('banner_image'))) then begin
    TImage(FLayoutBanner.FindStyleResource('banner_image')).Visible := True;
  end;
end;

procedure TFSearch.fnClickFavorite(Sender: TObject);
begin
  TTask.Run(procedure begin
    fnProsesFavorite(TCornerButton(Sender));
  end);
end;

procedure TFSearch.fnDownloadImages(FMemData: TFDMemTable);
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

procedure TFSearch.fnFindData(FKeyword: String);
var
  req : String;
  lb : TListBoxItem;
begin
  try
    req := 'findRadio';
    DM.RReq.AddParameter('keyword', FKeyword);
    if not fnParsingJSON(req, memData) then begin
      fnShowMessage(memData.FieldByName('pesan').AsString);
      Exit;
    end;

    fnDownloadImages(memData);

    TThread.Synchronize(nil, procedure begin
      for var i := 0 to memData.RecordCount - 1 do begin
        addItem(lbSearch,
          memData.FieldByName('radio_name').AsString,
          fnReplaceStr(memData.FieldByName('stream_url').AsString, '\', ''),
          memData.FieldByName('favorite').AsInteger,
          memData.FieldByName('id').AsInteger
        );
        memData.Next;
      end;

      var lb := TListBoxItem.Create(nil);
      lb.Width := lbSearch.Width;
      lb.Selectable := False;
      lb.Height := 80;
      lb.Text := '';

      lbSearch.AddObject(lb);
    end);

  finally

  end;
end;

procedure TFSearch.fnGoBack;
begin
  fnGoFrame(GoFrame, FromFrame);
end;

procedure TFSearch.fnProsesFavorite(FCorner: TCornerButton);
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

procedure TFSearch.fnSetBanner;
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

procedure TFSearch.lbSearchItemClick(const Sender: TCustomListBox;
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

procedure TFSearch.ReleaseFrame;
begin
  DisposeOf;
end;

procedure TFSearch.setFrame;
begin
  Self.setAnchorContent;

  loTemp.Visible := False;

  if statF then
    Exit;

  statF := True;

end;

end.
