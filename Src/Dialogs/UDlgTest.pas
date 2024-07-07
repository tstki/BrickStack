unit UDlgTest;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  IdHttp, UConfig, Vcl.ExtCtrls;

type
  TDlgTest = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    Button2: TButton;
    Image1: TImage;
    Button3: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
    FIdHttp: TIdHttp;
    FConfig: TConfig;
  public
    { Public declarations }
    property IdHttp: TIdHttp read FIdHttp write FIdHttp;
    property Config: TConfig read FConfig write FConfig;
  end;

implementation

{$R *.dfm}

uses
  IdSSL, IdSSLOpenSSL, IdSSLOpenSSLHeaders,
  UFrmMain,
  FireDAC.Comp.Client,
  Data.DB,
  USQLiteConnection,
  System.Net.HttpClient, System.IOUtils,
  //Vcl.Graphics, // TWICImage
JPEG,
  StrUtils;

procedure TDlgTest.Button1Click(Sender: TObject);
begin
  var BaseUrl := FConfig.RebrickableBaseUrl;
  var EndPoint := '/api/v3/lego/colors/';
  var ApiKey := FConfig.RebrickableAPIKey;

  FIdHttp.Request.CustomHeaders.Clear;
  FIdHttp.Request.CustomHeaders.AddValue('Authorization', 'key ' + ApiKey);

  try
    var HttpResult := FIdHttp.Get(BaseUrl + EndPoint);
    Memo1.Text := HttpResult;
  except on e:exception do
    begin
      // show error if any
      var idErr := IdSSLOpenSSLHeaders.WhichFailedToLoad();
      ShowMessage(IfThen(idErr <> '', idErr, e.Message));
    end
  end;
end;

procedure TDlgTest.Button2Click(Sender: TObject);
begin
  var SqlConnection := FrmMain.AcquireConnection;
  var FDQuery := TFDQuery.Create(nil);
  try
    // Set up the query
    FDQuery.Connection := SqlConnection;
    FDQuery.SQL.Text := 'SELECT * FROM MySetLists';

    FDQuery.Open;

    while not FDQuery.Eof do begin
      Memo1.Lines.Add(FDQuery.FieldByName('Name').AsString);
      Memo1.Lines.Add(FDQuery.FieldByName('Description').AsString);
      FDQuery.Next; // Move to the next row
    end;
  finally
    FDQuery.Free;
    FrmMain.ReleaseConnection(SqlConnection);
  end;

  // Seems the "fieldname as" does not work. See how to get the fieldnames or FieldDefs example:
  //  for var I := 0 to FDQuery.FieldCount - 1 do
  //    ShowMessage(FDQuery.Fields[I].FieldName);
end;

procedure TDlgTest.Button3Click(Sender: TObject);

  procedure DownloadImage(const URL, FileName: string);
  var
    HTTPClient: THTTPClient;
    Response: IHTTPResponse;
    FileStream: TFileStream;
  begin
    HTTPClient := THTTPClient.Create;
    try
      Response := HTTPClient.Get(URL);
      if Response.StatusCode = 200 then begin
        FileStream := TFileStream.Create(FileName, fmCreate);
        try
          //FileStream.CopyFrom(Response.ContentStream, 0);
          //Response.ContentStream.Position := 0;
//          Image1.Picture.LoadFromStream(FileStream);
            var JPEGImage := TJPEGImage.Create;
            try
              //JPEGImage.LoadFromFile('d:\temp\image2.jpg');
              JPEGImage.LoadFromStream(Response.ContentStream);
              Image1.Picture.Assign(JPEGImage);
            finally
              JPEGImage.Free;
            end;

        finally
          FileStream.Free;
        end;
      end else
        raise Exception.Create('Failed to download image: ' + Response.StatusText);
    finally
      HTTPClient.Free;
    end;
  end;

  procedure loadimage();
  var
    //Picture: TPicture;
    JpegImage: TJPEGImage;
  begin
    JPEGImage := TJPEGImage.Create;
    try
      JPEGImage.LoadFromFile('d:\temp\image2.jpg');
      //JPEGImage.LoadFromStream();
      Image1.Picture.Assign(JPEGImage);
    finally
      JPEGImage.Free;
    end;
  end;

begin
  var Url := 'https://cdn.rebrickable.com/media/sets/42111-1.jpg';
  DownloadImage(url, 'd:\temp\image2.jpg');
//  loadimage();
end;

end.
