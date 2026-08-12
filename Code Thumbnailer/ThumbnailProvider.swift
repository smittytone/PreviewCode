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

    // FROM 2.2.4
    // Make the core generator common to all instances, ie. all thumbnails
    private var common: Common? = nil
    // Set the primary drawing frame and a base font size
    private let codeFrame: CGRect = NSMakeRect(CGFloat(BUFFOON_CONSTANTS.THUMBNAIL.ORIGIN_X),
                                               CGFloat(BUFFOON_CONSTANTS.THUMBNAIL.ORIGIN_Y),
                                               CGFloat(BUFFOON_CONSTANTS.THUMBNAIL.WIDTH),
                                               CGFloat(BUFFOON_CONSTANTS.THUMBNAIL.HEIGHT))

    // MARK: - QLThumbnailProvider Required Functions

    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        
        /*
         * This is the main entry point for macOS' thumbnailing system
         */

        // FROM 2.3.3 -- move this up so it's available outside the `do` block, and make it optional
        var codeFileHandle: FileHandle? = nil

        // Load the source file using a co-ordinator as we don't know what thread this function
        // will be executed in when it's called by macOS' QuickLook code
        do {
            // Get the file contents as a string
            // FROM 2.3.0 - Only read in a minimal amount of data
            codeFileHandle = try FileHandle(forReadingFrom: request.fileURL)

            // FROM 2.3.3 -- if `codeFileHandle` is still `nil` for some reason, bail
            guard let cfh = codeFileHandle else {
                throw ThumbnailerError.ignoredError
            }

            guard let data = try cfh.read(upToCount: BUFFOON_CONSTANTS.MAX_THUMBNAIL_READ_SIZE) else {
                // Can read file, buy can't read data (maybe none to be had?) so bail
                throw ThumbnailerError.ignoredError
            }

            // Close the open file because it's no longer needed
            // NOTE Should not fail because we've opened it and read data
            try cfh.close()

            // Get the string's encoding, or fail back to .utf8
            let encoding = data.stringEncoding ?? .utf8
            guard let codeString = String(data: data, encoding: encoding) else {
                handler(nil, ThumbnailerError.badFileLoad(request.fileURL.path))
                return
            }
            
            // Instantiate the common code within the closure
            if self.common == nil {
                self.common = Common(forThumbnail: true)
                if self.common == nil {
                    // A key component of Common, eg. 'hightlight.js' is missing,
                    // so we cannot continue
                    handler(nil, ThumbnailerError.badHighlighter)
                    return
                }
            }

            // Instantiate an NSTextField to display the NSAttributedString render of the code
            let language = self.common!.getLanguage(request.fileURL.path)

            // FROM 2.2.5 -- handle Psion files
            var codeAttString: NSAttributedString
            if language == "psion" {
                // Special case for psion files, which may contain binary data
                if request.fileURL.pathExtension.lowercased() == "opl" {
                    // NOTE In this case only, the thumbnail's source string may be rendered way too big
                    codeAttString = self.common!.getAttributedString(self.common!.processPsionFile(data, encoding), "scala")
                } else {
                    codeAttString = self.common!.getAttributedString(codeString, "scala")
                }
            } else {
                // All other languages
                codeAttString = self.common!.getAttributedString(codeString, language)
            }

            let codeTextField = NSTextField(frame: self.codeFrame)
            codeTextField.attributedStringValue = codeAttString

            // FROM 2.2.3
            // From macOS 26.1, make sure thumbnail backgrounds remain white
            // NOTE This may become a setting in future, but for now retain the styling
            //      we have always presented.
            if #available(macOS 26.1, *) {
                if !self.common!.settings.thumbnailMatchFinderMode {
                    codeTextField.isBezeled = false
                    codeTextField.drawsBackground = true
                    codeTextField.backgroundColor = .white
                }
            }

            // Generate the bitmap from the rendered code text view
            guard let bodyImageRep = codeTextField.bitmapImageRepForCachingDisplay(in: self.codeFrame) else {
                handler(nil, ThumbnailerError.badGfxBitmap)
                return
            }
            
            // Draw the code view into the bitmap
            codeTextField.cacheDisplay(in: codeFrame, to: bodyImageRep)
            
            if let image = bodyImageRep.cgImage {
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
                    // `scaleFrame` and `image` are immutable
                    context.draw(image, in: scaleFrame, byTiling: false)
                    return true
                }, nil)
                return
            }
            
            handler(nil, ThumbnailerError.badGfxDraw)
            return
        } catch {
            // FROM 2.3.4
            do {
                if let cfh = codeFileHandle {
                    try cfh.close()
                }
            } catch {
                // NOP -- pass through error
            }
        }
        
        // We didn't draw anything because of 'can't find file' error
        handler(nil, ThumbnailerError.badFileUnreadable(request.fileURL.path))
    }
}
