unit uUtils;

interface

uses
  Windows, Messages, SysUtils, System.JSON, apiCore, apiObjects, uTypes;

type
  TAIMPUtils = class
  public
    class function GetAIMPString(AIMPStr: IAIMPString): string;
    class function MakeString(Core: IAIMPCore; const S: string): IAIMPString;
    class procedure SendJSON(JSON: TJSONObject);
    class function IsWindowLocked(Hwnd: THandle): Boolean;
  end;

implementation

const
  WS_EX_TRANSPARENT = $20;

class function TAIMPUtils.GetAIMPString(AIMPStr: IAIMPString): string;
begin
  if AIMPStr = nil then Exit('');
  SetLength(Result, AIMPStr.GetLength);
  if Length(Result) > 0 then
    Move(AIMPStr.GetData^, Result[1], Length(Result) * SizeOf(Char));
end;

class function TAIMPUtils.MakeString(Core: IAIMPCore; const S: string): IAIMPString;
begin
  if Core.CreateObject(IID_IAIMPString, Result) = S_OK then
    Result.SetData(PChar(S), Length(S));
end;

class procedure TAIMPUtils.SendJSON(JSON: TJSONObject);
var
  JsonStr: string;
  Utf8Str: UTF8String;
  CopyData: TCopyDataStruct;
  Hwnd: THandle;
begin
  Hwnd := FindWindow(nil, PChar(TARGET_WINDOW_TITLE));
  if Hwnd = 0 then Exit;

  JsonStr := JSON.ToString;
  Utf8Str := UTF8String(JsonStr);

  CopyData.dwData := COPYDATA_ID_AILRC;
  CopyData.cbData := Length(Utf8Str) + 1;
  CopyData.lpData := PAnsiChar(Utf8Str);

  SendMessageTimeout(Hwnd, WM_COPYDATA, 0, LPARAM(@CopyData),
    SMTO_ABORTIFHUNG or SMTO_NORMAL, 10, nil);
end;

class function TAIMPUtils.IsWindowLocked(Hwnd: THandle): Boolean;
var
  Style: LongInt;
begin
  Result := False;
  if Hwnd = 0 then Exit;
  Style := GetWindowLong(Hwnd, GWL_EXSTYLE);
  Result := (Style and WS_EX_TRANSPARENT) <> 0;
end;

end.
