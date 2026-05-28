#include "Utils.h"
#include <vector>

namespace Utils {

    std::wstring GetAIMPString(IAIMPString* aimpStr) {
        if (!aimpStr) return L"";
        int len = aimpStr->GetLength();
        if (len <= 0) return L"";
        return std::wstring(aimpStr->GetData(), len);
    }

    IAIMPString* MakeAIMPString(IAIMPCore* core, const std::wstring& str) {
        IAIMPString* result = nullptr;
        if (core->CreateObject(IID_IAIMPString, reinterpret_cast<void**>(&result)) == S_OK) {
            result->SetData(const_cast<wchar_t*>(str.c_str()), str.length());
        }
        return result;
    }

    std::string WideToUTF8(const std::wstring& wstr) {
        if (wstr.empty()) return std::string();
        int size_needed = WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), NULL, 0, NULL, NULL);
        std::string strTo(size_needed, 0);
        WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), &strTo[0], size_needed, NULL, NULL);
        return strTo;
    }

    std::wstring UTF8ToWide(const std::string& str) {
        if (str.empty()) return std::wstring();
        int size_needed = MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), NULL, 0);
        std::wstring wstrTo(size_needed, 0);
        MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), &wstrTo[0], size_needed);
        return wstrTo;
    }

    HWND GetCachedWindow() {
        static HWND cachedHwnd = nullptr;
        if (cachedHwnd && IsWindow(cachedHwnd)) {
            return cachedHwnd;
        }
        cachedHwnd = FindWindowW(nullptr, TARGET_WINDOW_TITLE);
        return cachedHwnd;
    }

    void SendJSON(const std::string& jsonStr) {
        HWND hwnd = GetCachedWindow();
        if (!hwnd) return;

        COPYDATASTRUCT copyData;
        copyData.dwData = COPYDATA_ID_AILRC;
        copyData.cbData = static_cast<DWORD>(jsonStr.length() + 1);
        copyData.lpData = const_cast<char*>(jsonStr.c_str());

        SendMessageTimeoutW(hwnd, WM_COPYDATA, 0, reinterpret_cast<LPARAM>(&copyData),
            SMTO_ABORTIFHUNG | SMTO_NORMAL, 10, nullptr);
    }

    bool IsWindowLocked(HWND hwnd) {
        if (!hwnd) return false;
        LONG_PTR style = GetWindowLongPtrW(hwnd, GWL_EXSTYLE);
        return (style & WS_EX_TRANSPARENT) != 0;
    }

}
