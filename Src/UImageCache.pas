unit UImageCache;

interface

uses
  System.Classes, Generics.Collections, Graphics,
  System.SyncObjs,
  UConfig;

const
  // Image dimensions
  cidMAX96 = 0;
  cidMAX128 = 1;
  cidMAX256 = 2;
  cidMAX512 = 3;

type
  TImageCache = class(TObject)
  private
    { Private declarations }
    FConfig: TConfig;
    FImageCache: TDictionary<String, TPicture>;
    function FGetLocalFilePathByUrl(const Url: String): String;
    function FGetFromCache(const Url: String; var Value: TPicture): Boolean;
    function FGetFromDisk(const Url: String; var Value: TPicture): Boolean;
    function FGetFromUrl(const Url: String; var Value: TPicture): Boolean;
  public
    { Public declarations }
    constructor Create;
    destructor Destroy; override;
    procedure AddImage(const Url: string; Picture: TPicture);
    function GetImage(const Url: string; const ImageType: Integer): TPicture;
    procedure SaveImage(const Url: String; Picture: TPicture);
    property Config: TConfig read FConfig write FConfig;
  end;

  //Image url examples for sets and minifigs are easy:
  // https://cdn.rebrickable.com/media/sets/1089-1.jpg       // Easy and consistent with set_num
  // https://cdn.rebrickable.com/media/sets/fig-000010.jpg   // Consistent with the fig_num

  //And then chaos with zero consistency: (So just save the whole thing)
  // https://cdn.rebrickable.com/media/parts/elements/4211065.jpg
  // https://cdn.rebrickable.com/media/parts/ldraw/15/3069bps4.png
  // https://cdn.rebrickable.com/media/parts/ldraw/4/4070.png

  //Smaller scale images:
  //  https://cdn.rebrickable.com/media/sets/0011-2.jpg // Take from DB
  //    Insert "thumbs"
  //    Add size suffix
  //  https://cdn.rebrickable.com/media/thumbs/parts/elements/6020193.jpg/50x150p.jpg // works

  //Parts can be limited to 128x128 : for grid
  //Sets can be limited to 256x256 : for grid
  //Individual images can be limited to 1000x1000 or less.

//Todo
  //Make this smarter
  //Keep up to X images in memory. Currently no limit - observe how bad this gets first.
  //Fix WImage issues.
  //improve error handling
  //convert to bmp for faster drawing
var
  CriticalSection: TCriticalSection;

implementation

uses
  System.SysUtils, System.Net.HttpClient, System.IOUtils, System.Net.URLClient,
  Vcl.Imaging.jpeg;

constructor TImageCache.Create;
begin
  inherited;
  FImageCache := TDictionary<string, TPicture>.Create;
end;

destructor TImageCache.Destroy;
begin
  FImageCache.Free;
  inherited;
end;

function TImageCache.FGetLocalFilePathByUrl(const Url: String): String;
begin
  //Remove the domain from the URl. Example input:
  // https://cdn.rebrickable.com/media/parts/elements/4211065.jpg

  //Example output:
  // C:\Programs\BrickStack\media\parts\elements\4211065.jpg

  try
    var URI := TURI.Create(URL);

    Result := FConfig.LocalImageCachePath;
    if (Length(Result) > 0) and (Result[High(Result)] = TPath.DirectorySeparatorChar) then
      SetLength(Result, Length(Result) - 1);

    Result := Result + StringReplace(URI.Path, '/', '\', [rfReplaceAll]);
  except
    //on E: Exception do
      //Writeln('Error parsing URL: ' + E.Message);
  end;
end;

function TImageCache.FGetFromCache(const Url: String; var Value: TPicture): Boolean;
begin
  Result := FImageCache.TryGetValue(Url, Value);
end;

function TImageCache.FGetFromDisk(const Url: String; var Value: TPicture): Boolean;
begin
  if Config.LocalImageCachePath <> '' then begin
    var FilePath := FGetLocalFilePathByUrl(Url);
    if FileExists(FilePath) then begin
      Value := TPicture.Create;
      try
        Value.LoadFromFile(FilePath);
        // If jpeg error 53 is thrown, this means either a corrupted file - or insufficient memory.
        // you can try to catch EJPEG error and check for #53 within the message.
        Result := True;
      except
        begin
          // Get error, see if the image is a PNG instead of a jpg, in which case it needs to be loaded differently.
          { Will work, but causes access violation on application close - debug later
          var WImage := TWICImage.Create;
          WImage.LoadFromFile(FilePath);
          Value.Assign(WImage);
          WImage.Free;
          //}
          //Value.Free;
          Result := False;
        end;
      end;
    end else
      Result := False;
  end else
    Result := False;
end;

function TImageCache.FGetFromUrl(const Url: String; var Value: TPicture): Boolean;
const
  DefaultNoImage = 'https://rebrickable.com/media/thumbs/nil.png/250x250p.png';
  // Missing minifig default: https://rebrickable.com/static/img/nil_mf.jpg
  // Missing part default:    https://rebrickable.com/media/thumbs/nil.png/250x250p.png
begin
  var HTTPClient := THTTPClient.Create;
  try
    var Response := HTTPClient.Get(URL);
    if Response.StatusCode = 200 then begin
      Value := TPicture.Create;
      Value.LoadFromStream(Response.ContentStream);
      Result := True;
    end else begin
      // Prevent possible infinite loop.
      if SameText('Url', DefaultNoImage) then
        raise Exception.Create('Failed to download image: ' + Response.StatusText)
      else
        Result := FGetFromUrl(DefaultNoImage, Value);
    end;
  finally
    HTTPClient.Free;
  end;
end;

procedure TImageCache.AddImage(const Url: string; Picture: TPicture);
begin
  FImageCache.AddOrSetValue(Url, Picture);
end;

procedure TImageCache.SaveImage(const Url: String; Picture: TPicture);
begin
  if FConfig.LocalImageCachePath <> '' then begin
    var FullFilepath := FGetLocalFilePathByUrl(Url);
    var FilePath := ExtractFilePath(FullFilePath);
    ForceDirectories(Filepath);
    Picture.SaveToFile(FullFilepath);
  end;
end;

function TImageCache.GetImage(const Url: string; const ImageType: Integer): TPicture;
begin
  // todo: add width/height param.
  // parse URL to get thumbnail instead of full size image.
  {
  //Smaller scale images:
  //  https://cdn.rebrickable.com/media/sets/0011-2.jpg // Take from DB
  //    Insert "thumbs"
  //    Add size suffix
  //  https://cdn.rebrickable.com/media/thumbs/parts/elements/6020193.jpg/50x150p.jpg // works

  //Parts can be limited to 128x128 : for grid
  //Sets can be limited to 256x256 : for grid
  //Individual images can be limited to 512x512 or less.
  }

  var SizeSuffix := '';

  case ImageType of
    cidMAX96:
      SizeSuffix := '96x96p.jpg';
    cidMAX128:
      SizeSuffix := '128x128p.jpg';
    cidMAX256:
      SizeSuffix := '256x256p.jpg';
    cidMAX512:
      SizeSuffix := '512x512p.jpg';
  end;

  var NewUrl := StringReplace('Url', 'https://cdn.rebrickable.com/media/', 'https://cdn.rebrickable.com/media/thumbs/', []) + SizeSuffix;

  CriticalSection.Enter;
  try
    try
      if FGetFromCache(NewUrl, Result) then
        Exit
      else if FGetFromDisk(NewUrl, Result) then begin
        AddImage(NewUrl, Result);
        Exit;
      end else if FGetFromUrl(NewUrl, Result) then begin // May raise if image is not found.
        SaveImage(NewUrl, Result);
        AddImage(NewUrl, Result);
        Exit;
      end else
        Result := nil;
    except
      // Log error
      Result := nil;
    end;
  finally
    CriticalSection.Leave
  end;
end;


initialization
  // Initialize global variables here
  CriticalSection := TCriticalSection.Create;

finalization
  // Perform cleanup when the unit is finalized
  CriticalSection.Free;

end.
