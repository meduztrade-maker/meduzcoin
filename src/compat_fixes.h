// Compatibility shim for building this 2018-era codebase with modern GCC/libstdc++,
// which no longer leaks these headers in transitively the way older toolchains did.
// Force-included into every translation unit via CMAKE_CXX_FLAGS (-include).
#pragma once

#include <cstdint>
#include <cstddef>
#include <cstring>
#include <cstdio>
#include <cstdlib>
#include <stdexcept>
#include <memory>
#include <string>
#include <vector>
#include <algorithm>
#include <limits>
#include <thread>
#include <chrono>
