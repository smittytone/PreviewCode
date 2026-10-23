/*
 *  ThumbnailProvider.swift
 *  PreviewCode
 *
 *  Created by Tony Smith on 04/06/2021.
 *  Copyright © 2026 Tony Smith. All rights reserved.
 */


import AppKit
import QuickLookThumbnailing


class ThumbnailProvider: QLThumbnailProvider {

    // MARK: - Private Properties

    private enum ThumbnailerError: Error {
        case badFileLoad(String)
        case badFileUnreadable(String)
        case badFileUnsupportedEncoding(String)
        case badFileUnsupportedFile(String)
        case badGfxBitmap
        case badGfxDraw
        case badHighlighter
        case ignoredError
    }


    // MARK: - QLThumbnailProvider Required Functions

    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        
        /*
         * This is the main entry point for macOS' thumbnailing system
         */

        // Get the file contents as a string
        // FROM 2.3.0 - Only read in a minimal amount of data
        guard let codeFileHandle = try? FileHandle(forReadingFrom: request.fileURL) else {
            handler(nil, ThumbnailerError.badFileUnreadable(request.fileURL.path))
            return
        }

        defer { try? codeFileHandle.close() }

        guard let data = try? codeFileHandle.read(upToCount: BUFFOON_CONSTANTS.MAX_THUMBNAIL_READ_SIZE) else {
            // Can read file, buy can't read data (maybe none to be had?) so bail
            handler(nil, ThumbnailerError.badFileUnreadable(request.fileURL.path))
            return
        }

        // Get the string's encoding, or fail back to .utf8
        let encoding = data.stringEncoding ?? .utf8
        guard let codeString = String(data: data, encoding: encoding) else {
            handler(nil, ThumbnailerError.badFileLoad(request.fileURL.path))
            return
        }

        // Instantiate the common code within the closure
        guard let common = Common(forThumbnail: true) else {
            // A key component of Common, eg. 'hightlight.js' is missing, so bail
            handler(nil, ThumbnailerError.badHighlighter)
            return
        }

        // Instantiate an NSTextField to display the NSAttributedString render of the code
        let language = common.getLanguage(request.fileURL.path)

        // FROM 2.2.5 -- handle Psion files
        var codeAttString: NSAttributedString
        if language == "psion" {
            // Special case for psion files, which may contain binary data
            if request.fileURL.pathExtension.lowercased() == "opl" {
                // NOTE In this case only, the thumbnail's source string may be rendered way too big
                codeAttString = common.getAttributedString(common.processPsionFile(data, encoding), "scala")
            } else {
                codeAttString = common.getAttributedString(codeString, "scala")
            }
        } else {
            // All other languages
            codeAttString = common.getAttributedString(codeString, language)
        }

        // Set the primary NSTextView drawing frame and a base font size
        let codeFrame = NSMakeRect(CGFloat(BUFFOON_CONSTANTS.THUMBNAIL.ORIGIN_X),
                                   CGFloat(BUFFOON_CONSTANTS.THUMBNAIL.ORIGIN_Y),
                                   CGFloat(BUFFOON_CONSTANTS.THUMBNAIL.WIDTH),
                                   CGFloat(BUFFOON_CONSTANTS.THUMBNAIL.HEIGHT))

        let codeTextField = NSTextField(frame: codeFrame)
        codeTextField.attributedStringValue = codeAttString

        // FROM 2.2.3
        // From macOS 26.1, make sure thumbnail backgrounds remain white
        // NOTE This may become a setting in future, but for now retain the styling
        //      we have always presented.
        if #available(macOS 26.1, *) {
            if !common.settings.thumbnailMatchFinderMode {
                codeTextField.isBezeled = false
                codeTextField.drawsBackground = true
                codeTextField.backgroundColor = .white
            }
        }

        // Generate the bitmap from the rendered code text view
        guard let bodyImageRep = codeTextField.bitmapImageRepForCachingDisplay(in: codeFrame) else {
            handler(nil, ThumbnailerError.badGfxBitmap)
            return
        }

        // Draw the code view into the bitmap
        codeTextField.cacheDisplay(in: codeFrame, to: bodyImageRep)

        guard let image = bodyImageRep.cgImage else {
            handler(nil, ThumbnailerError.badGfxDraw)
            return
        }

        // Calculate image scaling, frame size, etc.
        let thumbnailFrame = NSMakeRect(0.0,
                                        0.0,
                                        CGFloat(BUFFOON_CONSTANTS.THUMBNAIL.ASPECT) * request.maximumSize.height,
                                        request.maximumSize.height)

        // NOTE The `+2.0` is a hack to avoid a line above the image
        let scaleFrame = NSMakeRect(0.0,
                                    0.0,
                                    thumbnailFrame.width * request.scale,
                                    (thumbnailFrame.height * request.scale) + 2.0)

        // Pass a QLThumbnailReply and no error to the supplied handler
        handler(QLThumbnailReply(contextSize: thumbnailFrame.size) { (context) -> Bool in
            // `scaleFrame` and `image` are immutable
            context.draw(image, in: scaleFrame, byTiling: false)
            return true
        }, nil)
    }
}
