unit uPlugin;

interface

uses
  Windows, SysUtils, Classes, ShellAPI, Messages, System.JSON,
  apiPlugin, apiCore, apiMessages, apiPlayer, apiObjects, apiTypes,
  apiActions, apiMenu, apiFileManager;

const
  TARGET_WINDOW_TITLE = 'AILrc';
  COPYDATA_ID_AILRC = 19941012;

  ACTION_ID_TOGGLE = 'aimp.action.ailrc.toggle';
  MENU_ID_TOGGLE   = 'aimp.menu.ailrc.toggle';

type
  TMenuStateUpdater = class(TInterfacedObject, IAIMPActionEvent)
  private
    FMenuItem: IAIMPMenuItem;
  public
    constructor Create(AMenuItem: IAIMPMenuItem);
    procedure OnExecute(Data: IUnknown); stdcall;
  end;

  TAIMPLifecyclePlugin = class(TInterfacedObject, IAIMPPlugin, IAIMPMessageHook, IAIMPActionEvent)
  private
    FCore: IAIMPCore;
    FMessageDispatcher: IAIMPServiceMessageDispatcher;
    FPlayer: IAIMPServicePlayer;
    FMenuManager: IAIMPServiceMenuManager;

    FActionToggle: IAIMPAction;
    FMenuItemToggle: IAIMPMenuItem;
    FMenuUpdater: IAIMPActionEvent;

    function MakeString(const S: string): IAIMPString;
    function GetAIMPString(AIMPStr: IAIMPString): string;

    procedure SendJSON(JSON: TJSONObject);
    procedure SendTrackInfo;
    procedure SendState;
    procedure SendPosition;
    procedure LaunchApp;
    procedure CloseApp;
    function IsAppRunning: Boolean;

    procedure RegisterUI;
  public
    function InfoGet(Index: Integer): PWideChar; stdcall;
    function InfoGetCategories: Cardinal; stdcall;
    function Initialize(Core: IAIMPCore): HRESULT; stdcall;
    procedure Finalize; stdcall;
    procedure SystemNotification(NotifyID: Integer; Data: IUnknown); stdcall;

    procedure CoreMessage(Message: LongWord; Param1: Integer; Param2: Pointer; var Result: HRESULT); stdcall;

    procedure OnExecute(Data: IUnknown); stdcall;
  end;

implementation

{ TMenuStateUpdater }

constructor TMenuStateUpdater.Create(AMenuItem: IAIMPMenuItem);
begin
  inherited Create;
  FMenuItem := AMenuItem;
end;

procedure TMenuStateUpdater.OnExecute(Data: IUnknown);
var
  Hwnd: THandle;
begin
  if FMenuItem = nil then Exit;
  Hwnd := FindWindow(nil, PChar(TARGET_WINDOW_TITLE));
  FMenuItem.SetValueAsInt32(AIMP_MENUITEM_PROPID_CHECKED, Integer(Hwnd <> 0));
end;

{ TAIMPLifecyclePlugin }

function TAIMPLifecyclePlugin.InfoGetCategories: Cardinal;
begin
  Result := AIMP_PLUGIN_CATEGORY_ADDONS;
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

  if FCore.QueryInterface(IID_IAIMPServiceMessageDispatcher, FMessageDispatcher) <> S_OK then Exit(E_FAIL);
  if FCore.QueryInterface(IID_IAIMPServicePlayer, FPlayer) <> S_OK then Exit(E_FAIL);
  if FCore.QueryInterface(IID_IAIMPServiceMenuManager, FMenuManager) <> S_OK then Exit(E_FAIL);

  if FMessageDispatcher.Hook(Self) <> S_OK then Exit(E_FAIL);

  RegisterUI;
  LaunchApp;

  Result := S_OK;
end;

function TAIMPLifecyclePlugin.MakeString(const S: string): IAIMPString;
begin
  if FCore.CreateObject(IID_IAIMPString, Result) = S_OK then
  begin
    Result.SetData(PChar(S), Length(S));
  end;
end;

procedure TAIMPLifecyclePlugin.RegisterUI;
var
  ActionName: IAIMPString;
  ActionID: IAIMPString;
  MenuID: IAIMPString;
  MenuCaption: IAIMPString;
  ParentMenuItem: IAIMPMenuItem;
begin
  FCore.CreateObject(IID_IAIMPAction, FActionToggle);

  ActionName := MakeString('Desktop Lyrics');
  ActionID   := MakeString(ACTION_ID_TOGGLE);

  FActionToggle.SetValueAsObject(AIMP_ACTION_PROPID_ID, ActionID);
  FActionToggle.SetValueAsObject(AIMP_ACTION_PROPID_NAME, ActionName);
  FActionToggle.SetValueAsObject(AIMP_ACTION_PROPID_GROUPNAME, ActionName);
  FActionToggle.SetValueAsObject(AIMP_ACTION_PROPID_EVENT, Self);
  FActionToggle.SetValueAsInt32(AIMP_ACTION_PROPID_ENABLED, 1);

  FCore.RegisterExtension(IID_IAIMPServiceActionManager, FActionToggle);

  FCore.CreateObject(IID_IAIMPMenuItem, FMenuItemToggle);
  MenuID := MakeString(MENU_ID_TOGGLE);
  MenuCaption := MakeString('Desktop Lyrics');

  FMenuItemToggle.SetValueAsObject(AIMP_MENUITEM_PROPID_ID, MenuID);
  FMenuItemToggle.SetValueAsObject(AIMP_MENUITEM_PROPID_ACTION, FActionToggle);
  FMenuItemToggle.SetValueAsObject(AIMP_MENUITEM_PROPID_CAPTION, MenuCaption);

  if FMenuManager.GetBuiltIn(AIMP_MENUID_PLAYER_MAIN_FUNCTIONS, ParentMenuItem) = S_OK then
  begin
    FMenuItemToggle.SetValueAsObject(AIMP_MENUITEM_PROPID_PARENT, ParentMenuItem);
  end;

  FMenuItemToggle.SetValueAsInt32(AIMP_MENUITEM_PROPID_STYLE, AIMP_MENUITEM_STYLE_CHECKBOX);

  FMenuUpdater := TMenuStateUpdater.Create(FMenuItemToggle);
  FMenuItemToggle.SetValueAsObject(AIMP_MENUITEM_PROPID_EVENT_ONSHOW, FMenuUpdater);

  FCore.RegisterExtension(IID_IAIMPServiceMenuManager, FMenuItemToggle);
end;

procedure TAIMPLifecyclePlugin.Finalize;
begin
  if Assigned(FMessageDispatcher) then
    FMessageDispatcher.Unhook(Self);

  CloseApp;

  FActionToggle := nil;
  FMenuItemToggle := nil;
  FMenuUpdater := nil;
  FPlayer := nil;
  FMessageDispatcher := nil;
  FMenuManager := nil;
  FCore := nil;
end;

procedure TAIMPLifecyclePlugin.OnExecute(Data: IUnknown);
begin
  if IsAppRunning then
    CloseApp
  else
    LaunchApp;

  if FMenuItemToggle <> nil then
    FMenuItemToggle.SetValueAsInt32(AIMP_MENUITEM_PROPID_CHECKED, Integer(IsAppRunning));
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
      SendTrackInfo;

    AIMP_MSG_EVENT_PLAYER_STATE:
      SendState;

    AIMP_MSG_EVENT_PLAYER_UPDATE_POSITION_HR:
      if (FPlayer <> nil) and (FPlayer.GetState = AIMP_PLAYER_STATE_PLAYING) then
        SendPosition;
  end;
end;

function TAIMPLifecyclePlugin.IsAppRunning: Boolean;
begin
  Result := FindWindow(nil, PChar(TARGET_WINDOW_TITLE)) <> 0;
end;

procedure TAIMPLifecyclePlugin.LaunchApp;
var
  AppExe: string;
begin
  AppExe := ExtractFilePath(ParamStr(0)) + 'AILrc.exe';
  if FileExists(AppExe) and (not IsAppRunning) then
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

procedure TAIMPLifecyclePlugin.SendTrackInfo;
var
  FileInfo: IAIMPFileInfo;
  PropList: IAIMPPropertyList;
  StrObj: IAIMPString;
  Duration: Double;
  JSON, Data: TJSONObject;
begin
  if FPlayer = nil then Exit;
  if FPlayer.GetInfo(FileInfo) <> S_OK then Exit;
  if FileInfo.QueryInterface(IID_IAIMPPropertyList, PropList) <> S_OK then Exit;

  JSON := TJSONObject.Create;
  Data := TJSONObject.Create;
  try
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
  except
    JSON.Free;
  end;
end;

procedure TAIMPLifecyclePlugin.SendState;
var
  State: Integer;
  JSON, Data: TJSONObject;
begin
  if FPlayer = nil then Exit;
  State := FPlayer.GetState;

  JSON := TJSONObject.Create;
  Data := TJSONObject.Create;
  try
    JSON.AddPair('type', 'state');
    Data.AddPair('state', TJSONNumber.Create(State));
    JSON.AddPair('data', Data);
    SendJSON(JSON);
  except
    JSON.Free;
  end;
end;

procedure TAIMPLifecyclePlugin.SendPosition;
var
  Seconds: Double;
  JSON, Data: TJSONObject;
begin
  if FPlayer = nil then Exit;
  if FPlayer.GetPosition(Seconds) <> S_OK then Exit;

  JSON := TJSONObject.Create;
  Data := TJSONObject.Create;
  try
    JSON.AddPair('type', 'position');
    Data.AddPair('position', TJSONNumber.Create(Seconds));
    JSON.AddPair('data', Data);
    SendJSON(JSON);
  except
    JSON.Free;
  end;
end;

procedure TAIMPLifecyclePlugin.SendJSON(JSON: TJSONObject);
var
  JsonStr: string;
  CopyData: TCopyDataStruct;
  Hwnd: THandle;
begin
  Hwnd := FindWindow(nil, PChar(TARGET_WINDOW_TITLE));
  if Hwnd = 0 then Exit;

  JsonStr := JSON.ToString;
  CopyData.dwData := COPYDATA_ID_AILRC;
  CopyData.cbData := (Length(JsonStr) + 1) * SizeOf(Char);
  CopyData.lpData := PChar(JsonStr);
  SendMessageTimeout(Hwnd, WM_COPYDATA, 0, LPARAM(@CopyData), SMTO_ABORTIFHUNG or SMTO_NORMAL, 10, nil);
end;

function TAIMPLifecyclePlugin.GetAIMPString(AIMPStr: IAIMPString): string;
begin
  Result := '';
  if AIMPStr = nil then Exit;
  Result := AIMPStr.GetData;
end;

end.
