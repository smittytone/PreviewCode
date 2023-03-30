# PreviewCode 1.3.0

*PreviewCode* provides macOS QuickLook file previews and Finder icon thumbnails for more than 50 programming and scripting languages, header files, and data files.

It is not exhaustive, nor is it intended to be. It is, however, intended to support [the most popular languages](#languages) used by Mac-based developers, whether for use on a Mac or on other platforms.

![PreviewCode App Store QR code](qr-code.jpg)

## Installation and Usage ##

Just run the host app once to register the extensions &mdash; you can quit the app as soon as it has launched. We recommend logging out of your Mac and back in again at this point. Now you can preview source code files using QuickLook (select an icon and hit Space), and Finder’s preview pane and **Info** panels.

You can disable and re-enable the Code Previewer and Code Thumbnailer extensions at any time in **System Preferences > Extensions > Quick Look**.

### Adjusting the Preview

Open the main app and click on **Show Preview Preferences**, or select **Preferences...** from the **PreviewCode** menu.

You can select from a range of text sizes, choose a monospace font, select the font’s style — regular, bold, italic, etc. — and pick which theme you would like previews to use. One hundred themes are included, and you can view all of them, or just dark or light ones.

*PreviewCode* will use your selected theme whether your Mac is set to light or dark mode. It will not adapt according to your system setting, but we may add support for this in a future release.

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
- Pascal (`.pas`)
- Perl (`.perl`)
- PHP (`.php`)
- Python (`.py`)
- Ruby (`.rb`)
- Rust (`.rs`, `.rust`)
- Swift (`.swift`)
- TypeScript (`.typescript`, `.tsx`, `.ts`)
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
- Enviroment (`.env`)
- LaTex (`.latex`, `.tex`)
- Makefiles (`makefile`)
- Apple Property list files (`.plist`)
- Apple Entitlements files (`.entitlements`) 
- Apple Xcode NIB files (`.xib`) 
- Apple Xcode storyboard files (`.storyboard`) 
- Protobuf (`.proto`)
- SASS/SCSS (`.scss`, `.sass`)
- SQL script (`.sql`)
- Terraform source file (`.tf`, `.terraform`)
- Terraform variable file (`.tfvars`)
- Twig (`.twig`)

## Known Issues ##

- *PreviewCode* will not render Clojure `.edn` files. This is because the `.edn` file extension is pre-set on macOS to an Adobe digital rights management product.
- *PreviewCode* will not render TypeScript `.ts` files. This is because the `.ts` file extension is pre-set on macOS to MPEG-2 transport stream video files.
- *PreviewCode* will not render Elixir `.exs` files if GarageBand and/or Logic Pro is installed on your Mac. This is because these apps use this file extension for EXS24 instrument files.
- Previews displayed on external displays, or on Macs with connected to multiple monitors, may intermittently not be scrollable if you’re using a third-party mouse. Workaround: a MacBook’s built-in trackpad will be able to scroll.

## Source Code ##

This repository contains the primary source code for *PreviewCode*. Certain graphical assets and data files are not included. To build *PreviewCode* from scratch, you will need to add these files yourself or remove them from your fork.

## Acknowledgements

*PreviewCode* makes use of [HighlighterSwift](https://github.com/smittytone/HighlighterSwift) which provides a Swift wrapper for [Highlight.js](https://github.com/highlightjs/highlight.js) and is derived from [Highlightr](https://github.com/raspu/Highlightr).

## Release Notes ##

- 1.3.0 *Unreleased*
    - Support automatic dark/light theme application by macOS UI mode.
- 1.2.7 *Unreleased*
    - Support `.elm` Elm files.
    - Stop *PreviewCode* attempting to preview `.scpt` binary applescript files.
    - Under-the-hood improvements
- 1.2.6 *18 March 2023*
    - Allow text to be selected in previews.
    - Support `.gml` GML (GameMaker Language) files.
    - Support `.vue` Vue.js files.
    - Support `.entitlements`, `.xib`, `.storyboard` Xcode files.
    - Update to use HighlighterSwift 1.1.1.
- 1.2.5 *21 January 2023*
    - Add link to [PreviewText](https://smittytone.net/previewtext/index.html).
    - Better menu handling when panels are visible.
    - Better app exit management.
- 1.2.4 *14 December 2022*
    - Add `com.microsoft.c-sharp` UTI.
    - Support makefiles.
- 1.2.3 *2 October 2022*
    - Add link to [PreviewJson](https://smittytone.net/previewjson/index.html).
- 1.2.2 *26 August 2022*
    - Add `public.lua-script` UTI.
    - Support XML `.plist` files.
    - Initial support for non-utf8 source code file encodings.
- 1.2.1 *7 August 2022*
    - Support the `.cs` C# extension.
    - Fix ARM assembly file display.
    - Fix operation of Preferences’ font style popup.
- 1.2.0 *26 April 2022*
    - Update to use HighlighterSwift 1.1.0.
    - Support environment `.env` files.
    - Support CMake `.cmake` files.
    - Support Terraform variable `.tfvars` files.
    - Support AsciiDoc `.adoc`, `.asciidoc` and `.asc` files.
    - Support `.conf`, `.cf`, `.cfg`, `.ini` and `.rc` config files
    - Fix Haskell `.hsl` extension.
    - Fix x86 `.nasm` preview.
    - Change ActionScript supported extension to `.actionscript` to avoid clash with AppleSingle `.as`.
    - Remove Lisp `.cl` — clash with OpenCL source.
    - Remove Lisp `.l` — clash with Lex source.
    - Remove F# `.fs` — clash with OpenGL Fragment Shader source.
    - Remove Dylan `.dylan` and `.lid` extensions.
- 1.1.1 *19 November 2021*
    - Support HashiCorp Terraform `.tf` files.
    - Disable file-type thumbnail tags under macOS 12 Monterey to avoid clash with system-added tags.
- 1.1.0 *28 July 2021*
    - Improved font selection code.
    - Separate font style selection.
    - Accelerate loading of the **Preferences** panel, especially on Intel Macs.
    - Code streamlining.
    - Fixed a rare bug in the previewer error reporting code.
    - Apple wants links to other apps to be App Store links. So be it. What Apple wants, Apple gets.
- 1.0.0 *16 June 2021*
    - Initial public release.

## Copyright and Credits ##

Primary app code and UI design &copy; 2023, Tony Smith.

Code portions &copy; 2016 Juan Pablo Illanes.<br />Code portions &copy; 2006-22 Ivan Sagalaev.
