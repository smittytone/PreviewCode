/*
 *  Common.swift
 *  PreviewCode
 *  Code common to Code Previewer and Code Thumbnailer
 *
 *  Created by Tony Smith on 30/05/2021.
 *  Copyright © 2021 Tony Smith. All rights reserved.
 */


import Foundation
import AppKit
import UniformTypeIdentifiers
import Highlighter


// FROM 1.1.0
// Implement as a class
final class Common: NSObject {

    // MARK:- Public Properties

    var themeBackgroundColour: NSColor = NSColor.white
    var isThemeDark: Bool = false

    // MARK:- Private Properties

    private var themeName: String = BUFFOON_CONSTANTS.DEFAULT_THEME
    private var font: NSFont? = nil
    private var fontSize: CGFloat = CGFloat(BUFFOON_CONSTANTS.THEME_PREVIEW_FONT_SIZE)
    private var fontName: String = BUFFOON_CONSTANTS.DEFAULT_FONT
    private var errorAtts: [NSAttributedString.Key: Any] = [:]
    private var highlighter: Highlighter? = nil
    
    private let appSuiteName: String = MNU_SECRETS.PID + BUFFOON_CONSTANTS.SUITE_NAME
    


    // MARK:- Lifecycle Functions

    init(_ isThumbnail: Bool) {

        super.init()

        var themeString: String = BUFFOON_CONSTANTS.DEFAULT_THEME

        if let defaults: UserDefaults = UserDefaults(suiteName: self.appSuiteName) {
            defaults.synchronize()
            self.fontName = defaults.string(forKey: "com-bps-previewcode-base-font-name") ?? BUFFOON_CONSTANTS.DEFAULT_FONT

            if !isThumbnail {
                self.fontSize = CGFloat(defaults.float(forKey: "com-bps-previewcode-base-font-size"))

                // NOTE We store the raw theme name, so 'setThemeValues()' is called
                //      to extract the actual name and its mode (light or dark)
                themeString = defaults.string(forKey: "com-bps-previewcode-theme-name") ?? BUFFOON_CONSTANTS.DEFAULT_THEME
            }
        }

        // Choose a specific theme values for thumbnails
        if isThumbnail {
            self.themeName = "atom-one-light"
            self.isThemeDark = false
            self.fontSize = CGFloat(BUFFOON_CONSTANTS.BASE_THUMBNAIL_FONT_SIZE)
        } else {
            let themeParts: [String] = themeString.components(separatedBy: ".")
            self.themeName = themeParts[1]
            self.isThemeDark = (themeParts[0] == "dark")

            // Just in case the above block reads in zero value for the preview font size
            if self.fontSize < BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS[0] ||
                self.fontSize > BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS[BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS.count - 1] {
                self.fontSize = CGFloat(BUFFOON_CONSTANTS.BASE_PREVIEW_FONT_SIZE)
            }
        }

        // Generate the font we'll use, at the required size
        if let chosenFont: NSFont = NSFont.init(name: self.fontName, size: self.fontSize) {
            self.font = chosenFont
        } else {
            self.font = NSFont.systemFont(ofSize: self.fontSize)
        }

        // Set the error format attributes to the font chosen by the user
        self.errorAtts = [
            .foregroundColor: NSColor.red,
            .font: self.font!
        ]

        // Set the background colour here
        if let highlightr: Highlighter = Highlighter.init() {
            self.highlighter = highlightr
            self.highlighter!.setTheme(self.themeName)
            self.highlighter!.theme.setCodeFont(self.font!)
            self.themeBackgroundColour = self.highlighter!.theme.themeBackgroundColour
        }
    }

    
    // MARK:- The Primary Function

    /**
    Use HightlightSwift to style the source code string.

    - Parameters:
        - codeFileString: The raw source code.
        - language:       The source code language, eg. `swift`.
        - isThumbnail:    Are we rendering a thumbnail (`true`) or a preview (`false`).

    - Returns: The rendered source as an NSAttributedString.
    */
    func getAttributedString(_ codeFileString: String, _ language: String, _ isThumbnail: Bool) -> NSAttributedString {

        // Run the specified code string through Highlightr/Highlight.js
        var renderedString: NSAttributedString? = nil

        if let highlightr: Highlighter = self.highlighter {
            renderedString = highlightr.highlight(codeFileString, as: language)
        }

        // If the rendered string is good, return it
        if let ras: NSAttributedString = renderedString {
            // Trap any incorrectly parsed language names
            if (ras.string != "undefined") {
                return ras
            }
        }

        // Return an error message
        return NSAttributedString.init(string: "Could not render source code (\(language))",
                                       attributes: self.errorAtts)
    }


    // MARK: - Utility Functions

    /**
     Set key theme parameters.
     
     We record in prefs a string combinining the theme's Highlight.js name and
     its 'mode' (light or dark), so we need to call this function at some
     point to extract these two data points.
     
     **NOTE** This should now be called only **once**, before the code is rendered
          to avoid threading race conditions. This is called by `setBaseValues()`
          and `AppDelegate` (frequently, once for each theme).
     
     - Parameters:
        - themeData: The PreviewCode theme info string, eg. `dark.an-old-hope`.
     */
    func setThemeValues(_ themeData: String) {
        
        let themeParts: [String] = themeData.components(separatedBy: ".")
        self.themeName = themeParts[1]
        self.isThemeDark = (themeParts[0] == "dark")

        // Set the background colour here
        if let highlightr: Highlighter = self.highlighter {
            highlightr.setTheme(self.themeName)
            self.themeBackgroundColour = highlightr.theme.themeBackgroundColour
        }
    }

    /**
    Determine the source file's language from its UTI.

    For example, `public.swift-source` -> `swift`.

    If `isForTag` is `true`, it returns the actual name of the language,
    not the naming used by Highlight.js, which it returns if `isForTag`
    is `false`. This is because these are not always the same,
    eg. `c++` vs `cpp`, `pascal` vs `delphi`.

    - Parameters:
        - sourceFilePath: The path to the source code file.
        - isForTag:       Are we rendering a thumbnail tag (`true`) or not (`false`).

    - Returns: The source code's language.
    */
    func getLanguage(_ sourceFilePath: String, _ isForTag: Bool) -> String {

        let sourceFileUTI: String = getSourceFileUTI(sourceFilePath)
        let sourceFileExtension: String = (sourceFilePath as NSString).pathExtension

        // Trap 'non-standard' UTIs
        if sourceFileUTI.hasPrefix("com.apple.applescript") {
            return "applescript"
        }

        if sourceFileUTI == "public.script" {
            return "bash"
        }

        if sourceFileUTI == "public.css" {
            return "css"
        }

        var sourceLanguage: String = BUFFOON_CONSTANTS.DEFAULT_LANGUAGE_UTI
        let parts = sourceFileUTI.components(separatedBy: ".")
        if parts.count > 0 {
            let index: Int = parts.count - 1
            var endIndex: Range<String.Index>? = parts[index].range(of: "-source")
            if endIndex == nil { endIndex = parts[index].range(of: "-header") }
            if endIndex == nil { endIndex = parts[index].range(of: "-script") }

            if let anEndIndex = endIndex {
                sourceLanguage = String(parts[index][..<anEndIndex.lowerBound])
            }
        }

        // Address those languages that are referenced slightly differently
        // in highlight.js, eg. 'objective-c' -> 'objectivec'; are accessed
        // as aliases, eg. 'pascal' -> 'delphi'; or all use the same language,
        // eg. all shells -> 'bash'
        switch(sourceLanguage) {
        case "objective-c":
            sourceLanguage = isForTag ? "obj-c" : "objectivec"
        case "objective-c-plus-plus":
            sourceLanguage = isForTag ? "obj-c++" : "objectivec"
        case "c-plus-plus":
            sourceLanguage = isForTag ? "c++" : "cpp"
        case "shell", "zsh", "csh", "ksh", "tsch":
            if !isForTag { sourceLanguage = "bash" }
        case "pascal":
            if !isForTag { sourceLanguage = "delphi" }
        case "assembly":
            if sourceFileExtension == "s" { sourceLanguage = isForTag ? "arm" : "armasm" }
            if sourceFileExtension == "asm" { sourceLanguage = isForTag ? "x86-64" : "x86asm" }
        case "nasm-assembly":
            sourceLanguage = isForTag ? "x86-64" : "x86asm"
        case "latex":
            if !isForTag { sourceLanguage = "tex" }
        case "csharp":
            if isForTag { sourceLanguage = "c#" }
        case "fsharp":
            if isForTag { sourceLanguage = "f#" }
        case "brainfuck":
            if isForTag { sourceLanguage = "brainf**k" }
        default:
            // NOP
            break
        }

        return sourceLanguage
    }


    /**
    Get the supplied source file's UTI.

    We'll use it to determine the file's programming language.

    - Parameters:
        - sourceFilePath: The path to the source code file.

    - Returns: The source code's UTI.
    */
    func getSourceFileUTI(_ sourceFilePath: String) -> String {

        // Create a URL reference to the sample file
        var sourceFileUTI: String = ""
        let sourceFileURL = URL.init(fileURLWithPath: sourceFilePath)

        do {
            // Read back the UTI from the URL
            // Use Big Sur's UTType API
            if #available(macOS 11, *) {
                if let uti: UTType = try sourceFileURL.resourceValues(forKeys: [.contentTypeKey]).contentType {
                    sourceFileUTI = uti.identifier
                }
            } else {
                // NOTE '.typeIdentifier' yields an optional
                if let uti: String = try sourceFileURL.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
                    sourceFileUTI = uti
                }
            }
        } catch {
            // NOP
        }

        return sourceFileUTI
    }

}
