# Cross-compile a 32-bit Windows exe with mingw-w64 (brew install mingw-w64 / apt install g++-mingw-w64-i686).
CXX       = i686-w64-mingw32-g++
CXXFLAGS  = -O2 -std=c++17 -Wall -Wno-unused-function -Iinclude
LDFLAGS   = -s -static -static-libgcc -static-libstdc++
LDLIBS    = -lws2_32 -lshlwapi -lpsapi -luser32
TARGET    = dist/ffxi-login.exe

all: $(TARGET)

$(TARGET): FFXI-Launcher.cpp sha1.cpp sha1.h include/nlohmann/json.hpp
	mkdir -p dist
	$(CXX) $(CXXFLAGS) -o $@ FFXI-Launcher.cpp sha1.cpp $(LDFLAGS) $(LDLIBS)

clean:
	rm -rf dist

.PHONY: all clean
