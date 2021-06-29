# PreviewCode 1.0.1

*PreviewCode* provides macOS QuickLook file previews and Finder icon thumbnails for more than 50 programming and scripting languages, header files, and data files.

It is not exhaustive, nor is it intended to be. It is, however, intended to support [the most popular languages](#languages) used by Mac-based developers, whether for use on a Mac or on other platforms.

![PreviewCode App Store QR code](qr-code.jpg)

## Installation and Usage ##

Just run the host app once to register the extensions &mdash; you can quit the app as soon as it has launched. We recommend logging out of your Mac and back in again at this point. Now you can preview source code files using QuickLook (select an icon and hit Space), and Finder’s preview pane and **Info** panels.

You can disable and re-enable the Code Previewer and Code Thumbnailer extensions at any time in **System Preferences > Extensions > Quick Look**.

### Adjusting the Preview

Open the main app and click on **Show Preview Preferences**, or select **Preferences...** from the **PreviewCode** menu.

You will now be able to select from a range of text sizes, choose a monospace font, and pick which theme you would like previews to use. One hundred themes are included.

*PreviewCode* will use your selected theme whether your Mac is set to light or dark mode. It will not adapt according to your system setting, but we made add support for this in a future release.

## Languages

### Compiled Languages

* ActionScript (`.as`)
* Ada (`.ads`, `.adb`)
* AppleScript (`.applescript`)
* Arduino (`.ino`)
* Basic (`.bas`)
* Brainfuck (`.b`, `.bf`)
* C (`.c`, `.h`)
* C++ (`.cpp`, `.hpp`)
* C# (`.csx`)
* Clojure (`.clj`, `.cljs`, `.cljc`, `.edn`)
* CoffeeScript (`.coffee`)
* Dart (`.dart`)
* Dylan (`.dylan`, `.lid`)
* Elixir (`.ex`, `.exs`)
* Erlang (`.erl`, `.hrl`)
* Fortran (`.for`)
* F# (`.fs`, `.fsx`, `.fsi`, `.fsscript`)
* Go (`.go`)
* Haskell (`.hs`, `.lhs`)
* Java (`.java`)
* JavaScript (`.js`)
* Julia (`.jl`)
* Kotlin (`.kt`, `.kts`, `.ktm`)
* Lisp (`.lisp`, `.lsp`, `.l`, `.cl`, `.fasl`)
* Lua (`.lua`)
* Objective-C (`.m`)
* Pascal (`.pas`)
* Perl (`.perl`)
* PHP (`.php`)
* Python (`.py`)
* Ruby (`.rb`)
* Rust (`.rs`)
* Swift (`.swift`)
* TypeScript (`.tsx`)
* Visual Basic Script (`.vbs`)

### Shell Scripting

* Bash (`.sh`)
* C Shell (`.csh`)
* Korn Shell (`.ksh`)
* TCSH (`.tsch`)
* Z Shell (`.zsh`)

### Assembly

* ARM Assembler (`.s`)
* x86-64 Assembler (`.asm`, `.nasm`)

### Others

* CSS (`.css`)
* LaTex (`.tex`)
* Protobuf (`.proto`)
* SASS/SCSS (`.scss`, `.sass`)
* SQL script (`.sql`)
* Twig (`.twig`)

## Source Code ##

This repository contains the primary source code for *PreviewCode*. Certain graphical assets and data files are not included. To build *PreviewCode* from scratch, you will need to add these files yourself or remove them from your fork.

## Acknowledgements

*PreviewCode* makes use of [HighlightSwift](https://github.com/smittytone/HighlightSwift) which provides a Swift wrapper for [Highlight.js](https://github.com/highlightjs/highlight.js) and is derived from [Highlightr](https://github.com/raspu/Highlightr).

## Release Notes ##

* 1.0.0 *Unreleased*
    * Improved font selection code.
    * Speed **Preferences** panel loading.
    * Apple wants links to other apps to be App Store links. What Apple wants, Apple gets.
* 1.0.0 *16 June 2021*
    * Initial public release.

## Copyright and Credits ##

Primary app code and UI design &copy; 2021, Tony Smith.

Code portions &copy; 2016 Juan Pablo Illanes.<br />Code portions &copy; 2006-21 Ivan Sagalaev.