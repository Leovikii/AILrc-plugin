#pragma once
#include <windows.h>
#include <string>
#include "apiObjects.h"
#include "apiCore.h"

namespace Utils {

    std::wstring GetAIMPString(IAIMPString* aimpStr);
    IAIMPString* MakeAIMPString(IAIMPCore* core, const std::wstring& str);

    std::string WideToUTF8(const std::wstring& wstr);
    std::wstring UTF8ToWide(const std::string& str);

    void SendJSON(const std::string& jsonStr);
    bool IsWindowLocked(HWND hwnd);

    constexpr const wchar_t* TARGET_WINDOW_TITLE = L"AILrc";
    constexpr ULONG_PTR COPYDATA_ID_AILRC = 0x41494C52; // Needs to match Delphi's COPYDATA_ID_AILRC (Wait, Delphi used what? Let's check...)
}
