unit uPlugin;

interface

uses
  Windows, SysUtils, Classes, ShellAPI, Messages, System.JSON,
  apiPlugin, apiCore, apiMessages, apiPlayer, apiFileManager, apiObjects, apiTypes;

const
  TARGET_WINDOW_TITLE = 'AILrc';
  COPYDATA_ID_AILRC = 19941012;

type
  TAIMPLifecyclePlugin = class(TInterfacedObject, IAIMPPlugin, IAIMPMessageHook)
  private
    FCore: IAIMPCore;
    FMessageDispatcher: IAIMPServiceMessageDispatcher;
    FPlayer: IAIMPServicePlayer;

    function GetAIMPString(AIMPStr: IAIMPString): string;
    procedure SendJSON(JSON: TJSONObject);
    procedure SendTrackInfo;
    procedure SendState;
    procedure SendPosition;
    procedure LaunchApp;
    procedure CloseApp;
  public
    function InfoGet(Index: Integer): PWideChar; stdcall;
    function InfoGetCategories: Cardinal; stdcall;
    function Initialize(Core: IAIMPCore): HRESULT; stdcall;
    procedure Finalize; stdcall;
    procedure SystemNotification(NotifyID: Integer; Data: IUnknown); stdcall;

    procedure CoreMessage(Message: LongWord; Param1: Integer; Param2: Pointer; var Result: HRESULT); stdcall;
  end;

implementation

function TAIMPLifecyclePlugin.InfoGetCategories: Cardinal;
begin
  Result := 2;
end;

function TAIMPLifecyclePlugin.InfoGet(Index: Integer): PWideChar;
begin
  case Index of
    AIMP_PLUGIN_INFO_NAME:              Result := 'AILrc plugin';
    AIMP_PLUGIN_INFO_AUTHOR:            Result := 'LeoViki';
    AIMP_PLUGIN_INFO_SHORT_DESCRIPTION: Result := 'Syncs metadata and lyrics position to AILrc';
  else
    Result := nil;
  end;
end;

function TAIMPLifecyclePlugin.Initialize(Core: IAIMPCore): HRESULT;
begin
  FCore := Core;

  if FCore.QueryInterface(IID_IAIMPServiceMessageDispatcher, FMessageDispatcher) <> S_OK then
    Exit(E_FAIL);

  if FCore.QueryInterface(IID_IAIMPServicePlayer, FPlayer) <> S_OK then
    Exit(E_FAIL);

  if FMessageDispatcher.Hook(Self) <> S_OK then
    Exit(E_FAIL);

  LaunchApp;
  Result := S_OK;
end;

procedure TAIMPLifecyclePlugin.Finalize;
begin
  if Assigned(FMessageDispatcher) then
    FMessageDispatcher.Unhook(Self);

  CloseApp;

  FPlayer := nil;
  FMessageDispatcher := nil;
  FCore := nil;
end;

procedure TAIMPLifecyclePlugin.SystemNotification(NotifyID: Integer; Data: IUnknown);
begin
end;

procedure TAIMPLifecyclePlugin.CoreMessage(Message: LongWord; Param1: Integer;
  Param2: Pointer; var Result: HRESULT);
begin
  case Message of
    AIMP_MSG_EVENT_STREAM_START,
    AIMP_MSG_EVENT_PLAYING_FILE_INFO:
      begin
        SendTrackInfo;
      end;

    AIMP_MSG_EVENT_PLAYER_STATE:
      begin
        SendState;
      end;

    AIMP_MSG_EVENT_PLAYER_UPDATE_POSITION_HR:
      begin
        if (FPlayer <> nil) and (FPlayer.GetState = AIMP_PLAYER_STATE_PLAYING) then
          SendPosition;
      end;
  end;
end;

procedure TAIMPLifecyclePlugin.SendTrackInfo;
var
  FileInfo: IAIMPFileInfo;
  PropList: IAIMPPropertyList;
  StrObj: IAIMPString;
  Duration: Double;
  JSON: TJSONObject;
  Data: TJSONObject;
begin
  if FPlayer = nil then Exit;

  if FPlayer.GetInfo(FileInfo) <> S_OK then Exit;
  if FileInfo.QueryInterface(IID_IAIMPPropertyList, PropList) <> S_OK then Exit;

  JSON := TJSONObject.Create;
  try
    Data := TJSONObject.Create;
    JSON.AddPair('type', 'track');

    if PropList.GetValueAsObject(AIMP_FILEINFO_PROPID_TITLE, IID_IAIMPString, StrObj) = S_OK then
      Data.AddPair('title', GetAIMPString(StrObj));

    if PropList.GetValueAsObject(AIMP_FILEINFO_PROPID_ARTIST, IID_IAIMPString, StrObj) = S_OK then
      Data.AddPair('artist', GetAIMPString(StrObj));

    if PropList.GetValueAsObject(AIMP_FILEINFO_PROPID_ALBUM, IID_IAIMPString, StrObj) = S_OK then
      Data.AddPair('album', GetAIMPString(StrObj));

    if PropList.GetValueAsObject(AIMP_FILEINFO_PROPID_FILENAME, IID_IAIMPString, StrObj) = S_OK then
      Data.AddPair('file_path', GetAIMPString(StrObj));

    if PropList.GetValueAsFloat(AIMP_FILEINFO_PROPID_DURATION, Duration) = S_OK then
      Data.AddPair('duration', TJSONNumber.Create(Duration));

    JSON.AddPair('data', Data);
    SendJSON(JSON);
  finally
    JSON.Free;
  end;
end;

procedure TAIMPLifecyclePlugin.SendState;
var
  State: Integer;
  JSON: TJSONObject;
  Data: TJSONObject;
begin
  if FPlayer = nil then Exit;
  State := FPlayer.GetState;

  JSON := TJSONObject.Create;
  try
    Data := TJSONObject.Create;
    JSON.AddPair('type', 'state');
    Data.AddPair('state', TJSONNumber.Create(State));
    JSON.AddPair('data', Data);

    SendJSON(JSON);
  finally
    JSON.Free;
  end;
end;

procedure TAIMPLifecyclePlugin.SendPosition;
var
  Seconds: Double;
  JSON: TJSONObject;
  Data: TJSONObject;
begin
  if FPlayer = nil then Exit;
  if FPlayer.GetPosition(Seconds) <> S_OK then Exit;

  JSON := TJSONObject.Create;
  try
    Data := TJSONObject.Create;
    JSON.AddPair('type', 'position');
    Data.AddPair('position', TJSONNumber.Create(Seconds));
    JSON.AddPair('data', Data);

    SendJSON(JSON);
  finally
    JSON.Free;
  end;
end;

procedure TAIMPLifecyclePlugin.SendJSON(JSON: TJSONObject);
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

function TAIMPLifecyclePlugin.GetAIMPString(AIMPStr: IAIMPString): string;
begin
  if AIMPStr = nil then Exit('');
  SetLength(Result, AIMPStr.GetLength);
  if Length(Result) > 0 then
    Move(AIMPStr.GetData^, Result[1], Length(Result) * SizeOf(Char));
end;

procedure TAIMPLifecyclePlugin.LaunchApp;
var
  AppExe: string;
begin
  AppExe := ExtractFilePath(ParamStr(0)) + 'AILrc.exe';
  if FileExists(AppExe) and (FindWindow(nil, PChar(TARGET_WINDOW_TITLE)) = 0) then
    ShellExecute(0, 'open', PChar(AppExe), nil, PChar(ExtractFilePath(AppExe)), SW_SHOWNORMAL);
end;

procedure TAIMPLifecyclePlugin.CloseApp;
var
  Hwnd: THandle;
begin
  Hwnd := FindWindow(nil, PChar(TARGET_WINDOW_TITLE));
  if Hwnd <> 0 then
    PostMessage(Hwnd, WM_CLOSE, 0, 0);
end;

end.
