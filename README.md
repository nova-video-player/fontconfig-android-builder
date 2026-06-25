### fontconfig-android-builder

A simple shell script to cross-compile fontconfig project for Android targets.

Builds the binaries and libs using static linking.

Typical usage:
```
bash ./build.sh
```

Requirements:
- Android SDK & NDK
- prebuilt FreeType (via libfreetype-android-builder)
- prebuilt libxml2 (via libxml2-android-builder)
- prebuilt zlib (via zlib-android-builder)
- some dev tools
