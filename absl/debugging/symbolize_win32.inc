// Copyright 2018 The Abseil Authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// See "Retrieving Symbol Information by Address":
// https://msdn.microsoft.com/en-us/library/windows/desktop/ms680578(v=vs.85).aspx

#include <windows.h>
#include <winternl.h>

// MSVC header dbghelp.h has a warning for an ignored typedef.
#pragma warning(push)
#pragma warning(disable:4091)
#include <dbghelp.h>
#pragma warning(pop)

#pragma comment(lib, "dbghelp.lib")

#include <algorithm>
#include <cstring>

#include "absl/base/internal/raw_logging.h"

namespace absl {
ABSL_NAMESPACE_BEGIN

static HANDLE process = NULL;

void InitializeSymbolizer(const char*) {
  if (process != nullptr) {
    return;
  }
  process = (HANDLE)static_cast<uintptr_t>(GetCurrentProcessId());

  // Symbols are not loaded until a reference is made requiring the
  // symbols be loaded. This is the fastest, most efficient way to use
  // the symbol handler.
  SymSetOptions(SYMOPT_DEFERRED_LOADS | SYMOPT_UNDNAME);
  DWORD syminitialize_error;
  constexpr int kSymInitializeRetries = 5;
  for (int i = 0; i < kSymInitializeRetries; ++i) {
    if (SymInitialize(process, nullptr, true)) {
      return;
    }

    // SymInitialize can fail sometimes with a STATUS_INFO_LENGTH_MISMATCH
    // NTSTATUS (0xC0000004), which can happen when a module load occurs during
    // the SymInitialize call. In this case, we should try calling SymInitialize
    // again.
    constexpr DWORD kStatusInfoLengthMismatch = DWORD{0xC0000004};
    syminitialize_error = GetLastError();
    if (syminitialize_error != kStatusInfoLengthMismatch) {
      break;
    }
  }

  // GetLastError() returns a Win32 DWORD, but we assign to
  // unsigned long long to simplify the ABSL_RAW_LOG case below.  The uniform
  // initialization guarantees this is not a narrowing conversion.
  const unsigned long long error{syminitialize_error};
  ABSL_RAW_LOG(FATAL, "SymInitialize() failed: %llu", error);
}

bool Symbolize_Internal(const void* pc, char* out, int out_size) {
  if (out == nullptr || out_size <= 0) {
    return false;
  }

  const DWORD64 addr = reinterpret_cast<DWORD64>(pc);

  alignas(SYMBOL_INFO) char sym_buf[sizeof(SYMBOL_INFO) + MAX_SYM_NAME];
  SYMBOL_INFO* symbol = reinterpret_cast<SYMBOL_INFO*>(sym_buf);
  symbol->SizeOfStruct = sizeof(SYMBOL_INFO);
  symbol->MaxNameLen = MAX_SYM_NAME;

  IMAGEHLP_MODULE64 module = {};
  module.SizeOfStruct = sizeof(module);

  const bool have_symbol = SymFromAddr(process, addr, nullptr, symbol) == TRUE;
  const bool have_module = SymGetModuleInfo64(process, addr, &module) == TRUE;

  if (!have_symbol && !have_module) {
    return false;
  }

  const char* module_name = nullptr;
  if (have_module) {
    if (module.ModuleName[0] != '\0') {
      module_name = module.ModuleName;
    } else if (module.LoadedImageName[0] != '\0') {
      module_name = module.LoadedImageName;
    } else if (module.ImageName[0] != '\0') {
      module_name = module.ImageName;
    }
  }

  char full[512];
  if (have_symbol && module_name) {
    _snprintf_s(full, sizeof(full), _TRUNCATE, "%s:%s", module_name, symbol->Name);
  } else if (have_symbol) {
    _snprintf_s(full, sizeof(full), _TRUNCATE, "%s", symbol->Name);
  } else {
    _snprintf_s(full, sizeof(full), _TRUNCATE, "%s", module_name);
  }

  const size_t out_size_t = static_cast<size_t>(out_size);
  strncpy(out, full, out_size_t);
  if (out[out_size_t - 1] != '\0') {
    static constexpr char kEllipsis[] = "...";
    const size_t ellipsis_size =
        std::min(sizeof(kEllipsis) - 1, out_size_t - 1);
    memcpy(out + out_size_t - ellipsis_size - 1, kEllipsis, ellipsis_size);
    out[out_size_t - 1] = '\0';
  }

  return true;
}

bool Symbolize(const void *pc, char* out, int out_size) {
  // Try symbolizing once first
  if (Symbolize_Internal(pc, out, out_size)) {
    return true;
  }

  // Failed, try refreshing module list and then symbolize again
  SymRefreshModuleList(process);
  return Symbolize_Internal(pc, out, out_size);
}

ABSL_NAMESPACE_END
}  // namespace absl
