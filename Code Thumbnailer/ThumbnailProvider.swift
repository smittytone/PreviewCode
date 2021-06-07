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
    
    // MARK: Private Properties
    private var appSuiteName: String = MNU_SECRETS.PID + BUFFOON_CONSTANTS.SUITE_NAME
    
    
    // MARK:- Lifecycle Required Functions
    
    override init() {
        // Must call the super class because we don't know
        // what operations it performs
        super.init()
        
        // Set the base values once per instantiation, not every
        // time a string is rendered (which risks a race condition)
        setBaseValues(true)
    }

    
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        
        let thumbnailFrame: CGRect = NSMakeRect(0.0,
                                                0.0,
                                                CGFloat(BUFFOON_CONSTANTS.THUMBNAIL_SIZE.ASPECT) * request.maximumSize.height,
                                                request.maximumSize.height)
        
        handler(QLThumbnailReply.init(contextSize: thumbnailFrame.size) { () -> Bool in
            // Place all the remaining code within the closure passed to 'handler()'
            let success = autoreleasepool { () -> Bool in
                // Load the source file using a co-ordinator as we don't know what thread this function
                // will be executed in when it's called by macOS' QuickLook code
                if FileManager.default.isReadableFile(atPath: request.fileURL.path) {
                    // Only proceed if the file is accessible from here
                    do {
                        // Get the file contents as a string, making sure it's not cached
                        // as we're not going to read it again any time soon
                        let data: Data = try Data.init(contentsOf: request.fileURL, options: [.uncached])
                        guard let codeFileString: String = String.init(data: data, encoding: .utf8) else { return false }
                        
                        // Set the language
                        let language: String = getLanguage(request.fileURL.path, false)
                        
                        // Get the Attributed String
                        let codeAttString: NSAttributedString = getAttributedString(codeFileString, language, true)

                        // Set the primary drawing frame and a base font size
                        let codeFrame: CGRect = CGRect.init(x: BUFFOON_CONSTANTS.THUMBNAIL_SIZE.ORIGIN_X,
                                                            y: BUFFOON_CONSTANTS.THUMBNAIL_SIZE.ORIGIN_Y,
                                                            width: BUFFOON_CONSTANTS.THUMBNAIL_SIZE.WIDTH,
                                                            height: BUFFOON_CONSTANTS.THUMBNAIL_SIZE.HEIGHT)

                        // Instantiate an NSTextView to display the NSAttributedString render of the code
                        // Make sure it is not selectable, ie. not interactive
                        let codeTextView: NSTextView = NSTextView.init(frame: codeFrame)
                        codeTextView.isSelectable = false
                        codeTextView.backgroundColor = NSColor.white

                        // Write the code NSAttributedString into the view's text storage
                        guard let codeTextStorage: NSTextStorage = codeTextView.textStorage else { return false }
                        codeTextStorage.setAttributedString(codeAttString)

                        // Also generate text for the bottom-of-thumbnail file type tag,
                        // if the user has this set as a preference
                        var tagTextView: NSTextView? = nil
                        var tagFrame: CGRect? = nil

                        // Define the frame of the tag area
                        tagFrame = CGRect.init(x: BUFFOON_CONSTANTS.THUMBNAIL_SIZE.ORIGIN_X,
                                               y: BUFFOON_CONSTANTS.THUMBNAIL_SIZE.ORIGIN_Y,
                                               width: BUFFOON_CONSTANTS.THUMBNAIL_SIZE.WIDTH,
                                               height: BUFFOON_CONSTANTS.THUMBNAIL_SIZE.TAG_HEIGHT)

                        // Instantiate an NSTextView to display the NSAttributedString render of the tag,
                        // this time with a clear background
                        // Make sure it is not selectable, ie. not interactive
                        // NOTE 'tagTextView' is an optional
                        tagTextView = NSTextView.init(frame: tagFrame!)
                        tagTextView!.isSelectable = false
                        tagTextView!.backgroundColor = NSColor.clear

                        // Write the tag rendered as an NSAttributedString into the view's text storage
                        if let tagTextStorage: NSTextStorage = tagTextView!.textStorage {
                            // NOTE We use 'request.maximumSize' for more accurate results
                            let tag: String = getLanguage(request.fileURL.path, true).uppercased()
                            tagTextStorage.setAttributedString(self.getTagString(tag, request.maximumSize.width))
                            tagTextView!.textContainer!.lineFragmentPadding = 0.0
                            tagTextView!.textContainer!.maximumNumberOfLines = 1
                        } else {
                            // Set this on error so we don't try and draw the tag later
                            tagFrame = nil
                        }
                        
                        // Generate the bitmap from the rendered YAML text view
                        guard let imageRep: NSBitmapImageRep = codeTextView.bitmapImageRepForCachingDisplay(in: codeFrame) else { return false }
                        
                        // Draw into the bitmap first the YAML view...
                        codeTextView.cacheDisplay(in: codeFrame, to: imageRep)

                        // ...then the tag view
                        if tagFrame != nil && tagTextView != nil {
                            tagTextView!.cacheDisplay(in: tagFrame!, to: imageRep)
                        }

                        return imageRep.draw(in: thumbnailFrame)
                    } catch {
                        // NOP: fall through to error
                    }
                }

                // We didn't draw anything because of an error
                return false
            }

            // Pass the outcome up from out of the autorelease
            // pool code to the handler
            return success
        }, nil)
    }
    
    
    // MARK:- Misc Functions
    
    func getTagString(_ tag: String, _ width: CGFloat) -> NSAttributedString {

        // Set the text for the bottom-of-thumbnail file type tag

        // Set the paragraph style we'll use -- just centred text
        let style: NSMutableParagraphStyle = NSMutableParagraphStyle.init()
        style.alignment = .center
        style.lineBreakMode = .byTruncatingMiddle
        
        // Set the point size
        var fontSize: CGFloat = 146
        let renderSize: NSSize = (tag as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: fontSize)])
        if renderSize.width > CGFloat(BUFFOON_CONSTANTS.THUMBNAIL_SIZE.WIDTH) - 20 {
            let ratio: CGFloat = CGFloat(BUFFOON_CONSTANTS.THUMBNAIL_SIZE.WIDTH - 20) / renderSize.width
            fontSize *= ratio;
            if fontSize < 118 {
                fontSize = 118
            }
        }
        
        // Build the tag's string attributes
        let tagAtts: [NSAttributedString.Key: Any] = [
            .paragraphStyle: style as NSParagraphStyle,
            .font: NSFont.systemFont(ofSize: fontSize),
            .foregroundColor: (width < 128
                                ? NSColor.init(red: 0.3, green: 0.0, blue: 0.0, alpha: 1.0)
                                : NSColor.init(red: 0.4, green: 0.0, blue: 0.0, alpha: 1.0))
        ]

        // Return the attributed string built from the tag
        return NSAttributedString.init(string: tag,
                                       attributes: tagAtts)
    }
}
