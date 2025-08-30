/*
 *  ThumbnailProvider.swift
 *  PreviewCode
 *
 *  Created by Tony Smith on 04/06/2021.
 *  Copyright © 2025 Tony Smith. All rights reserved.
 */


import Foundation
import AppKit
import QuickLookThumbnailing


class ThumbnailProvider: QLThumbnailProvider {

    // MARK:- Private Properties

    private enum ThumbnailerError: Error {
        case badFileLoad(String)
        case badFileUnreadable(String)
        case badFileUnsupportedEncoding(String)
        case badFileUnsupportedFile(String)
        case badGfxBitmap
        case badGfxDraw
        case badHighlighter
    }


    // MARK:- QLThumbnailProvider Required Functions

    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {

        /*
         * This is the main entry point for macOS' thumbnailing system
         */

        // Load the source file using a co-ordinator as we don't know what thread this function
        // will be executed in when it's called by macOS' QuickLook code
        if FileManager.default.isReadableFile(atPath: request.fileURL.path) {
            // Only proceed if the file is accessible from here
            do {
                // Get the file contents as a string, making sure it's not cached
                // as we're not going to read it again any time soon
                let data: Data = try Data(contentsOf: request.fileURL, options: [.uncached])

                // Get the string's encoding, or fail back to .utf8
                let encoding: String.Encoding = data.stringEncoding ?? .utf8

                guard let codeFileString: String = String(data: data, encoding: encoding) else {
                    handler(nil, ThumbnailerError.badFileLoad(request.fileURL.path))
                    return
                }

                // Instantiate the common code within the closure
                let common: Common = Common(true)
                if common.initError {
                    // A key component of Common, eg. 'hightlight.js' is missing,
                    // so we cannot continue
                    handler(nil, ThumbnailerError.badHighlighter)
                    return
                }

                // Only render the lines likely to appear in the thumbnail
                let lines: [Substring] = codeFileString.split(separator: "\n", maxSplits: BUFFOON_CONSTANTS.THUMBNAIL.LINE_COUNT + 1, omittingEmptySubsequences: false)
                var displayString: String = ""
                for i in 0..<lines.count {
                    // Break at line THUMBNAIL_LINE_COUNT
                    if i >= BUFFOON_CONSTANTS.THUMBNAIL.LINE_COUNT { break }
                    displayString += (String(lines[i]) + "\n")
                }

                // Set the primary drawing frame and a base font size
                let codeFrame: CGRect = NSMakeRect(CGFloat(BUFFOON_CONSTANTS.THUMBNAIL.ORIGIN_X),
                                                   CGFloat(BUFFOON_CONSTANTS.THUMBNAIL.ORIGIN_Y),
                                                   CGFloat(BUFFOON_CONSTANTS.THUMBNAIL.WIDTH),
                                                   CGFloat(BUFFOON_CONSTANTS.THUMBNAIL.HEIGHT))

                // Instantiate an NSTextField to display the NSAttributedString render of the code
                let language: String = common.getLanguage(request.fileURL.path, false)
                let codeTextField: NSTextField = NSTextField(frame: codeFrame)
                codeTextField.attributedStringValue = common.getAttributedString(displayString, language)

                // Generate the bitmap from the rendered code text view
                guard let bodyImageRep: NSBitmapImageRep = codeTextField.bitmapImageRepForCachingDisplay(in: codeFrame) else {
                    handler(nil, ThumbnailerError.badGfxBitmap)
                    return
                }

                // Draw the code view into the bitmap
                codeTextField.cacheDisplay(in: codeFrame, to: bodyImageRep)

                if let image: CGImage = bodyImageRep.cgImage {
                    // Just in case, make a copy of the cgImage, in case
                    // `bodyImageReg` is freed
                    if let cgImage: CGImage = image.copy() {
                        // Calculate image scaling, frame size, etc.
                        let thumbnailFrame: CGRect = NSMakeRect(0.0,
                                                                0.0,
                                                                CGFloat(BUFFOON_CONSTANTS.THUMBNAIL.ASPECT) * request.maximumSize.height,
                                                                request.maximumSize.height)
                        
                        // NOTE The `+2.0` is a hack to avoid a line above the image
                        let scaleFrame: CGRect = NSMakeRect(0.0,
                                                            0.0,
                                                            thumbnailFrame.width * request.scale,
                                                            (thumbnailFrame.height * request.scale) + 2.0)

                        // Pass a QLThumbnailReply and no error to the supplied handler
                        handler(QLThumbnailReply(contextSize: thumbnailFrame.size) { (context) -> Bool in
                            // `scaleFrame` and `cgImage` are immutable
                            context.draw(cgImage, in: scaleFrame, byTiling: false)
                            return true
                        }, nil)
                        return
                    }
                }

                handler(nil, ThumbnailerError.badGfxDraw)
                return
            } catch {
                // NOP: fall through to error
            }
        }

        // We didn't draw anything because of 'can't find file' error
        handler(nil, ThumbnailerError.badFileUnreadable(request.fileURL.path))
    }
}
