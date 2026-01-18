unit uPlugin;

interface

uses
  Windows, Messages, SysUtils, Classes,
  apiPlugin, apiCore, apiMessages, apiPlayer, apiMenu, apiActions,
  uController;

type
  TAIMPLifecyclePlugin = class(TInterfacedObject, IAIMPPlugin, IAIMPMessageHook, IAIMPActionEvent)
  private
    FCore: IAIMPCore;
    FMessageDispatcher: IAIMPServiceMessageDispatcher;
    FController: TPluginController;
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

function TAIMPLifecyclePlugin.InfoGetCategories: Cardinal;
begin
  Result := AIMP_PLUGIN_CATEGORY_ADDONS;
end;

function TAIMPLifecyclePlugin.InfoGet(Index: Integer): PWideChar;
begin
  case Index of
    AIMP_PLUGIN_INFO_NAME:              Result := 'AILrc plugin v2.2';
    AIMP_PLUGIN_INFO_AUTHOR:            Result := 'LeoViki';
    AIMP_PLUGIN_INFO_SHORT_DESCRIPTION: Result := 'Syncs metadata and lyrics position to AILrc';
  else
    Result := nil;
  end;
end;

function TAIMPLifecyclePlugin.Initialize(Core: IAIMPCore): HRESULT;
var
  PlayerService: IAIMPServicePlayer;
begin
  FCore := Core;

  if FCore.QueryInterface(IID_IAIMPServiceMessageDispatcher, FMessageDispatcher) <> S_OK then
    Exit(E_FAIL);

  if FCore.QueryInterface(IID_IAIMPServicePlayer, PlayerService) <> S_OK then
    Exit(E_FAIL);

  if FMessageDispatcher.Hook(Self) <> S_OK then
    Exit(E_FAIL);

  FController := TPluginController.Create(FCore, PlayerService);
  FController.InitMenus(Self);
  FController.ToggleApp;

  Result := S_OK;
end;

procedure TAIMPLifecyclePlugin.Finalize;
begin
  if Assigned(FController) then
  begin
    FController.ToggleApp;
    FController.Free;
    FController := nil;
  end;

  if Assigned(FMessageDispatcher) then
    FMessageDispatcher.Unhook(Self);

  FMessageDispatcher := nil;
  FCore := nil;
end;

procedure TAIMPLifecyclePlugin.SystemNotification(NotifyID: Integer; Data: IUnknown);
begin
end;

procedure TAIMPLifecyclePlugin.CoreMessage(Message: LongWord; Param1: Integer;
  Param2: Pointer; var Result: HRESULT);
begin
  if FController = nil then Exit;

  case Message of
    AIMP_MSG_EVENT_STREAM_START,
    AIMP_MSG_EVENT_PLAYING_FILE_INFO:
      FController.SendTrackInfo;

    AIMP_MSG_EVENT_PLAYER_STATE:
      FController.SendState;

    AIMP_MSG_EVENT_PLAYER_UPDATE_POSITION_HR:
      FController.SendPosition;
  end;
end;

procedure TAIMPLifecyclePlugin.OnExecute(Data: IUnknown);
var
  MenuItem: IAIMPMenuItem;
begin
  if (Data.QueryInterface(IID_IAIMPMenuItem, MenuItem) = S_OK) and Assigned(FController) then
  begin
    FController.HandleMenuAction(MenuItem);
  end;
end;

end.
