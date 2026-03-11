#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

// Registers the io.supabase.rateme:// URL scheme in the current-user registry
// so Windows routes OAuth deep-link callbacks back to this executable.
static void RegisterUrlScheme() {
  wchar_t exePath[MAX_PATH] = {};
  GetModuleFileNameW(nullptr, exePath, MAX_PATH);

  // Command string: "C:\path\to\rateme.exe" "%1"
  wchar_t command[MAX_PATH + 8] = {};
  _snwprintf_s(command, _countof(command), _TRUNCATE, L"\"%s\" \"%%1\"",
               exePath);

  const wchar_t* kBase = L"Software\\Classes\\io.supabase.rateme";
  const wchar_t* kCmd  =
      L"Software\\Classes\\io.supabase.rateme\\shell\\open\\command";

  HKEY hKey = nullptr;
  // Root key: URL scheme description + "URL Protocol" marker
  if (RegCreateKeyExW(HKEY_CURRENT_USER, kBase, 0, nullptr, 0,
                      KEY_SET_VALUE, nullptr, &hKey, nullptr) == ERROR_SUCCESS) {
    const wchar_t* kDesc = L"rateme OAuth Callback";
    RegSetValueExW(hKey, nullptr, 0, REG_SZ,
                   reinterpret_cast<const BYTE*>(kDesc),
                   static_cast<DWORD>((wcslen(kDesc) + 1) * sizeof(wchar_t)));
    RegSetValueExW(hKey, L"URL Protocol", 0, REG_SZ,
                   reinterpret_cast<const BYTE*>(L""),
                   static_cast<DWORD>(sizeof(wchar_t)));
    RegCloseKey(hKey);
  }

  // Command key: tells Windows which binary to launch
  if (RegCreateKeyExW(HKEY_CURRENT_USER, kCmd, 0, nullptr, 0,
                      KEY_SET_VALUE, nullptr, &hKey, nullptr) == ERROR_SUCCESS) {
    RegSetValueExW(hKey, nullptr, 0, REG_SZ,
                   reinterpret_cast<const BYTE*>(command),
                   static_cast<DWORD>((wcslen(command) + 1) * sizeof(wchar_t)));
    RegCloseKey(hKey);
  }
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Register the custom URL scheme so the OS can route OAuth callbacks back.
  RegisterUrlScheme();

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"rateme", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
