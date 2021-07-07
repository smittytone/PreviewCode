/*
 *  ThumbnailProvider.swift
 *  PreviewCode
 *
 *  Created by Tony Smith on 04/06/2021.
 *  Copyright © 2021 Tony Smith. All rights reserved.
 */


import QuickLookThumbnailing
import Cocoa


class ThumbnailProvider: QLThumbnailProvider {

    // MARK:- Private Properties

    private enum ThumbnailerError: Error {
        case badFileLoad(String)
        case badFileUnreadable(String)
        case badGfxBitmap
        case badGfxDraw
    }


    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {

        /*
         * This is the main entry point for macOS' thumbnailing system
         */

        let targetHeight: CGFloat = request.maximumSize.height
        let targetWidth: CGFloat = CGFloat(BUFFOON_CONSTANTS.THUMBNAIL_SIZE.ASPECT) * request.maximumSize.height
        let thumbnailFrame: CGRect = NSMakeRect(0.0,
                                                0.0,
                                                targetWidth,
                                                targetHeight)

        handler(QLThumbnailReply.init(contextSize: thumbnailFrame.size) { () -> Bool in
            // Place all the remaining code within the closure passed to 'handler()'
            let result: Result<Bool, ThumbnailerError> = autoreleasepool { () -> Result<Bool, ThumbnailerError> in
                // Load the source file using a co-ordinator as we don't know what thread this function
                // will be executed in when it's called by macOS' QuickLook code
                if FileManager.default.isReadableFile(atPath: request.fileURL.path) {
                    // Only proceed if the file is accessible from here
                    do {
                        // Get the file contents as a string, making sure it's not cached
                        // as we're not going to read it again any time soon
                        let data: Data = try Data.init(contentsOf: request.fileURL, options: [.uncached])
                        guard let codeFileString: String = String.init(data: data, encoding: .utf8) else {
                            return .failure(ThumbnailerError.badFileLoad(request.fileURL.path))
                        }

                        // Instantiate the common code within the closure
                        let common: Common = Common.init(true)

                        // Set the language
                        let language: String = common.getLanguage(request.fileURL.path, false)

                        // Get the Attributed String
                        let codeAttString: NSAttributedString = common.getAttributedString(codeFileString, language, true)


                        // Set the primary drawing frame and a base font size
                        let codeFrame: CGRect = CGRect.init(x: BUFFOON_CONSTANTS.THUMBNAIL_SIZE.ORIGIN_X,
                                                            y: BUFFOON_CONSTANTS.THUMBNAIL_SIZE.ORIGIN_Y,
                                                            width: BUFFOON_CONSTANTS.THUMBNAIL_SIZE.WIDTH,
                                                            height: BUFFOON_CONSTANTS.THUMBNAIL_SIZE.HEIGHT)

                        // Instantiate an NSTextField to display the NSAttributedString render of the code
                        let codeTextField: NSTextField = NSTextField.init(labelWithAttributedString: codeAttString)
                        codeTextField.frame = codeFrame

                        // Generate the bitmap from the rendered code text view
                        guard let imageRep: NSBitmapImageRep = codeTextField.bitmapImageRepForCachingDisplay(in: codeFrame) else {
                            return .failure(ThumbnailerError.badGfxBitmap)
                        }

                        // Draw the code view into the bitmap
                        codeTextField.cacheDisplay(in: codeFrame, to: imageRep)

                        // Also generate text for the bottom-of-thumbnail file type tag
                        // Define the frame of the tag area
                        let tagFrame: CGRect = CGRect.init(x: BUFFOON_CONSTANTS.THUMBNAIL_SIZE.ORIGIN_X,
                                                           y: BUFFOON_CONSTANTS.THUMBNAIL_SIZE.ORIGIN_Y,
                                                           width: BUFFOON_CONSTANTS.THUMBNAIL_SIZE.WIDTH,
                                                           height: BUFFOON_CONSTANTS.THUMBNAIL_SIZE.TAG_HEIGHT)

                        // Set the paragraph style we'll use -- just centred text
                        let style: NSMutableParagraphStyle = NSMutableParagraphStyle.init()
                        style.alignment = .center
                        style.lineBreakMode = .byTruncatingMiddle

                        // Set the point size
                        let tag: String = common.getLanguage(request.fileURL.path, true).uppercased()
                        var fontSize: CGFloat = CGFloat(BUFFOON_CONSTANTS.TAG_TEXT_SIZE)
                        let renderSize: NSSize = (tag as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: fontSize)])
                        if renderSize.width > CGFloat(BUFFOON_CONSTANTS.THUMBNAIL_SIZE.WIDTH) - 20 {
                            let ratio: CGFloat = CGFloat(BUFFOON_CONSTANTS.THUMBNAIL_SIZE.WIDTH - 20) / renderSize.width
                            fontSize *= ratio;
                            if fontSize < CGFloat(BUFFOON_CONSTANTS.TAG_TEXT_MIN_SIZE) {
                                fontSize = CGFloat(BUFFOON_CONSTANTS.TAG_TEXT_MIN_SIZE)
                            }
                        }

                        // Build the tag's string attributes
                        let tagAtts: [NSAttributedString.Key: Any] = [
                            .paragraphStyle: style as NSParagraphStyle,
                            .font: NSFont.systemFont(ofSize: fontSize),
                            .foregroundColor: NSColor.init(red: 0.00, green: 0.33, blue: 0.53, alpha: 1.00)
                        ]

                        // Instantiate an NSTextField to display the NSAttributedString render of the tag
                        let tagAttString: NSAttributedString = NSAttributedString.init(string: tag, attributes: tagAtts)
                        let tagTextField: NSTextField = NSTextField.init(labelWithAttributedString: tagAttString)
                        tagTextField.frame = tagFrame

                        // Draw the tag view into the bitmap
                        tagTextField.cacheDisplay(in: tagFrame, to: imageRep)

                        // Draw the bitmap into the current context
                        let drawResult = imageRep.draw(in: thumbnailFrame)
                        if drawResult {
                            return .success(true)
                        } else {
                            return .failure(ThumbnailerError.badGfxDraw)
                        }
                    } catch {
                        // NOP: fall through to error
                    }
                }

                // We didn't draw anything because of 'can't find file' error
                return .failure(ThumbnailerError.badFileUnreadable(request.fileURL.path))
            }

            // Pass the outcome up from out of the autorelease
            // pool code to the handler as a bool, logging an error
            // if appropriate
            switch result {
                case .success(_):
                    return true
                case .failure(let error):
                    switch error {
                        case .badFileUnreadable(let filePath):
                            NSLog("Could not access file \(filePath)")
                        case .badFileLoad(let filePath):
                            NSLog("Could not render file \(filePath)")
                        default:
                            NSLog("Could not render thumbnail")
                    }
            }

            return false
        }, nil)
    }

}
