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
    
    private var appSuiteName: String = MNU_SECRETS.PID + BUFFOON_CONSTANTS.SUITE_NAME
    
    
    // MARK:- Lifecycle Required Functions
    
    override init() {
        
        /* 
         * Override the init() method so we can do all the setup we need
         * BEFORE we start rendering, ie. so we don't write values another
         * thread may be trying to read
         */
        
        // Must call the super class because we don't know
        // what operations it performs
        super.init()
        
        // Set the base values once per instantiation, not every
        // time a string is rendered (which risks a race condition)
        setBaseValues(true)
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
            //let success = autoreleasepool { () -> Bool in
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

                        // Instantiate an NSTextField to display the NSAttributedString render of the code
                        let codeTextField: NSTextField = NSTextField.init(labelWithAttributedString: codeAttString)
                        codeTextField.frame = codeFrame
                        
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
                        let tag: String = getLanguage(request.fileURL.path, true).uppercased()
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
                        let tagTextField: NSTextField = NSTextField.init(labelWithAttributedString: NSAttributedString.init(string: tag, attributes: tagAtts))
                        tagTextField.frame = tagFrame
                        
                        // Generate the bitmap from the rendered YAML text view
                        guard let imageRep: NSBitmapImageRep = codeTextField.bitmapImageRepForCachingDisplay(in: codeFrame) else { return false }
                        
                        // Draw the code view into the bitmap and then the tag
                        codeTextField.cacheDisplay(in: codeFrame, to: imageRep)
                        tagTextField.cacheDisplay(in: tagFrame, to: imageRep)
                        return imageRep.draw(in: thumbnailFrame)
                    } catch {
                        // NOP: fall through to error
                    }
                }

                // We didn't draw anything because of an error
                return false
            //}

            // Pass the outcome up from out of the autorelease
            // pool code to the handler
            //return success
        }, nil)
    }
    
    
    /*
    // MARK:- Utility Functions
    
    /**
     Create an attributed string for a file icon tag.
     
     We'll use it to determine the file's programming language.
     
     - Parameters:
        - tag:   The text of the tag.
     
     - Returns: The tag as an NSAttributedString.
     */
    func getTagString(_ tag: String) -> NSAttributedString {

        // Set the paragraph style we'll use -- just centred text
        let style: NSMutableParagraphStyle = NSMutableParagraphStyle.init()
        style.alignment = .center
        style.lineBreakMode = .byTruncatingMiddle
        
        // Set the point size
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
            .paragraphStyle: style,
            .font: NSFont.systemFont(ofSize: fontSize),
            .foregroundColor: NSColor.init(red: 0.00, green: 0.33, blue: 0.53, alpha: 1.00)
        ]

        // Return the attributed string built from the tag
        return NSAttributedString.init(string: tag,
                                       attributes: tagAtts)
    }
    */
}
