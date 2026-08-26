/*
 *  PAExtension.swift
 *  PreviewApps
 *
 *  Created by Tony Smith on 18/06/2021.
 *  Copyright © 2026 Tony Smith. All rights reserved.
 */

import AppKit


extension Data {

    /**
     Get the encoding of the string formed from data.

     - Returns The string's encoding or nil.
    */
    var stringEncoding: String.Encoding? {
        var nss: NSString? = nil
        guard case let rawValue = NSString.stringEncoding(for: self,
                                                          encodingOptions: nil,
                                                          convertedString: &nss,
                                                          usedLossyConversion: nil), rawValue != 0 else { return nil }
        return .init(rawValue: rawValue)
    }
}


extension NSMutableAttributedString {

    /**
     Swap the paragraph style in all of the attributes of an NSMutableAttributedString
     with the supplied new paragraph style.

     - Parameters:
        - paraStyle: The injected NSParagraphStyle.
     */
    func addParaStyle(with paraStyle: NSParagraphStyle) {

        beginEditing()
        self.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: self.length)) { (value, range, stop) in
            if let _ = value as? NSParagraphStyle {
                addAttribute(.paragraphStyle, value: paraStyle, range: range)
            }
        }
        endEditing()
    }


    /**
     Append the contents of an array of attributed strings

     - Parameters:
        - strings: The attributed strings to add.
     */
    public func addAttributedStrings(_ strings: [NSMutableAttributedString]) {

        for string in strings {
            self.append(string)
        }
    }


    /**
     Append the contents of an array of attributed strings

     - Parameters:
        - strings: The attributed strings to add.
     */
    public func addAttributedStrings(_ strings: [NSAttributedString]) {

        for string in strings {
            self.append(string)
        }
    }
}


extension NSAttributedString {

    /**
     Return the width of the rendered string in points.
     */
    var width: CGFloat {
        let rectA = boundingRect(
          with: NSSize(width: Double.infinity, height: Double.infinity),
          options: [.usesLineFragmentOrigin]
        )

        let textStorage = NSTextStorage(attributedString: self)
        let textContainer = NSTextContainer()
        let layoutManager = NSLayoutManager()

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        textContainer.lineFragmentPadding = 0.0
        layoutManager.glyphRange(for: textContainer)

        let rectB = layoutManager.usedRect(for: textContainer)
        return ceil(max(rectA.width, rectB.width))
    }


    /**
     Split the instance as per splitting a regular string.
     */
    func components(separatedBy separator: String) -> [NSAttributedString] {
        var parts: [NSAttributedString] = []
        let subStrings = self.string.components(separatedBy: separator)
        var range = NSRange(location: 0, length: 0)
        for subString in subStrings {
            range.length = subString.utf16.count
            let attributedString = attributedSubstring(from: range)
            parts.append(attributedString)
            range.location += range.length + separator.utf16.count
        }

        return parts
    }
}


extension Scanner {

    /**
     Look ahead and return the next character in the sequence without
     altering the current location of the scanner.

     DEPRECATED

     - Parameters
        - in: The string being scanned.

     - Returns The next character as a string.
     */
    func getNextCharacter(in outer: String) -> String {

        let string = self.string as NSString
        let idx = self.currentIndex.utf16Offset(in: outer)
        let nextChar = string.substring(with: NSMakeRange(idx, 1))
        return nextChar
    }


    /**
     Look ahead and return the next character in the sequence without
     altering the current location of the scanner.

     - Returns The next character as a string, or an empty one.
     */
    func getNextChar() -> String {

        if self.currentIndex < self.string.endIndex {
            let nextIndex = self.string.index(after: self.currentIndex)
            return String(self.string[self.currentIndex..<nextIndex])
        }

        return ""
    }


    /**
     Step over the next character.
     */
    func skipNextCharacter() {

        // Add check to hopefully fix certain Thumbnailer crashes
        if self.currentIndex < self.string.endIndex {
            self.currentIndex = self.string.index(after: self.currentIndex)
        }
    }
}


extension CGFloat {

    /**
     Determine if the instance is near enough the specified value as makes no odds.

     - Parameters
        - value: The float value we're comparing the instance to.

     - Returns `true` if the values are proximate, otherwise `false`.
     */
    func isClose(to value: CGFloat) -> Bool {

        let rndA = (self * 100).rounded() / 100
        let rndB = (value * 100).rounded() / 100

        if self == value || rndA == rndB {
            return true
        }

        let absA: CGFloat = abs(self)
        let absB: CGFloat = abs(value)
        let diff: CGFloat = abs(self - value)

        if self == .zero || value == .zero || (absA + absB) < Self.leastNormalMagnitude {
            return diff < Self.ulpOfOne * Self.leastNormalMagnitude
        } else {
            return (diff / Self.minimum(CGFloat(absA + absB), Self.greatestFiniteMagnitude)) < .ulpOfOne
        }
    }
}


extension Double {

    /**
     Determine if the instance is near enough the specified value as makes no odds.

     - Parameters
        - value: The float value we're comparing the instance to.

     - Returns `true` if the values are proximate, otherwise `false`.
     */
    func isClose(to value: CGFloat) -> Bool {

        let rndA = (self * 100).rounded() / 100
        let rndB = (value * 100).rounded() / 100

        if self == value || rndA == rndB {
            return true
        }

        let absA: CGFloat = abs(self)
        let absB: CGFloat = abs(value)
        let diff: CGFloat = abs(self - value)

        if self == .zero || value == .zero || (absA + absB) < Self.leastNormalMagnitude {
            return diff < Self.ulpOfOne * Self.leastNormalMagnitude
        } else {
            return (diff / Self.minimum(CGFloat(absA + absB), Self.greatestFiniteMagnitude)) < .ulpOfOne
        }
    }
}


extension NSColor {

    /**
     Class function to return an NSColor object that matches the colour supplied as a RGBA hex value.

     - Parameters:
        - colourValue: The colour as a hex string `RRGGBBAA`, eg `FF00AA88`.

     - Returns An NSColor object.
     */
    static func hexToColour(_ colourValue: String) -> NSColor {

        var colourString = colourValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        if (colourString.hasPrefix("#")) {
            // The colour is defined by a hex value
            colourString = String(colourString.dropFirst(1))
        }

        // Colours in hex strings have 3, 6 or 8 (6 + alpha) values
        guard [8, 6, 3].contains(colourString.count) else { return NSColor.gray }
        guard let colourValue = Int(colourString, radix: 16) else { return NSColor.gray }

        var r: UInt64 = 0, g: UInt64 = 0, b: UInt64 = 0
        var divisor: CGFloat = 255.0
        var alpha: CGFloat = 1.0

        if colourString.count == 6 {
            r = UInt64((colourValue >> 16) & 0xFF)
            g = UInt64((colourValue >> 8) & 0xFF)
            b = UInt64(colourValue & 0xFF)
        } else if colourString.count == 8 {
            r = UInt64((colourValue >> 24) & 0xFF)
            g = UInt64((colourValue >> 16) & 0xFF)
            b = UInt64((colourValue >> 8) & 0xFF)
            alpha = CGFloat(colourValue & 0xFF) / divisor
        } else {
            // Decode a three-character hex string
            r = UInt64((colourValue >> 8) & 0xF)
            g = UInt64((colourValue >> 4) & 0xF)
            b = UInt64(colourValue & 0xF)
            divisor = 15.0
        }

        return NSColor(red: CGFloat(r) / divisor, green: CGFloat(g) / divisor, blue: CGFloat(b) / divisor, alpha: alpha)
    }


    /**
     Property providing a colour's internal representation into an RGB+A hex string.
     */
    var hexString: String {

        guard let rgbColour = usingColorSpace(.sRGB) else {
            return "FF0000FF"
        }

        let red = Int(round(rgbColour.redComponent * 0xFF))
        let green = Int(round(rgbColour.greenComponent * 0xFF))
        let blue = Int(round(rgbColour.blueComponent * 0xFF))
        let alpha = Int(round(rgbColour.alphaComponent * 0xFF))

        let hexString = NSString(format: "%02X%02X%02X%02X", red, green, blue, alpha)
        return hexString as String
    }
}


extension URL {

    /**
     Get a Unix-styled path from a file URL.

     - Returns The Unix-stype path.
     */
    func unixpath() -> String {

        return self.absoluteString.replacingOccurrences(of: "file://", with: "")
    }
}


extension NSApplication {

    var inLightMode: Bool {
        // Use a better check than string values
        return effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .aqua
    }
}


extension NSBitmapImageRep {

    /**
     Return a copy of the image in the specified size.

     - Parameters
        - newSize: The chosen size.

     - Returns The resized version of the image, or `nil` on error.
     */
    func resize(to newSize: NSSize) -> NSBitmapImageRep? {

        if let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil,
                                         pixelsWide: Int(newSize.width),
                                         pixelsHigh: Int(newSize.height),
                                         bitsPerSample: 8,
                                         samplesPerPixel: 4,
                                         hasAlpha: true,
                                         isPlanar: false,
                                         colorSpaceName: .calibratedRGB,
                                         bytesPerRow: 0,
                                         bitsPerPixel: 0) {
            bitmap.size = newSize
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
            draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: .zero, operation: .copy, fraction: 1.0, respectFlipped: true, hints: nil)
            NSGraphicsContext.restoreGraphicsState()

            return bitmap
        }

        return nil
    }
}


extension String {

    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, self.count)..<self.count]
    }

    func substring(toIndex: Int) -> String {
        return self[0..<max(0, toIndex)]
    }

    subscript(r: Range<Int>) -> String {
        let bounds = (lower: max(0, min(self.count, r.lowerBound)), upper: min(self.count, max(0, r.upperBound)))
        let range = Range(uncheckedBounds:bounds)
        let start = index(self.startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}
