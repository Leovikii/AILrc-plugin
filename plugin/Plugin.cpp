#include "apiPlugin.h"
#include "apiMessages.h"
#include "Controller.h"
#include "IUnknownImpl.h"

class LifecyclePlugin;

class MessageHookImpl : public IUnknownImpl<IAIMPMessageHook> {
private:
    PluginController* FController;
public:
    MessageHookImpl() : FController(nullptr) {}

    void SetController(PluginController* controller) {
        FController = controller;
    }

    virtual BOOL isOurRIID(REFIID riid) override {
        return IsEqualGUID(riid, IID_IAIMPMessageHook);
    }

    virtual void WINAPI CoreMessage(DWORD Message, int Param1, void* Param2, HRESULT* Result) override {
        if (!FController) return;

        switch (Message) {
            case AIMP_MSG_EVENT_STREAM_START:
            case AIMP_MSG_EVENT_PLAYING_FILE_INFO:
                FController->SendTrackInfo();
                break;
            case AIMP_MSG_EVENT_PLAYER_STATE:
                FController->SendState();
                break;
            case AIMP_MSG_EVENT_PLAYER_UPDATE_POSITION_HR:
                FController->SendPosition();
                break;
        }
    }
};

class ActionEventImpl : public IUnknownImpl<IAIMPActionEvent> {
private:
    PluginController* FController;
public:
    ActionEventImpl() : FController(nullptr) {}

    void SetController(PluginController* controller) {
        FController = controller;
    }

    virtual BOOL isOurRIID(REFIID riid) override {
        return IsEqualGUID(riid, IID_IAIMPActionEvent);
    }

    virtual void WINAPI OnExecute(IUnknown* Data) override {
        if (!FController || !Data) return;
        
        IAIMPMenuItem* menuItem = nullptr;
        if (Data->QueryInterface(IID_IAIMPMenuItem, reinterpret_cast<void**>(&menuItem)) == S_OK) {
            FController->HandleMenuAction(menuItem);
            menuItem->Release();
        }
    }
};

class LifecyclePlugin : public IUnknownImpl<IAIMPPlugin> {
private:
    IAIMPCore* FCore;
    IAIMPServiceMessageDispatcher* FMessageDispatcher;
    PluginController* FController;
    
    MessageHookImpl* FMessageHook;
    ActionEventImpl* FActionEvent;

public:
    LifecyclePlugin() : FCore(nullptr), FMessageDispatcher(nullptr), FController(nullptr) {
        FMessageHook = new MessageHookImpl();
        FMessageHook->AddRef();
        
        FActionEvent = new ActionEventImpl();
        FActionEvent->AddRef();
    }

    virtual ~LifecyclePlugin() {
        FActionEvent->Release();
        FMessageHook->Release();
    }

    virtual BOOL isOurRIID(REFIID riid) override {
        // IAIMPPlugin doesn't have an IID, but we return true just in case AIMP checks for it
        return false;
    }

    virtual PWCHAR WINAPI InfoGet(int Index) override {
        switch (Index) {
            case AIMP_PLUGIN_INFO_NAME:              return const_cast<PWCHAR>(L"AILrc plugin v3.0.0");
            case AIMP_PLUGIN_INFO_AUTHOR:            return const_cast<PWCHAR>(L"LeoViki");
            case AIMP_PLUGIN_INFO_SHORT_DESCRIPTION: return const_cast<PWCHAR>(L"Syncs metadata and lyrics position to AILrc");
            default:                                 return nullptr;
        }
    }

    virtual DWORD WINAPI InfoGetCategories() override {
        return AIMP_PLUGIN_CATEGORY_ADDONS;
    }

    virtual HRESULT WINAPI Initialize(IAIMPCore* Core) override {
        FCore = Core;
        FCore->AddRef();

        if (FCore->QueryInterface(IID_IAIMPServiceMessageDispatcher, reinterpret_cast<void**>(&FMessageDispatcher)) != S_OK) {
            return E_FAIL;
        }

        IAIMPServicePlayer* playerService = nullptr;
        if (FCore->QueryInterface(IID_IAIMPServicePlayer, reinterpret_cast<void**>(&playerService)) != S_OK) {
            return E_FAIL;
        }

        if (FMessageDispatcher->Hook(FMessageHook) != S_OK) {
            playerService->Release();
            return E_FAIL;
        }

        FController = new PluginController(FCore, playerService);
        FMessageHook->SetController(FController);
        FActionEvent->SetController(FController);

        FController->InitMenus(FActionEvent);
        FController->LaunchApp();

        playerService->Release();

        return S_OK;
    }

    virtual HRESULT WINAPI Finalize() override {
        if (FController) {
            FController->CloseApp();
            delete FController;
            FController = nullptr;
            FMessageHook->SetController(nullptr);
            FActionEvent->SetController(nullptr);
        }

        if (FMessageDispatcher) {
            FMessageDispatcher->Unhook(FMessageHook);
            FMessageDispatcher->Release();
            FMessageDispatcher = nullptr;
        }

        if (FCore) {
            FCore->Release();
            FCore = nullptr;
        }

        return S_OK;
    }

    virtual void WINAPI SystemNotification(int NotifyID, IUnknown* Data) override {
    }
};

extern "C" __declspec(dllexport) HRESULT WINAPI AIMPPluginGetHeader(IAIMPPlugin** Header) {
    if (!Header) return E_POINTER;
    LifecyclePlugin* plugin = new LifecyclePlugin();
    plugin->AddRef();
    *Header = plugin;
    return S_OK;
}
