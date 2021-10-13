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
    var isThemeDark: Bool              = false
    var initError: Bool                = false


    // MARK:- Private Properties

    private var font: NSFont? = nil
    private var highlighter: Highlighter? = nil


    // MARK:- Lifecycle Functions

    init(_ isThumbnail: Bool) {

        super.init()

        // Set local values with default properties
        var themeName: String = BUFFOON_CONSTANTS.DEFAULT_THEME
        var themeString: String = BUFFOON_CONSTANTS.DEFAULT_THEME
        var fontName: String = BUFFOON_CONSTANTS.DEFAULT_FONT
        var fontSize: CGFloat = CGFloat(BUFFOON_CONSTANTS.THEME_PREVIEW_FONT_SIZE)

        // Read in the user preferences to update the above values
        if let prefs: UserDefaults = UserDefaults(suiteName: MNU_SECRETS.PID + BUFFOON_CONSTANTS.SUITE_NAME) {
            if !isThumbnail {
                fontSize = CGFloat(prefs.float(forKey: "com-bps-previewcode-base-font-size"))
                themeString = prefs.string(forKey: "com-bps-previewcode-theme-name") ?? BUFFOON_CONSTANTS.DEFAULT_THEME
            }

            fontName = prefs.string(forKey: "com-bps-previewcode-base-font-name") ?? BUFFOON_CONSTANTS.DEFAULT_FONT
        }

        // Set instance theme-related properties
        if isThumbnail {
            // Thumbnails use fixed, light-on-dark values
            themeName = setTheme(BUFFOON_CONSTANTS.DEFAULT_THUMB_THEME)
            fontSize = CGFloat(BUFFOON_CONSTANTS.BASE_THUMBNAIL_FONT_SIZE)
        } else {
            // Set preview theme details
            themeName = setTheme(themeString)

            // Just in case the above block reads in zero value for the preview font size
            if fontSize < BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS[0] ||
                fontSize > BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS[BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS.count - 1] {
                fontSize = CGFloat(BUFFOON_CONSTANTS.BASE_PREVIEW_FONT_SIZE)
            }
        }

        // Generate the font we'll use, at the required size
        if let chosenFont: NSFont = NSFont.init(name: fontName, size: fontSize) {
            self.font = chosenFont
        } else {
            self.font = NSFont.systemFont(ofSize: fontSize)
        }

        // Instantiate the instance's highlighter
        if let hr: Highlighter = Highlighter.init() {
            hr.setTheme(themeName)
            hr.theme.setCodeFont(self.font!)
            self.themeBackgroundColour = hr.theme.themeBackgroundColour
            self.highlighter = hr
        } else {
            // TODO Need a better notification for
            //      highlighter instantiation errors
            self.initError = true
        }
    }

    
    // MARK:- The Primary Function

    /**
    Use HightlightSwift to style the source code string.

    - Parameters:
        - codeFileString: The raw source code.
        - language:       The source code language, eg. `swift`.

    - Returns: The rendered source as an NSAttributedString.
    */
    func getAttributedString(_ codeFileString: String, _ language: String) -> NSAttributedString {

        // Run the specified code string through Highlightr/Highlight.js
        var renderedString: NSAttributedString? = nil

        if let hr: Highlighter = self.highlighter {
            renderedString = hr.highlight(codeFileString, as: language)
        }

        // If the rendered string is good, return it
        if let ras: NSAttributedString = renderedString {
            // Trap any incorrectly parsed language names
            if (ras.string != "undefined") {
                return ras
            }
        }

        // Return an error message
        let errorAtts: [NSAttributedString.Key : Any] = [
            .foregroundColor: NSColor.red,
            .font: self.font!
        ]

        return NSAttributedString.init(string: "Could not render source code in (\(language))",
                                       attributes: errorAtts)
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
    func updateTheme(_ themeData: String) {
        
        let themeName: String = setTheme(themeData)
        if let highlightr: Highlighter = self.highlighter {
            highlightr.setTheme(themeName)
            self.themeBackgroundColour = highlightr.theme.themeBackgroundColour
        }
    }


    /**
     Extract the theme name from the storage string.

     - Parameters:
        - themeString: The base theme record, eg. `light.atom-one-light`.

     - Returns: The name of the theme's filem, eg. `atom-one-light`.
     */
    private func setTheme(_ themeString: String) -> String {

        var themeParts: [String] = themeString.components(separatedBy: ".")

        // Just in case...
        if themeParts.count != 2 {
            themeParts = ["dark", "agate"]
        }

        self.isThemeDark = (themeParts[0] == "dark")
        return themeParts[1]
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
            if sourceFileExtension == "s" { sourceLanguage = isForTag ? "ARM" : "armasm" }
            if sourceFileExtension == "asm" { sourceLanguage = isForTag ? "x86-64" : "x86asm" }
        case "nasm-assembly":
            sourceLanguage = isForTag ? "x86-64" : "x86asm"
        case "6809-assembly":
            sourceLanguage = isForTag ? "6809" : "x86asm"
        case "latex":
            if !isForTag { sourceLanguage = "tex" }
        case "csharp":
            if isForTag { sourceLanguage = "c#" }
        case "fsharp":
            if isForTag { sourceLanguage = "f#" }
        case "brainfuck":
            if isForTag { sourceLanguage = "brainf**k" }
        case "terraform":
            if !isForTag { sourceLanguage = "c" }
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
