#include "Controller.h"
#include "Utils.h"
#include <nlohmann/json.hpp>
#include <shellapi.h>

void WINAPI MenuStateUpdater::OnExecute(IUnknown* Data) {
    if (FController) {
        FController->UpdateMenuState();
    }
}

PluginController::PluginController(IAIMPCore* core, IAIMPServicePlayer* player) 
    : FCore(core), FPlayer(player), FMenuManager(nullptr), FMenuToggle(nullptr), FMenuLock(nullptr) {
    
    FCore->AddRef();
    if (FPlayer) FPlayer->AddRef();

    if (FCore->QueryInterface(IID_IAIMPServiceMenuManager, reinterpret_cast<void**>(&FMenuManager)) != S_OK) {
        FMenuManager = nullptr;
    }

    FMenuUpdater = new MenuStateUpdater(this);
    FMenuUpdater->AddRef();
}

PluginController::~PluginController() {
    if (FMenuLock) {
        FCore->UnregisterExtension(FMenuLock);
        FMenuLock->Release();
    }
    if (FMenuToggle) {
        FCore->UnregisterExtension(FMenuToggle);
        FMenuToggle->Release();
    }
    if (FMenuUpdater) {
        FMenuUpdater->Release();
    }
    if (FMenuManager) {
        FMenuManager->Release();
    }
    if (FPlayer) {
        FPlayer->Release();
    }
    if (FCore) {
        FCore->Release();
    }
}

void PluginController::InitMenus(IUnknown* handler) {
    if (!FMenuManager) return;

    IAIMPMenuItem* parentMenuItem = nullptr;
    if (FMenuManager->GetBuiltIn(AIMP_MENUID_PLAYER_MAIN_FUNCTIONS, &parentMenuItem) != S_OK) {
        parentMenuItem = nullptr;
    }

    if (FCore->CreateObject(IID_IAIMPMenuItem, reinterpret_cast<void**>(&FMenuToggle)) == S_OK) {
        IAIMPString* idStr = Utils::MakeAIMPString(FCore, L"aimp.leoviki.ailrc.toggle");
        IAIMPString* nameStr = Utils::MakeAIMPString(FCore, L"AILrc");
        
        FMenuToggle->SetValueAsObject(AIMP_MENUITEM_PROPID_ID, idStr);
        FMenuToggle->SetValueAsObject(AIMP_MENUITEM_PROPID_NAME, nameStr);
        FMenuToggle->SetValueAsInt32(AIMP_MENUITEM_PROPID_STYLE, AIMP_MENUITEM_STYLE_CHECKBOX);
        FMenuToggle->SetValueAsObject(AIMP_MENUITEM_PROPID_EVENT, handler);
        FMenuToggle->SetValueAsObject(AIMP_MENUITEM_PROPID_EVENT_ONSHOW, FMenuUpdater);

        if (parentMenuItem) {
            FMenuToggle->SetValueAsObject(AIMP_MENUITEM_PROPID_PARENT, parentMenuItem);
        }

        FCore->RegisterExtension(IID_IAIMPServiceMenuManager, FMenuToggle);
        
        if (idStr) idStr->Release();
        if (nameStr) nameStr->Release();
    }

    if (FCore->CreateObject(IID_IAIMPMenuItem, reinterpret_cast<void**>(&FMenuLock)) == S_OK) {
        IAIMPString* idStr = Utils::MakeAIMPString(FCore, L"aimp.leoviki.ailrc.lock");
        IAIMPString* nameStr = Utils::MakeAIMPString(FCore, L"Lock AILrc");
        
        FMenuLock->SetValueAsObject(AIMP_MENUITEM_PROPID_ID, idStr);
        FMenuLock->SetValueAsObject(AIMP_MENUITEM_PROPID_NAME, nameStr);
        FMenuLock->SetValueAsInt32(AIMP_MENUITEM_PROPID_STYLE, AIMP_MENUITEM_STYLE_CHECKBOX);
        FMenuLock->SetValueAsObject(AIMP_MENUITEM_PROPID_EVENT, handler);
        FMenuLock->SetValueAsObject(AIMP_MENUITEM_PROPID_EVENT_ONSHOW, FMenuUpdater);

        if (parentMenuItem) {
            FMenuLock->SetValueAsObject(AIMP_MENUITEM_PROPID_PARENT, parentMenuItem);
        }

        FCore->RegisterExtension(IID_IAIMPServiceMenuManager, FMenuLock);
        
        if (idStr) idStr->Release();
        if (nameStr) nameStr->Release();
    }

    if (parentMenuItem) parentMenuItem->Release();

    UpdateMenuState();
}

void PluginController::UpdateMenuState() {
    HWND hwnd = FindWindowW(nullptr, Utils::TARGET_WINDOW_TITLE);
    bool isRunning = (hwnd != nullptr);
    bool isLocked = isRunning ? Utils::IsWindowLocked(hwnd) : false;

    if (FMenuToggle) {
        FMenuToggle->SetValueAsInt32(AIMP_MENUITEM_PROPID_CHECKED, isRunning ? 1 : 0);
    }
    if (FMenuLock) {
        FMenuLock->SetValueAsInt32(AIMP_MENUITEM_PROPID_CHECKED, isLocked ? 1 : 0);
        FMenuLock->SetValueAsInt32(AIMP_MENUITEM_PROPID_ENABLED, isRunning ? 1 : 0);
    }
}

void PluginController::HandleMenuAction(IAIMPMenuItem* menuItem) {
    IAIMPString* idObj = nullptr;
    if (menuItem->GetValueAsObject(AIMP_MENUITEM_PROPID_ID, IID_IAIMPString, reinterpret_cast<void**>(&idObj)) != S_OK) {
        return;
    }
    
    std::wstring idStr = Utils::GetAIMPString(idObj);
    idObj->Release();

    if (idStr == L"aimp.leoviki.ailrc.toggle") {
        ToggleApp();
    } else if (idStr == L"aimp.leoviki.ailrc.lock") {
        ToggleLock();
    }

    UpdateMenuState();
}

void PluginController::LaunchApp() {
    HWND hwnd = FindWindowW(nullptr, Utils::TARGET_WINDOW_TITLE);
    if (!hwnd) {
        wchar_t exePath[MAX_PATH];
        GetModuleFileNameW(nullptr, exePath, MAX_PATH);
        std::wstring pathStr = exePath;
        size_t pos = pathStr.find_last_of(L"\\/");
        if (pos != std::wstring::npos) {
            std::wstring dirStr = pathStr.substr(0, pos + 1);
            std::wstring appExe = dirStr + L"AILrc.exe";
            
            // In AIMP plugins, the exe path might actually be the AIMP.exe.
            // Wait, in Delphi `ExtractFilePath(ParamStr(0))` gives AIMP.exe path! 
            // So AILrc.exe is supposed to be next to AIMP.exe.
            ShellExecuteW(nullptr, L"open", appExe.c_str(), nullptr, dirStr.c_str(), SW_SHOWNORMAL);
            SyncInitialData();
        }
    }
}

void PluginController::CloseApp() {
    HWND hwnd = FindWindowW(nullptr, Utils::TARGET_WINDOW_TITLE);
    if (hwnd) {
        PostMessageW(hwnd, WM_CLOSE, 0, 0);
    }
}

void PluginController::ToggleApp() {
    HWND hwnd = FindWindowW(nullptr, Utils::TARGET_WINDOW_TITLE);
    if (hwnd) {
        CloseApp();
    } else {
        LaunchApp();
    }
}

void PluginController::SyncInitialData() {
    HWND hwnd = nullptr;
    int attempts = 0;
    do {
        Sleep(100);
        hwnd = FindWindowW(nullptr, Utils::TARGET_WINDOW_TITLE);
        attempts++;
    } while (!hwnd && attempts <= 50);

    if (hwnd) {
        Sleep(1000);
        SendTrackInfo();
        SendState();
    }
}

void PluginController::ToggleLock() {
    HWND hwnd = FindWindowW(nullptr, Utils::TARGET_WINDOW_TITLE);
    if (!hwnd) return;
    bool currentlyLocked = Utils::IsWindowLocked(hwnd);
    SendLockState(!currentlyLocked);
}

void PluginController::SendLockState(bool locked) {
    nlohmann::json j;
    j["type"] = "lock";
    j["data"]["locked"] = locked;
    Utils::SendJSON(j.dump());
}

void PluginController::SendTrackInfo() {
    if (!FPlayer) return;

    IAIMPFileInfo* fileInfo = nullptr;
    if (FPlayer->GetInfo(&fileInfo) != S_OK) return;

    IAIMPPropertyList* propList = nullptr;
    if (fileInfo->QueryInterface(IID_IAIMPPropertyList, reinterpret_cast<void**>(&propList)) != S_OK) {
        fileInfo->Release();
        return;
    }

    nlohmann::json j;
    j["type"] = "track";

    IAIMPString* strObj = nullptr;
    
    if (propList->GetValueAsObject(AIMP_FILEINFO_PROPID_TITLE, IID_IAIMPString, reinterpret_cast<void**>(&strObj)) == S_OK) {
        j["data"]["title"] = Utils::WideToUTF8(Utils::GetAIMPString(strObj));
        strObj->Release();
    }
    if (propList->GetValueAsObject(AIMP_FILEINFO_PROPID_ARTIST, IID_IAIMPString, reinterpret_cast<void**>(&strObj)) == S_OK) {
        j["data"]["artist"] = Utils::WideToUTF8(Utils::GetAIMPString(strObj));
        strObj->Release();
    }
    if (propList->GetValueAsObject(AIMP_FILEINFO_PROPID_ALBUM, IID_IAIMPString, reinterpret_cast<void**>(&strObj)) == S_OK) {
        j["data"]["album"] = Utils::WideToUTF8(Utils::GetAIMPString(strObj));
        strObj->Release();
    }
    if (propList->GetValueAsObject(AIMP_FILEINFO_PROPID_FILENAME, IID_IAIMPString, reinterpret_cast<void**>(&strObj)) == S_OK) {
        j["data"]["file_path"] = Utils::WideToUTF8(Utils::GetAIMPString(strObj));
        strObj->Release();
    }

    double duration = 0.0;
    if (propList->GetValueAsFloat(AIMP_FILEINFO_PROPID_DURATION, &duration) == S_OK) {
        j["data"]["duration"] = duration;
    }

    Utils::SendJSON(j.dump());

    propList->Release();
    fileInfo->Release();
}

void PluginController::SendState() {
    if (!FPlayer) return;
    int state = FPlayer->GetState();
    nlohmann::json j;
    j["type"] = "state";
    j["data"]["state"] = state;
    Utils::SendJSON(j.dump());
}

void PluginController::SendPosition() {
    if (!FPlayer) return;
    double seconds = 0.0;
    if (FPlayer->GetPosition(&seconds) == S_OK) {
        nlohmann::json j;
        j["type"] = "position";
        j["data"]["position"] = seconds;
        Utils::SendJSON(j.dump());
    }
}
