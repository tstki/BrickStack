unit UBSTotp;

interface

uses
  System.SysUtils;

function GenerateTotpSecret: string;
function ProtectTotpSecret(const ASecret: string): string;
function UnprotectTotpSecret(const AProtectedSecret: string): string;
function TotpProvisioningUri(const AUserName, ASecret: string): string;
function TryVerifyTotpCode(const ASecret, ACode: string; AUnixTime: Int64; out AMatchedCounter: Int64): Boolean;
function GenerateRecoveryCode: string;
function RecoveryCodeHash(const ACode: string): string;

implementation

uses
  Winapi.Windows,
  System.Hash,
  System.RegularExpressions;

const
  cTotpSecretBytes = 20;
  cTotpPeriodSeconds = 30;
  cMaximumClockSkewSteps = 1;
  cCryptProtectUIForbidden = $00000001;
  cBCryptUseSystemPreferredRng = $00000002;

type
  TDataBlob = record
    Size: DWORD;
    Data: PByte;
  end;
  PDataBlob = ^TDataBlob;

  TBcryptGenRandom = function(Algorithm: Pointer; Buffer: PByte;
    BufferLength, Flags: ULONG): LongInt; stdcall;

function CryptProtectData(pDataIn: PDataBlob; szDataDescr: PWideChar;
  pOptionalEntropy: PDataBlob; pvReserved: Pointer; pPromptStruct: Pointer;
  dwFlags: DWORD; pDataOut: PDataBlob): BOOL; stdcall;
  external 'crypt32.dll' name 'CryptProtectData';
function CryptUnprotectData(pDataIn: PDataBlob; ppszDataDescr: Pointer;
  pOptionalEntropy: PDataBlob; pvReserved: Pointer; pPromptStruct: Pointer;
  dwFlags: DWORD; pDataOut: PDataBlob): BOOL; stdcall;
  external 'crypt32.dll' name 'CryptUnprotectData';

function SecureRandomBytes(ALength: Integer): TBytes;
begin
  var LibraryHandle := LoadLibrary('bcrypt.dll');
  if LibraryHandle = 0 then
    RaiseLastOSError;
  try
    var GenerateRandom: TBcryptGenRandom := TBcryptGenRandom(GetProcAddress(LibraryHandle, 'BCryptGenRandom'));
    if not Assigned(GenerateRandom) then
      raise Exception.Create('Windows secure random generator is unavailable.');
    SetLength(Result, ALength);
    var Status: LongInt := GenerateRandom(nil, @Result[0], Length(Result), cBCryptUseSystemPreferredRng);
    if Status < 0 then
      raise Exception.CreateFmt(
        'Windows secure random generation failed (0x%.8x).',
        [Cardinal(Status)]);
  finally
    FreeLibrary(LibraryHandle);
  end;
end;

function BytesToHex(const ABytes: TBytes): string;
begin
  Result := '';
  for var I := 0 to High(ABytes) do
    Result := Result + IntToHex(ABytes[I], 2);
end;

function HexToBytes(const AHex: string): TBytes;
begin
  if (AHex = '') or Odd(Length(AHex)) or
    not TRegEx.IsMatch(AHex, '^[0-9A-Fa-f]+$') then
    raise EArgumentException.Create('The protected TOTP secret is invalid.');
  SetLength(Result, Length(AHex) div 2);
  var Value: Integer;
  for var I := 0 to High(Result) do begin
    if not TryStrToInt('$' + Copy(AHex, I * 2 + 1, 2), Value) then
      raise EArgumentException.Create('The protected TOTP secret is invalid.');
    Result[I] := Byte(Value);
  end;
end;

function Base32Encode(const ABytes: TBytes): string;
const
  cAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
begin
  Result := '';
  var Buffer: Cardinal := 0;
  var BitsInBuffer := 0;
  for var I := 0 to High(ABytes) do begin
    Buffer := (Buffer shl 8) or ABytes[I];
    Inc(BitsInBuffer, 8);
    while BitsInBuffer >= 5 do
    begin
      Dec(BitsInBuffer, 5);
      Result := Result + cAlphabet[((Buffer shr BitsInBuffer) and $1F) + 1];
    end;
  end;
  if BitsInBuffer > 0 then
    Result := Result + cAlphabet[((Buffer shl (5 - BitsInBuffer)) and $1F) + 1];
end;

function Base32Decode(const AValue: string): TBytes;
const
  cAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
begin
  Result := nil;
  var Buffer: Cardinal := 0;
  var BitsInBuffer := 0;
  for var I := 1 to Length(AValue) do begin
    var Digit := Pos(UpCase(AValue[I]), cAlphabet) - 1;
    if Digit < 0 then
      raise EArgumentException.Create('The TOTP secret is invalid.');
    Buffer := (Buffer shl 5) or Cardinal(Digit);
    Inc(BitsInBuffer, 5);
    if BitsInBuffer >= 8 then begin
      Dec(BitsInBuffer, 8);
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := Byte((Buffer shr BitsInBuffer) and $FF);
    end;
  end;
end;

function GenerateTotpSecret: string;
begin
  Result := Base32Encode(SecureRandomBytes(cTotpSecretBytes));
end;

function ProtectTotpSecret(const ASecret: string): string;
begin
  var PlainBytes := TEncoding.UTF8.GetBytes(ASecret);
  var InputBlob: TDataBlob;
  InputBlob.Size := Length(PlainBytes);
  InputBlob.Data := @PlainBytes[0];
  var OutputBlob: TDataBlob;
  OutputBlob.Size := 0;
  OutputBlob.Data := nil;
  var Description := 'BrickStack TOTP secret';
  if not CryptProtectData(@InputBlob, PWideChar(Description), nil, nil, nil,
    cCryptProtectUIForbidden, @OutputBlob) then
    RaiseLastOSError;
  try
    var ProtectedBytes: TBytes;
    SetLength(ProtectedBytes, OutputBlob.Size);
    Move(OutputBlob.Data^, ProtectedBytes[0], OutputBlob.Size);
    Result := BytesToHex(ProtectedBytes);
  finally
    LocalFree(HLOCAL(OutputBlob.Data));
  end;
end;

function UnprotectTotpSecret(const AProtectedSecret: string): string;
begin
  var ProtectedBytes := HexToBytes(AProtectedSecret);
  var InputBlob: TDataBlob;
  InputBlob.Size := Length(ProtectedBytes);
  InputBlob.Data := @ProtectedBytes[0];
  var OutputBlob: TDataBlob;
  OutputBlob.Size := 0;
  OutputBlob.Data := nil;
  if not CryptUnprotectData(@InputBlob, nil, nil, nil, nil,
    cCryptProtectUIForbidden, @OutputBlob) then
    RaiseLastOSError;
  try
    var PlainBytes: TBytes;
    SetLength(PlainBytes, OutputBlob.Size);
    Move(OutputBlob.Data^, PlainBytes[0], OutputBlob.Size);
    Result := TEncoding.UTF8.GetString(PlainBytes);
  finally
    LocalFree(HLOCAL(OutputBlob.Data));
  end;
end;

function TotpProvisioningUri(const AUserName, ASecret: string): string;
begin
  Result := 'otpauth://totp/BrickStack%3A' + AUserName +
    '?secret=' + ASecret + '&issuer=BrickStack&algorithm=SHA1&digits=6&period=30';
end;

function TotpValue(const ASecret: string; ACounter: Int64): string;
begin
  var Key := Base32Decode(ASecret);
  var Data: TBytes;
  SetLength(Data, 8);
  for var I := 0 to 7 do
    Data[7 - I] := Byte((UInt64(ACounter) shr (I * 8)) and $FF);
  var Digest := THashSHA1.GetHMACAsBytes(Data, Key);
  var Offset := Digest[High(Digest)] and $0F;
  var BinaryCode := (Cardinal(Digest[Offset]) and $7F) shl 24 or
    (Cardinal(Digest[Offset + 1]) shl 16) or
    (Cardinal(Digest[Offset + 2]) shl 8) or
    Cardinal(Digest[Offset + 3]);
  Result := IntToStr(BinaryCode mod 1000000);
  while Length(Result) < 6 do
    Result := '0' + Result;
end;

function ConstantTimeCodeEquals(const AExpected, AActual: string): Boolean;
begin
  if Length(AExpected) <> Length(AActual) then
    Exit(False);
  var Difference: Byte := 0;
  for var I := 1 to Length(AExpected) do
    Difference := Difference or
      (Byte(Ord(AExpected[I])) xor Byte(Ord(AActual[I])));
  Result := Difference = 0;
end;

function TryVerifyTotpCode(const ASecret, ACode: string; AUnixTime: Int64; out AMatchedCounter: Int64): Boolean;
begin
  AMatchedCounter := -1;
  Result := False;
  if not TRegEx.IsMatch(ACode, '^[0-9]{6}$') or (AUnixTime < 0) then
    Exit;
  var CurrentCounter := AUnixTime div cTotpPeriodSeconds;
  for var Offset := -cMaximumClockSkewSteps to cMaximumClockSkewSteps do begin
    var CandidateCounter := CurrentCounter + Offset;
    if (CandidateCounter >= 0) and
      ConstantTimeCodeEquals(TotpValue(ASecret, CandidateCounter), ACode) then
    begin
      AMatchedCounter := CandidateCounter;
      Exit(True);
    end;
  end;
end;

function GenerateRecoveryCode: string;
begin
  Result := BytesToHex(SecureRandomBytes(16));
end;

function RecoveryCodeHash(const ACode: string): string;
begin
  Result := THashSHA2.GetHashString(UpperCase(ACode.Trim));
end;

end.
