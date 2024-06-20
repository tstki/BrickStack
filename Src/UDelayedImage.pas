unit UDelayedImage;

interface

uses
  System.Classes, Vcl.ExtCtrls, UImageCache;

// Image Load state
const
  LSNone = 0;
  LSLoading = 1;
  LSDone = 2;
  LSRetrying = 3;
  LSFailed = 4;

type
  TDelayedImage = class(TImage)
    protected
      procedure Paint; override;
    private
      FLoadState: Integer;
      FUrl: String;
      FImageCache: TImageCache;
    public
      //class function
      property LoadState: Integer read FLoadState write FLoadState;
      property Url: String read FUrl write FUrl;
      property ImageCache: TImageCache read FImageCache write FImageCache;
  end;

implementation

procedure TDelayedImage.Paint;
begin
  // We only want to start the thread once - we can impl LSRetrying later.
  if (FLoadState = LSNone) and (FUrl <> '') then begin
    FLoadState := LSLoading;

    // Queue loading the image async
    TThread.CreateAnonymousThread(
      procedure
      begin
        try
          var Picture := FImageCache.GetImage(FUrl);
          if Picture <> nil then begin
            Self.Picture := Picture;
            FLoadstate := LSDone;

            TThread.Synchronize(nil,
            procedure
            begin
              // Update the UI in the main thread
              Self.Invalidate;
            end);
          end;
        except
          // Handle exceptions here / delays.
          //Sleep(2000);

          TThread.Synchronize(nil,
          procedure
          begin
            FLoadState := LSFailed;
          end);
        end;
      end).Start;
  end;

  inherited;
end;

end.
