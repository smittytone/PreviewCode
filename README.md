# PreviewCode 2.2.2

*PreviewCode* provides macOS QuickLook file previews and Finder icon thumbnails for more than 50 programming and scripting languages, header files, and data files.

It is not exhaustive, nor is it intended to be. It is, however, intended to support [the most popular languages](#languages) used by Mac-based developers, whether for use on a Mac or on other platforms.

[![PreviewCode App Store QR code](qr-code.jpg)](https://apps.apple.com/gb/app/previewcode/id1571797683?mt=12)

## Installation and Usage ##

Just run the host app once to register the extensions &mdash; you can quit the app as soon as it has launched. We recommend logging out of your Mac and back in again at this point. Now you can preview source code files using QuickLook (select an icon and hit Space), and Finder’s preview pane and **Info** panels.

You can disable and re-enable the Code Previewer and Code Thumbnailer extensions at any time in **System Preferences > Extensions > Quick Look**.

### Adjusting the Preview

Open the main app and click on **Show Preview Preferences**, or select **Preferences...** from the **PreviewCode** menu.

You can select from a range of text sizes, choose a monospace font, select the font’s style — regular, bold, italic, etc. — choose your preferred line spacing, and pick which theme you would like previews to use. One hundred themes are included, and you can view all of them, or just dark or light ones.

*PreviewCode* will allow you to select a dark theme or a light one. These will be applied whatever UI mode your Mac is set to. If you select auto mode, you choose two themes, one light, the other dark. These will be applied automatically based on the current UI mode.

## Languages

### Compiled Languages

- ActionScript (`.actionscript`)
- Ada (`.ads`, `.adb`)
- AppleScript (`.applescript`)
- Arduino (`.arduino`, `.ino`)
- Basic (`.basic`, `.bas`)
- Brainfuck (`.brainfuck`, `.b`, `.bf`)
- C (`.c`, `.h`)
- C++ (`.cpp`, `.hpp`)
- C# (`.csx`, `.cs`, `.c-sharp`, `.csharp`)
- Clojure (`.clojure`, `.clj`, `.cljc`, `.cljs`)
- CoffeeScript (`.coffee`, `.coffeescript`, `.litcoffee`)
- Dart (`.dart`)
- Elixir (`.elxir`, `.ex`, `.exs`)
- Elm (`.elm`)
- Erlang (`.erlang`, `.erl`, `.hrl`)
- Fortran (`.for`)
- F# (`.fsharp`, `.f-sharp`, `.fsi`, `.fsx`, `.fsscript`)
- Go (`.go`)
- GameMaker Language (`.gml`)
- Haskell (`.haskell`, `.hs`, `.lhs`)
- Java (`.java`)
- JavaScript (`.js`)
- Julia (`.julia`, `.jl`)
- Kotlin (`.kotlin`, `.kt`, `.ktm`, `.kts`)
- Lisp (`.lisp`, `.lsp`, `.fasl`)
- Lua (`.lua`)
- Objective-C (`.m`)
- OPL (`.opl`, `.opa`)
- Pascal (`.pas`)
- Perl (`.perl`)
- PHP (`.php`)
- Python (`.py`)
- Ruby (`.rb`)
- Rust (`.rs`, `.rust`)
- Swift (`.swift`)
- TypeScript (`.typescript`, `.tsx`)
- Visual Basic Script (`.vbscript`, `.vbe`, `.vbs`, `.wsc`, `.wsf`)
- Vue.js (`.vue`)

### Shell Scripting

- Bash (`.sh`)
- C Shell (`.csh`)
- Korn Shell (`.ksh`)
- TCSH (`.tsch`)
- Z Shell (`.zsh`)

### Assembly

- ARM Assembler (`.s`)
- x86-64 Assembler (`.asm`, `.nasm`)

### Others

- AsciiDoc (`.asciidoc`, `.adoc`, `.asc`)
- Config files (`.conf`, `.cf`, `.cfg`, `.ini`, `.rc`)
- Cmake files (`.cmake`)
- CSS (`.css`)
- DxO PhotoLab sidecar (`.dop`)
- Environment (`.env`)
- Extensible Markup Platform (`.xmp`)
- LaTex (`.latex`, `.tex`)
- Makefiles (`makefile`)
- Apple Property list files (`.plist`)
- Apple Entitlements files (`.entitlements`)
- Apple Xcode NIB files (`.xib`)
- Apple Xcode storyboard files (`.storyboard`)
- Apple Xcode strings files (`.strings`)
- Protobuf (`.proto`)
- SASS/SCSS (`.scss`, `.sass`)
- SQL script (`.sql`)
- Terraform source file (`.tf`, `.terraform`)
- Terraform variable file (`.tfvars`)
- Translation Memory eXchange (`.tmx`)
- Twig (`.twig`)
- XML Localization Interchange File Format (`.xlf`, `.xliff`)

## Known Issues ##

1. *PreviewCode* will not render TypeScript `.ts` files. This is because the `.ts` file extension is pre-set on macOS to MPEG-2 transport stream video files. The `.tsx` and `.typescript` extensions are supported. We are actively investigating solutions to this problem.
1. *PreviewCode* will not render Clojure `.edn` files. This is because the `.edn` file extension is pre-set on macOS to an Adobe digital rights management product.
1. *PreviewCode* will not render Elixir `.exs` files if *GarageBand* and/or *Logic Pro* is installed on your Mac. This is because these apps use this file extension for EXS24 instrument files.
1. Previews displayed on external displays, or on Macs with connected to multiple monitors, may intermittently not be scrollable if you’re using a third-party mouse. Workaround: a MacBook’s built-in trackpad will be able to scroll.
1. Deselecting code in the preview is not immediate: the highlight clears after ~1s. We are investigating fixes.

## Source Code

This repository contains the primary source code for *PreviewCode*. Certain graphical assets, code components and data files are not included. To build *PreviewCode* from scratch, you will need to add these files yourself or remove them from your fork.

The files `REPLACE_WITH_YOUR_FUNCTIONS` and `REPLACE_WITH_YOUR_CODES` must be replaced with your own files. The former will contain your `sendFeedback(_ feedback: String) -> URLSessionTask?` function. The latter your Developer Team ID, used as the App Suite identifier prefix.

You will need to generate your own `Assets.xcassets` file containing the app icon, `app_logo.png` and theme screenshots.

You will need to create your own `new` directory containing your own `new.html` file.

## Acknowledgements

*PreviewCode* makes use of [HighlighterSwift](https://github.com/smittytone/HighlighterSwift) which provides a Swift wrapper for [Highlight.js](https://github.com/highlightjs/highlight.js) and is derived from [Highlightr](https://github.com/raspu/Highlightr).

## Release Notes ##

Please see the [CHANGELOG](./CHANGELOG.md)

## Copyright and Credits ##

Primary app code and UI design &copy; 2025, Tony Smith.

Code portions &copy; 2016 Juan Pablo Illanes.<br />Code portions &copy; 2006-25, Josh Goebel and Other Contributors
