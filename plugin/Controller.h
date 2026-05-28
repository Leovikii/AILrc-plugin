#pragma once

#include "apiCore.h"
#include "apiPlayer.h"
#include "apiMenu.h"
#include "apiMessages.h"
#include "apiActions.h"
#include "IUnknownImpl.h"
#include <string>

class PluginController;

class MenuStateUpdater : public IUnknownImpl<IAIMPActionEvent> {
private:
    PluginController* FController;
public:
    MenuStateUpdater(PluginController* controller) : FController(controller) {}

    virtual BOOL isOurRIID(REFIID riid) override {
        return IsEqualGUID(riid, IID_IAIMPActionEvent);
    }

    virtual void WINAPI OnExecute(IUnknown* Data) override;
};

class PluginController {
private:
    IAIMPCore* FCore;
    IAIMPServicePlayer* FPlayer;
    IAIMPServiceMenuManager* FMenuManager;
    
    IAIMPMenuItem* FMenuToggle;
    IAIMPMenuItem* FMenuLock;
    MenuStateUpdater* FMenuUpdater;

    void SyncInitialData();
    std::string GetTrackInfoJSON();
    std::string GetStateJSON();

public:
    PluginController(IAIMPCore* core, IAIMPServicePlayer* player);
    ~PluginController();

    void InitMenus(IUnknown* handler);
    void HandleMenuAction(IAIMPMenuItem* menuItem);
    void UpdateMenuState();

    void LaunchApp();
    void CloseApp();
    void ToggleApp();
    void ToggleLock();

    void SendTrackInfo();
    void SendState();
    void SendPosition();
    void SendLockState(bool locked);
};
