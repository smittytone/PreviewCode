/*
 *  Common.swift
 *  PreviewYaml
 *  Code common to Yaml Previewer and Yaml Thumbnailer
 *
 *  Created by Tony Smith on 22/04/2021.
 *  Copyright © 2021 Tony Smith. All rights reserved.
 */

import Foundation
import Yaml
import AppKit



// Use defaults for some user-selectable values
private var codeColourIndex: Int = BUFFOON_CONSTANTS.CODE_COLOUR_INDEX
private var codeFontIndex: Int = BUFFOON_CONSTANTS.CODE_FONT_INDEX
private var fontBaseSize: CGFloat = CGFloat(BUFFOON_CONSTANTS.BASE_PREVIEW_FONT_SIZE)
private var yamlIndent: Int = BUFFOON_CONSTANTS.YAML_INDENT
private var doShowLightBackground: Bool = false
private var doShowRawYaml: Bool = false
private var doIndentScalars: Bool = false
private let codeFonts: [String] = ["Helvetica", "ArialMT", "Helvetica", "HelveticaNeue",
                                   "LucidaGrande", "Times-Roman", "Verdana", "AndaleMono",
                                   "Courier", "Menlo-Regular", "Monaco", "PTMono-Regular"]

// YAML string attributes...
private var keyAtts: [NSAttributedString.Key: Any] = [
    .foregroundColor: getColour(codeColourIndex),
    .font: NSFont.systemFont(ofSize: fontBaseSize)
]

private var valAtts: [NSAttributedString.Key: Any] = [
    .foregroundColor: (doShowLightBackground ? NSColor.black : NSColor.labelColor),
    .font: NSFont.systemFont(ofSize: fontBaseSize)
]

// String artefacts...
private var hr = NSAttributedString(string: "\n\u{00A0}\u{0009}\u{00A0}\n\n",
                                    attributes: [.strikethroughStyle: NSUnderlineStyle.patternDot.rawValue,
                                                 .strikethroughColor: NSColor.labelColor])
private var newLine: NSAttributedString = NSAttributedString.init(string: "\n", attributes: valAtts)


// MARK: Primary Function

func getAttributedString(_ yamlFileString: String, _ isThumbnail: Bool) -> NSAttributedString {

    // Use YamlSwift to render the input YAML as an NSAttributedString, which is returned.
    // NOTE Set the font colour according to whether we're rendering a thumbail or a preview
    //      (thumbnails always rendered black on white; previews may be the opposite [dark mode])

    // Set up the base string
    var renderedString: NSMutableAttributedString = NSMutableAttributedString.init(string: "",
                                                                                   attributes: valAtts)
    
    do {
        // Parse the YAML data,
        // first fixing any .NAN, +/-.INF in the file
        // let processed = fixNan(yamlFileString)
        let yaml = try Yaml.loadMultiple(yamlFileString)
        
        // Render the YAML to NSAttributedString
        for i in 0..<yaml.count {
            if let yamlString = renderYaml(yaml[i], 0, false) {
                if i > 0 {
                    renderedString.append(hr)
                }
                renderedString.append(yamlString)
            }
        }
        
        // Just in case...
        if renderedString.length == 0 {
            renderedString = NSMutableAttributedString.init(string: "Could not render the YAML.\n", attributes: keyAtts)
        }
    } catch {
        // No YAML to render, or the YAML was mis-formatted
        // Get the error as reported by YamlSwift
        let yamlErr: Yaml.ResultError = error as! Yaml.ResultError
        var yamlErrString: String
        switch(yamlErr) {
            case .message(let s):
                yamlErrString = s ?? "unknown"
        }

        // Assemble the error string
        let errorString: NSMutableAttributedString = NSMutableAttributedString.init(string: "Could not render the YAML. Error: " + yamlErrString,
                                                                                    attributes: keyAtts)

        // Should we include the raw text?
        // At least the user can see the data this way
        if doShowRawYaml {
            errorString.append(hr)
            errorString.append(NSMutableAttributedString.init(string: yamlFileString + "\n",
                                                              attributes: valAtts))
        }

        renderedString = errorString
    }
    
    return renderedString as NSAttributedString
}


// MARK: Yaml Functions

func renderYaml(_ part: Yaml, _ indent: Int, _ isKey: Bool) -> NSAttributedString? {
    
    // Render a supplied YAML sub-component ('part') to an NSAttributedString,
    // indenting as required, and using a different text format for keys.
    // This is called recursively as it drills down through YAML values.
    // Returns nil on error
    
    // Set up the base string
    let returnString: NSMutableAttributedString = NSMutableAttributedString.init(string: "", attributes: valAtts)
    
    switch (part) {
    case .array:
        if let value = part.array {
            // Iterate through array elements
            // NOTE A given element can be of any YAML type
            for i in 0..<value.count {
                if let yamlString = renderYaml(value[i], indent, false) {
                    // Apply a prefix to separate array and dictionary elements from a
                    // previous one -- so apply to all but the first item
                    if i > 0 && (value[i].array != nil || value[i].dictionary != nil) {
                        returnString.append(newLine)
                    }
                    
                    // Add the element itself
                    returnString.append(yamlString)
                }
            }
            
            return returnString
        }
    case .dictionary:
        if let dict = part.dictionary {
            // Iterate through the dictionary's keys and their values
            // NOTE A given value can be of any YAML type
            
            // Sort the dictionary's keys (ascending)
            // We assume all keys will be strings, ints, doubles or bools
            var keys: [Yaml] = Array(dict.keys)
            keys = keys.sorted(by: { (a, b) -> Bool in
                // Strings?
                if let a_s: String = a.string {
                    if let b_s: String = b.string {
                        return (a_s.lowercased() < b_s.lowercased())
                    }
                }
                
                // Ints?
                if let a_i: Int = a.int {
                    if let b_i: Int = b.int {
                        return (a_i < b_i)
                    }
                }
                
                // Doubles?
                if let a_d: Double = a.double {
                    if let b_d: Double = b.double {
                        return (a_d < b_d)
                    }
                }
                
                // Bools
                if let a_b: Bool = a.bool {
                    if let b_b: Bool = b.bool {
                        return (a_b && !b_b)
                    }
                }
                
                return false
            })
            
            // Iterate through the sorted keys array
            for i in 0..<keys.count {
                // Prefix root-level key:value pairs after the first with a new line
                if indent == 0 && i > 0 {
                    returnString.append(newLine)
                }
                
                // Get the key:value pairs
                let key: Yaml = keys[i]
                let value: Yaml = dict[key] ?? ""
                
                // Render the key
                if let yamlString = renderYaml(key, indent, true) {
                    returnString.append(yamlString)
                }
                
                // If the value is a collection, we drop to the next line and indent
                var valueIndent: Int = 0
                if value.array != nil || value.dictionary != nil || doIndentScalars {
                    valueIndent = indent + yamlIndent
                    returnString.append(newLine)
                }
                
                // Render the key's value
                if let yamlString = renderYaml(value, valueIndent, false) {
                    returnString.append(yamlString)
                }
            }
            
            return returnString
        }
    case .string:
        if let keyOrValue = part.string {
            returnString.append(getIndentedString(keyOrValue, indent))
            returnString.setAttributes((isKey ? keyAtts : valAtts),
                                       range: NSMakeRange(0, returnString.length))
            returnString.append(isKey ? NSAttributedString.init(string: " ", attributes: valAtts) : newLine)
            return returnString
        }
    case .null:
        let valString: String = isKey ? "NULL KEY" : "NULL VALUE"
        returnString.append(getIndentedString(valString, indent))
        returnString.setAttributes(valAtts,
                                   range: NSMakeRange(0, returnString.length))
        returnString.append(isKey ? NSAttributedString.init(string: " ", attributes: valAtts) : newLine)
        return returnString
    default:
        // Place all the scalar values here
        // TODO These *may* be keys too, so we need to check that
        var valString: String = ""
        
        if let val = part.int {
            valString = "\(val)\n"
        } else if let val = part.double {
            valString = "\(val)\n"
        } else if let val = part.bool {
            valString = val ? "TRUE\n" : "FALSE\n"
        } else {
            valString = "UNKNOWN\n"
        }
        
        returnString.append(getIndentedString(valString, indent))
        returnString.setAttributes((isKey ? keyAtts : valAtts),
                                   range: NSMakeRange(0, returnString.length))
        return returnString
    }
    
    // Error condition
    return nil
}


func getIndentedString(_ baseString: String, _ indent: Int) -> NSAttributedString {
    
    // Return a space-prefix NSAttributedString where 'indent' specifies
    // the number of spaces to add
    
    let trimmedString = baseString.trimmingCharacters(in: .whitespaces)
    let spaces = "                                                     "
    let spaceString = String(spaces.suffix(indent))
    let indentedString: NSMutableAttributedString = NSMutableAttributedString.init()
    indentedString.append(NSAttributedString.init(string: spaceString))
    indentedString.append(NSAttributedString.init(string: trimmedString))
    return indentedString.attributedSubstring(from: NSMakeRange(0, indentedString.length))
}


// MARK: Formatting Functions

func setBaseValues(_ isThumbnail: Bool) {

    // Set common base style values for the markdown render
    // NOTE This should now be called only once

    // The suite name is the app group name, set in each extension's entitlements, and the host app's
    if let defaults = UserDefaults(suiteName: MNU_SECRETS.PID + ".suite.preview-yaml") {
        defaults.synchronize()
        fontBaseSize = CGFloat(isThumbnail
                              ? defaults.float(forKey: "com-bps-previewyaml-thumb-font-size")
                              : defaults.float(forKey: "com-bps-previewyaml-base-font-size"))
        codeColourIndex = defaults.integer(forKey: "com-bps-previewyaml-code-colour-index")
        codeFontIndex = defaults.integer(forKey: "com-bps-previewyaml-code-font-index")
        doShowLightBackground = defaults.bool(forKey: "com-bps-previewyaml-do-use-light")
        yamlIndent = isThumbnail ? 2 : defaults.integer(forKey: "com-bps-previewyaml-yaml-indent")
        doShowRawYaml = defaults.bool(forKey: "com-bps-previewyaml-show-bad-yaml")
        doIndentScalars = defaults.bool(forKey: "com-bps-previewyaml-do-indent-scalars")
    }

    // Just in case the above block reads in zero values
    // NOTE The other valyes CAN be zero
    if fontBaseSize < 1.0 || fontBaseSize > 28.0 {
        fontBaseSize = CGFloat(isThumbnail ? BUFFOON_CONSTANTS.BASE_THUMB_FONT_SIZE : BUFFOON_CONSTANTS.BASE_PREVIEW_FONT_SIZE)
    }

    // Set the YAML key:value fonts and sizes
    var font: NSFont
    if codeFontIndex == 0 {
        font = NSFont.systemFont(ofSize: fontBaseSize)
    } else {
        if let otherFont = NSFont.init(name: codeFonts[codeFontIndex], size: fontBaseSize) {
            font = otherFont
        } else {
            font = NSFont.systemFont(ofSize: fontBaseSize)
        }
    }
    
    keyAtts = [
        .foregroundColor: getColour(codeColourIndex),
        .font: font
    ]
    
    valAtts = [
        .foregroundColor: (isThumbnail || doShowLightBackground ? NSColor.black : NSColor.labelColor),
        .font: font
    ]
    
    hr = NSAttributedString(string: "\n\u{00A0}\u{0009}\u{00A0}\n\n",
                            attributes: [.strikethroughStyle: NSUnderlineStyle.thick.rawValue,
                                         .strikethroughColor: (isThumbnail || doShowLightBackground ? NSColor.black : NSColor.white)])
    
    newLine = NSAttributedString.init(string: "\n",
                                      attributes: valAtts)
}


func getColour(_ index: Int) -> NSColor {

    // Return the colour from the selection

    switch index {
        case 0:
            return NSColor.systemPurple
        case 1:
            return NSColor.systemBlue
        case 2:
            return NSColor.systemRed
        case 3:
            return NSColor.systemGreen
        case 4:
            return NSColor.systemOrange
        case 5:
            return NSColor.systemPink
        case 6:
            return NSColor.systemTeal
        case 7:
            return NSColor.systemBrown
        case 8:
            return NSColor.systemYellow
        case 9:
            return NSColor.systemIndigo
        default:
            return NSColor.systemGray
    }
}
    

func setError(_ code: Int) -> NSError {
    
    // NSError generation function
    
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


// MARK: - EXPERIMENTAL

func fixNan(_ yamlString: String) -> String {
    
    // Attempt to trap and fix .NaN, -.INF and .INF,
    // which give YamlSwift trouble
    
    let regexes = [#"-\.(inf|Inf|INF)+"#, #"\.(inf|Inf|INF)+"#, #"\.(nan|NaN|NAN)+"#]
    let unfixedlines = yamlString.components(separatedBy: CharacterSet.newlines)
    var fixedString: String = ""
    
    // Run through all the YAML file's lines
    for i in 0..<unfixedlines.count {
        // Look for a pattern on the current line
        var count: Int = 0
        var line: String = unfixedlines[i]
        
        for regex in regexes {
            if let itemRange: Range = line.range(of: regex, options: .regularExpression) {
                // Set the symbol based on the current value of 'count'
                // Can make this more Swift-y with an enum
                var symbol = ""
                switch(count) {
                case 0:
                    symbol = "\"-INF\""
                case 1:
                    symbol = "\"+INF\""
                default:
                    symbol = "\"NAN\""
                }
                
                // Swap out the originl symbol for a string version
                // (which doesn't cause a crash YamlString crash)
                line = line.replacingCharacters(in: itemRange, with: symbol)
                break;
            }
            
            // Move to next symbol
            count += 1
        }
        
        // Compose the return string
        fixedString += (line + "\n")
    }
    
    // Send the updated string back
    return fixedString
}
