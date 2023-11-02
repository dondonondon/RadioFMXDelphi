unit BFA.HelperMemTable;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  System.Net.URLClient, System.Net.HttpClient, System.Net.HttpClientComponent,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client, System.JSON, System.Net.Mime;

type
  TFDMemTableHelper = class helper for TFDMemTable
    function FillError(FMessage, FError : String) : String;
    function FillDataFromString(FJSON : String) : Boolean;
    function FillDataFromURL(FURL : String) : Boolean; overload;
    function FillDataFromURL(FURL : String; FMultiPart : TMultipartFormData) : Boolean; overload;
  end;

implementation

function TFDMemTableHelper.FillDataFromString(FJSON: String) : Boolean;
var
  JObjectData : TJSONObject;
  JArrayJSON : TJSONArray;
  i, ii: Integer;
  isArray : Boolean;
begin
  try
    Self.Active := False;
    Self.Close;
    Self.FieldDefs.Clear;

    if TJSONObject.ParseJSONValue(FJSON) is TJSONObject then begin
      JObjectData := TJSONObject.ParseJSONValue(FJSON) as TJSONObject;
    end else if TJSONObject.ParseJSONValue(FJSON) is TJSONArray then begin
      isArray := True;
      JArrayJSON := TJSONObject.ParseJSONValue(FJSON) as TJSONArray;
      JObjectData := TJSONObject(JArrayJSON.Get(0));
    end else begin
      Result := False;
      Self.FillError('Ini Bukan Format JSON', FJSON);
      Exit;
    end;

    for i := 0 to JObjectData.Size - 1 do
      Self.FieldDefs.Add(
        StringReplace(JObjectData.Get(i).JsonString.ToString, '"', '', [rfReplaceAll, rfIgnoreCase]),
        ftString,
        100000,
        False
      );

    Self.CreateDataSet;
    Self.Active := True;
    Self.Open;

    try
      if isArray then begin
        for i := 0 to JArrayJSON.Size - 1 do begin
          JObjectData := TJSONObject(JArrayJSON.Get(i));

          Self.Append;
          for ii := 0 to JObjectData.Size - 1 do
            if TJSONObject.ParseJSONValue(JObjectData.GetValue(Self.FieldDefs[ii].Name).ToJSON) is TJSONObject then
            Self.Fields[ii].AsString := JObjectData.GetValue(Self.FieldDefs[ii].Name).ToJSON
          else if TJSONObject.ParseJSONValue(JObjectData.GetValue(Self.FieldDefs[ii].Name).ToJSON) is TJSONArray then
            Self.Fields[ii].AsString := JObjectData.GetValue(Self.FieldDefs[ii].Name).ToJSON
          else
            Self.Fields[ii].AsString := JObjectData.Values[Self.FieldDefs[ii].Name].Value;
          Self.Post;
        end;
      end else begin

        Self.Append;
        for ii := 0 to JObjectData.Size - 1 do
          if TJSONObject.ParseJSONValue(JObjectData.GetValue(Self.FieldDefs[ii].Name).ToJSON) is TJSONObject then
            Self.Fields[ii].AsString := JObjectData.GetValue(Self.FieldDefs[ii].Name).ToJSON
          else if TJSONObject.ParseJSONValue(JObjectData.GetValue(Self.FieldDefs[ii].Name).ToJSON) is TJSONArray then
            Self.Fields[ii].AsString := JObjectData.GetValue(Self.FieldDefs[ii].Name).ToJSON
          else
            Self.Fields[ii].AsString := JObjectData.Values[Self.FieldDefs[ii].Name].Value;
        Self.Post;
      end;

      Result := True;
    except
      Result := False;
      Self.FillError('Gagal Parsing Data', FJSON);
    end;
  finally
    Self.First;
    if isArray then
      JArrayJSON.DisposeOf;
  end;
end;

function TFDMemTableHelper.FillDataFromURL(FURL: String) : Boolean;
var
  FNetHTTP : TNetHTTPClient;
  FNetRespon : IHTTPResponse;
begin
  FNetHTTP := TNetHTTPClient.Create(nil);
  try
    try
      FNetRespon := FNetHTTP.Get(FURL);
      Result := Self.FillDataFromString(FNetRespon.ContentAsString());
    except
      on E : Exception do begin
        FillError('Gagal Terkoneksi Dengan Server', E.Message);
        Result := False;
      end;
    end;
  finally
    FNetHTTP.DisposeOf;
  end;
end;

function TFDMemTableHelper.FillDataFromURL(FURL: String;
  FMultiPart : TMultipartFormData) : Boolean;
var
  FNetHTTP : TNetHTTPClient;
  FNetRespon : IHTTPResponse;
begin
  FNetHTTP := TNetHTTPClient.Create(nil);
  try
    try
      FNetRespon := FNetHTTP.Post(FURL, FMultiPart);
      Result := Self.FillDataFromString(FNetRespon.ContentAsString());
    except
      on E : Exception do begin
        FillError('Gagal Terkoneksi Dengan Server', E.Message);
        Result := False;
      end;
    end;
  finally
    FNetHTTP.DisposeOf;
  end;
end;

function TFDMemTableHelper.FillError(FMessage, FError: String): String;
begin
  Self.Active := False;
  Self.Close;
  Self.FieldDefs.Clear;

  Self.FieldDefs.Add('message', ftString, 200, False);
  Self.FieldDefs.Add('error', ftString, 200, False);

  Self.CreateDataSet;
  Self.Active := True;
  Self.Open;

  Self.Append;
  Self.Fields[0].AsString := FMessage;
  Self.Fields[1].AsString := FError;
  Self.Post;
end;

end.
