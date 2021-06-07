# PreviewCode 1.0.0

*PreviewCode* provides macOS QuickLook file previews and Finder icon thumbnails for a wide variety of programming and scripting languages, and data files.

It is not exhaustive, nor is it intended to be. It is intended to support [the most popular languages](#languages) used by Mac-based developers, whether for use on a Mac or on other platforms.

## Installation and Usage ##

Just run the host app once to register the extensions &mdash; you can quit the app as soon as it has launched. We recommend logging out of your Mac and back in again at this point. Now you can preview source code files using QuickLook (select an icon and hit Space), and Finder’s preview pane and **Info** panels.

You can disable and re-enable the Code Previewer and Code Thumbnailer extensions at any time in **System Preferences > Extensions > Quick Look**.

### Adjusting the Preview

Open the main app and click on **Show Preview Preferences**, or select **Preferences...** from the **PreviewCode** menu.

You will now be able to select from a range of text sizes, choose a monospace font, and pick which theme you would like previews to use.

*PreviewCode* will use your selected theme whether your Mac is set to light or dark mode. It will not adapt according to your system setting, but we made add support for this in a future release.

## Languages

### Compiled Languages

* Swift (`.swift`)
* C (`.c`, `.h`)
* C++ (`.cpp`, `.hpp`)
* Objective-C (`.m`)
* C# (`.csx`)
* Rust (`.rs`)
* Go (`.go`)
* Arduino (`.ino`)
* Ada (`.ads`, `.adb`)
* Pascal (`.pas`)
* Fortran (`.for`)

### Interpreted Languages

* Python (`.py`)
* JavaScript (`.js`)
* TypeScript (`.tsx`)
* AppleScript (`.applescript`)
* CoffeeScript (`.coffee`)
* Lua (`.lua`)
* Java (`.java`)
* PHP (`.php`)
* Perl (`.perl`)
* Ruby (`.rb`)
* Visual Basic Script (`.vbs`)
* Clojure (`.clj`, `.cljs`, `.cljc`, `.edn`)
* Erlang (`.erl`, `.hrl`)

### Shell Scripting

* Bash (`.sh`)
* Z Shell (`.zsh`)
* C Shell (`.csh`)
* Korn Shell (`.ksh`)
* TCSH (`.tsch`)

### Misc

* SQL script (`.sql`)
* ARM Assembler (`.s`)
* x86-64 Assembler (`.asm`)

## Data

* Protobuf (`.proto`)
* SASS/SCSS (`.scss`, `.sass`)
* CSS (`.css`)

## Source Code ##

This repository contains the primary source code for *PreviewCode*. Certain graphical assets and data files are not included. To build *PreviewCode* from scratch, you will need to add these files yourself or remove them from your fork.

## Acknowledgements

*PreviewCode* makes use of [Highlightr]() which provides a Swift wrapper for [Highlight.js]().

## Release Notes ##

* 1.0.0 *Unreleased*
    * Initial public release.

## Copyright and Credits ##

Primary app code and UI design &copy; 2021, Tony Smith.

Code portions &copy; 2016 Juan Pablo Illanes. Code portions &copy; 2006 Ivan Sagalaev.





## Todo

public.precompiled-c-header, .pch
com.bps.gradle-source, .gradle
com.bps.basic-source, .bas
com.bps.twig-source., .twig
com.bps.actionscript-source, .???
com.bps.brainfuck-source, .???
com.bps.dart-source, .???
com.bps.delphi-source, .???
com.bps.elixir-source, .???
com.bps.fsharp-source, .???
com.bps.haskell-source, .???
com.bps.julia-source. ,???
lisp
kotlin - may have UTI
dockerfile - may have UTI
smalltalk