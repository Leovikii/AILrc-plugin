unit uController;

interface

uses
  Windows, Messages, SysUtils, Classes, ShellAPI, System.JSON,
  apiCore, apiMenu, apiPlayer, apiFileManager, apiObjects, apiTypes, apiActions,
  uTypes, uUtils;

type
  TPluginController = class;

  TMenuStateUpdater = class(TInterfacedObject, IAIMPActionEvent)
  private
    FController: TPluginController;
  public
    constructor Create(Controller: TPluginController);
    procedure OnExecute(Data: IUnknown); stdcall;
  end;

  TPluginController = class
  private
    FCore: IAIMPCore;
    FPlayer: IAIMPServicePlayer;
    FMenuManager: IAIMPServiceMenuManager;
    FMenuUpdater: IAIMPActionEvent;

    FMenuToggle: IAIMPMenuItem;
    FMenuLock: IAIMPMenuItem;

    procedure UpdateMenuState;
    procedure SyncInitialData;
  public
    constructor Create(Core: IAIMPCore; Player: IAIMPServicePlayer);
    destructor Destroy; override;

    procedure InitMenus(Handler: IUnknown);
    procedure HandleMenuAction(MenuItem: IAIMPMenuItem);

    procedure LaunchApp;
    procedure CloseApp;
    procedure ToggleApp;

    procedure ToggleLock;

    procedure SendTrackInfo;
    procedure SendState;
    procedure SendPosition;
    procedure SendLockState(Locked: Boolean);
  end;

implementation

{ TMenuStateUpdater }

constructor TMenuStateUpdater.Create(Controller: TPluginController);
begin
  FController := Controller;
end;

procedure TMenuStateUpdater.OnExecute(Data: IUnknown);
begin
  if Assigned(FController) then
    FController.UpdateMenuState;
end;

{ TPluginController }

constructor TPluginController.Create(Core: IAIMPCore; Player: IAIMPServicePlayer);
begin
  FCore := Core;
  FPlayer := Player;
  if FCore.QueryInterface(IID_IAIMPServiceMenuManager, FMenuManager) <> S_OK then
    FMenuManager := nil;

  FMenuUpdater := TMenuStateUpdater.Create(Self);
end;

destructor TPluginController.Destroy;
begin
  if Assigned(FMenuLock) then FCore.UnregisterExtension(FMenuLock);
  if Assigned(FMenuToggle) then FCore.UnregisterExtension(FMenuToggle);

  FMenuLock := nil;
  FMenuToggle := nil;
  FMenuUpdater := nil;
  FMenuManager := nil;
  FPlayer := nil;
  FCore := nil;
  inherited;
end;

procedure TPluginController.InitMenus(Handler: IUnknown);
var
  ParentMenuItem: IAIMPMenuItem;
begin
  if FMenuManager = nil then Exit;

  if FMenuManager.GetBuiltIn(AIMP_MENUID_PLAYER_MAIN_FUNCTIONS, ParentMenuItem) <> S_OK then
    ParentMenuItem := nil;

  if FCore.CreateObject(IID_IAIMPMenuItem, FMenuToggle) = S_OK then
  begin
    FMenuToggle.SetValueAsObject(AIMP_MENUITEM_PROPID_ID, TAIMPUtils.MakeString(FCore, 'aimp.leoviki.ailrc.toggle'));
    FMenuToggle.SetValueAsObject(AIMP_MENUITEM_PROPID_NAME, TAIMPUtils.MakeString(FCore, '打开桌面歌词'));
    FMenuToggle.SetValueAsInt32(AIMP_MENUITEM_PROPID_STYLE, AIMP_MENUITEM_STYLE_CHECKBOX);
    FMenuToggle.SetValueAsObject(AIMP_MENUITEM_PROPID_EVENT, Handler);
    FMenuToggle.SetValueAsObject(AIMP_MENUITEM_PROPID_EVENT_ONSHOW, FMenuUpdater);

    if Assigned(ParentMenuItem) then
      FMenuToggle.SetValueAsObject(AIMP_MENUITEM_PROPID_PARENT, ParentMenuItem);

    FCore.RegisterExtension(IID_IAIMPServiceMenuManager, FMenuToggle);
  end;

  if FCore.CreateObject(IID_IAIMPMenuItem, FMenuLock) = S_OK then
  begin
    FMenuLock.SetValueAsObject(AIMP_MENUITEM_PROPID_ID, TAIMPUtils.MakeString(FCore, 'aimp.leoviki.ailrc.lock'));
    FMenuLock.SetValueAsObject(AIMP_MENUITEM_PROPID_NAME, TAIMPUtils.MakeString(FCore, '锁定桌面歌词'));
    FMenuLock.SetValueAsInt32(AIMP_MENUITEM_PROPID_STYLE, AIMP_MENUITEM_STYLE_CHECKBOX);
    FMenuLock.SetValueAsObject(AIMP_MENUITEM_PROPID_EVENT, Handler);
    FMenuLock.SetValueAsObject(AIMP_MENUITEM_PROPID_EVENT_ONSHOW, FMenuUpdater);

    if Assigned(ParentMenuItem) then
      FMenuLock.SetValueAsObject(AIMP_MENUITEM_PROPID_PARENT, ParentMenuItem);

    FCore.RegisterExtension(IID_IAIMPServiceMenuManager, FMenuLock);
  end;

  UpdateMenuState;
end;

procedure TPluginController.UpdateMenuState;
var
  Hwnd: THandle;
  IsRunning, IsLocked: Boolean;
begin
  Hwnd := FindWindow(nil, PChar(TARGET_WINDOW_TITLE));
  IsRunning := Hwnd <> 0;

  if IsRunning then
    IsLocked := TAIMPUtils.IsWindowLocked(Hwnd)
  else
    IsLocked := False;

  if Assigned(FMenuToggle) then
    FMenuToggle.SetValueAsInt32(AIMP_MENUITEM_PROPID_CHECKED, Integer(IsRunning));

  if Assigned(FMenuLock) then
  begin
    FMenuLock.SetValueAsInt32(AIMP_MENUITEM_PROPID_CHECKED, Integer(IsLocked));
    FMenuLock.SetValueAsInt32(AIMP_MENUITEM_PROPID_ENABLED, Integer(IsRunning));
  end;
end;

procedure TPluginController.HandleMenuAction(MenuItem: IAIMPMenuItem);
var
  ID: IAIMPString;
  IDStr: string;
begin
  if MenuItem.GetValueAsObject(AIMP_MENUITEM_PROPID_ID, IID_IAIMPString, ID) <> S_OK then Exit;
  IDStr := TAIMPUtils.GetAIMPString(ID);

  if IDStr = 'aimp.leoviki.ailrc.toggle' then
    ToggleApp
  else if IDStr = 'aimp.leoviki.ailrc.lock' then
    ToggleLock;

  UpdateMenuState;
end;

procedure TPluginController.LaunchApp;
var
  AppExe: string;
  Hwnd: THandle;
begin
  Hwnd := FindWindow(nil, PChar(TARGET_WINDOW_TITLE));
  if Hwnd = 0 then
  begin
    AppExe := ExtractFilePath(ParamStr(0)) + 'AILrc.exe';
    if FileExists(AppExe) then
    begin
      ShellExecute(0, 'open', PChar(AppExe), nil, PChar(ExtractFilePath(AppExe)), SW_SHOWNORMAL);
      SyncInitialData;
    end;
  end;
end;

procedure TPluginController.CloseApp;
var
  Hwnd: THandle;
begin
  Hwnd := FindWindow(nil, PChar(TARGET_WINDOW_TITLE));
  if Hwnd <> 0 then
    PostMessage(Hwnd, WM_CLOSE, 0, 0);
end;

procedure TPluginController.ToggleApp;
var
  Hwnd: THandle;
begin
  Hwnd := FindWindow(nil, PChar(TARGET_WINDOW_TITLE));
  if Hwnd <> 0 then
    CloseApp
  else
    LaunchApp;
end;

procedure TPluginController.SyncInitialData;
var
  Hwnd: THandle;
  Attempts: Integer;
begin
  Attempts := 0;
  repeat
    Sleep(100);
    Hwnd := FindWindow(nil, PChar(TARGET_WINDOW_TITLE));
    Inc(Attempts);
  until (Hwnd <> 0) or (Attempts > 50);

  if Hwnd <> 0 then
  begin
    Sleep(1000);
    SendTrackInfo;
    SendState;
  end;
end;

procedure TPluginController.ToggleLock;
var
  Hwnd: THandle;
  CurrentlyLocked: Boolean;
begin
  Hwnd := FindWindow(nil, PChar(TARGET_WINDOW_TITLE));
  if Hwnd = 0 then Exit;

  CurrentlyLocked := TAIMPUtils.IsWindowLocked(Hwnd);
  SendLockState(not CurrentlyLocked);
end;

procedure TPluginController.SendLockState(Locked: Boolean);
var
  JSON, Data: TJSONObject;
begin
  JSON := TJSONObject.Create;
  try
    Data := TJSONObject.Create;
    JSON.AddPair('type', 'lock');
    Data.AddPair('locked', TJSONBool.Create(Locked));
    JSON.AddPair('data', Data);
    TAIMPUtils.SendJSON(JSON);
  finally
    JSON.Free;
  end;
end;

procedure TPluginController.SendTrackInfo;
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
  try
    Data := TJSONObject.Create;
    JSON.AddPair('type', 'track');

    if PropList.GetValueAsObject(AIMP_FILEINFO_PROPID_TITLE, IID_IAIMPString, StrObj) = S_OK then
      Data.AddPair('title', TAIMPUtils.GetAIMPString(StrObj));

    if PropList.GetValueAsObject(AIMP_FILEINFO_PROPID_ARTIST, IID_IAIMPString, StrObj) = S_OK then
      Data.AddPair('artist', TAIMPUtils.GetAIMPString(StrObj));

    if PropList.GetValueAsObject(AIMP_FILEINFO_PROPID_ALBUM, IID_IAIMPString, StrObj) = S_OK then
      Data.AddPair('album', TAIMPUtils.GetAIMPString(StrObj));

    if PropList.GetValueAsObject(AIMP_FILEINFO_PROPID_FILENAME, IID_IAIMPString, StrObj) = S_OK then
      Data.AddPair('file_path', TAIMPUtils.GetAIMPString(StrObj));

    if PropList.GetValueAsFloat(AIMP_FILEINFO_PROPID_DURATION, Duration) = S_OK then
      Data.AddPair('duration', TJSONNumber.Create(Duration));

    JSON.AddPair('data', Data);
    TAIMPUtils.SendJSON(JSON);
  finally
    JSON.Free;
  end;
end;

procedure TPluginController.SendState;
var
  State: Integer;
  JSON, Data: TJSONObject;
begin
  if FPlayer = nil then Exit;
  State := FPlayer.GetState;

  JSON := TJSONObject.Create;
  try
    Data := TJSONObject.Create;
    JSON.AddPair('type', 'state');
    Data.AddPair('state', TJSONNumber.Create(State));
    JSON.AddPair('data', Data);
    TAIMPUtils.SendJSON(JSON);
  finally
    JSON.Free;
  end;
end;

procedure TPluginController.SendPosition;
var
  Seconds: Double;
  JSON, Data: TJSONObject;
begin
  if FPlayer = nil then Exit;
  if FPlayer.GetPosition(Seconds) <> S_OK then Exit;

  JSON := TJSONObject.Create;
  try
    Data := TJSONObject.Create;
    JSON.AddPair('type', 'position');
    Data.AddPair('position', TJSONNumber.Create(Seconds));
    JSON.AddPair('data', Data);
    TAIMPUtils.SendJSON(JSON);
  finally
    JSON.Free;
  end;
end;

end.
