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
import Highlighter


// MARK:- Global Properties

// Use defaults for some user-selectable values
private var theme: String = BUFFOON_CONSTANTS.DEFAULT_THEME
private var themeBackgroundColor: NSColor = NSColor.black
private var isThemeDark: Bool = false

private var font: NSFont = NSFont.init(name: fontName, size: fontSize)!
private var fontSize: CGFloat = CGFloat(BUFFOON_CONSTANTS.THEME_PREVIEW_FONT_SIZE)
private var fontName: String = BUFFOON_CONSTANTS.DEFAULT_FONT

private var appSuiteName: String = MNU_SECRETS.PID + BUFFOON_CONSTANTS.SUITE_NAME
private var errAtts: [NSAttributedString.Key: Any] = [
    .foregroundColor: NSColor.red,
    .font: font
]


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
    
    if let highlightr: Highlighter = Highlighter.init() {
        highlightr.setTheme(theme)
        highlightr.theme.setCodeFont(font)
        renderedString = highlightr.highlight(codeFileString, as: language)
    }
    
    // If the rendered string is good, return it
    if let rs: NSAttributedString = renderedString {
        // Trap any incorrectly parsed language names
        if (rs.string != "undefined") {
            return rs
        }
    }
    
    // Return an error message
    return NSAttributedString.init(string: "Could not render source code (\(language))", attributes: errAtts)
}


// MARK:- Formatting Functions

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
    theme = themeParts[1]
    isThemeDark = (themeParts[0] == "dark")

    // Set the background colour here
    if let highlightr: Highlighter = Highlighter.init() {
        highlightr.setTheme(theme)
        themeBackgroundColor = highlightr.theme.themeBackgroundColour
    }
}


/**
 Set common base style values for the source code render.
 
 **NOTE** This should now be called only ONCE, before the code is rendered
          to avoid threading race conditions.
 
 - Parameters:
    - isThumbnail:    Are we rendering a thumbnail (`true`) or a preview (`false`).
 */
func setBaseValues(_ isThumbnail: Bool) {

    // The suite name is the app group name, set in each extension's entitlements, and the host app's
    if let defaults = UserDefaults(suiteName: appSuiteName) {
        // Read back the theme and typeface prefs
        defaults.synchronize()
        fontName = defaults.string(forKey: "com-bps-previewcode-base-font-name") ?? BUFFOON_CONSTANTS.DEFAULT_FONT
        
        // No need to run the following for thumbnails - we set these manually
        if !isThumbnail {
            fontSize = CGFloat(defaults.float(forKey: "com-bps-previewcode-base-font-size"))
            
            // NOTE We store the raw theme name, so 'setThemeValues()' is called
            //      to extract the actual name and its mode (light or dark)
            setThemeValues(defaults.string(forKey: "com-bps-previewcode-theme-name") ?? BUFFOON_CONSTANTS.DEFAULT_THEME)
        }
    }

    // Choose a specific theme values for thumbnails
    if isThumbnail {
        theme = "atom-one-light"
        isThemeDark = false
        fontSize = CGFloat(BUFFOON_CONSTANTS.BASE_THUMBNAIL_FONT_SIZE)
    } else {
        // Just in case the above block reads in zero value for the preview font size
        if fontSize < BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS[0] ||
            fontSize > BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS[BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS.count - 1] {
            fontSize = CGFloat(BUFFOON_CONSTANTS.BASE_PREVIEW_FONT_SIZE)
        }
    }

    // Generate the font we'll use, at the required size
    if let chosenFont: NSFont = NSFont.init(name: fontName, size: fontSize) {
        font = chosenFont
    } else {
        font = NSFont.systemFont(ofSize: fontSize)
    }
    
    // Set the error format attributes to the font chosen by the user
    errAtts = [
        .foregroundColor: NSColor.red,
        .font: font
    ]
}


// MARK: - Utility Functions

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
        // NOTE '.typeIdentifier' yields an optional
        if let uti = try sourceFileURL.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
            sourceFileUTI = uti
        }
    } catch {
        // NOP
    }
    
    return sourceFileUTI
}


/**
 Generate an NSError for an internal error, specified by its code.
 
 Codes are listed in `Constants.swift`
 
 - Parameters:
    - code: The internal error code.
 
 - Returns: The described error as an NSError.
 */
func setError(_ code: Int) -> NSError {
    
    var errDesc: String
    
    switch(code) {
    case BUFFOON_CONSTANTS.ERRORS.CODES.FILE_INACCESSIBLE:
        errDesc = BUFFOON_CONSTANTS.ERRORS.MESSAGES.FILE_INACCESSIBLE
    case BUFFOON_CONSTANTS.ERRORS.CODES.FILE_WONT_OPEN:
        errDesc = BUFFOON_CONSTANTS.ERRORS.MESSAGES.FILE_WONT_OPEN
    case BUFFOON_CONSTANTS.ERRORS.CODES.BAD_TS_STRING:
        errDesc = BUFFOON_CONSTANTS.ERRORS.MESSAGES.BAD_TS_STRING
    case BUFFOON_CONSTANTS.ERRORS.CODES.BAD_MD_STRING:
        errDesc = BUFFOON_CONSTANTS.ERRORS.MESSAGES.BAD_MD_STRING
    default:
        errDesc = "UNKNOWN ERROR"
    }

    let bundleID = Bundle.main.object(forInfoDictionaryKey: "CFBundleID") as! String
    return NSError(domain: bundleID,
                   code: code,
                   userInfo: [NSLocalizedDescriptionKey: errDesc])
}


// MARK:- Threading-friendly Property Getters
/**
 Thread-friendly getter for the theme mode. May not be necessary.
 
 - Returns: Whether the theme is dark (`true`) or light (`false`).
 */
func getMode() -> Bool {
    
    // Simple getter
    
    return isThemeDark
}


/**
 Thread-friendly getter for the theme background colour. May not be necessary.
 
 - Returns: The theme background colour as an NSColor.
 */
func getBackgroundColour() -> NSColor {
    
    // Simple getter

    return themeBackgroundColor
}
