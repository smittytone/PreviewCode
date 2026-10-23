/*
 *  PreviewViewController.swift
 *  PreviewCode
 *
 *  Created by Tony Smith on 30/05/2021.
 *  Copyright © 2026 Tony Smith. All rights reserved.
 */

import AppKit
import Quartz


class PreviewViewController: NSViewController,
                             QLPreviewingController {

    // MARK: - Class UI Properties

    @IBOutlet var renderTextView: NSTextView!
    @IBOutlet var renderTextScrollView: NSScrollView!


    // MARK: - Public Properties

    override var nibName: NSNib.Name? {
        return NSNib.Name("PreviewViewController")
    }


    // MARK: - QLPreviewingController Required Functions

    // FROM 2.2.0
    // Update to use Swift Concurrency
    func preparePreviewOfFile(at url: URL) async throws {

        /*
         * This is the main entry point for macOS' preview system
         */

        // Get the file contents as a string
        guard let data = try? Data(contentsOf: url, options: [.uncached]) else {
            throw makeError(BUFFOON_CONSTANTS.ERRORS.CODES.FILE_WONT_OPEN)
        }

        let encoding = data.stringEncoding ?? .utf8
        guard let code = String(data: data, encoding: encoding) else {
            // FROM 1.2.2
            // We couldn't convert to data to a valid encoding
            throw makeError(BUFFOON_CONSTANTS.ERRORS.CODES.BAD_ENC_STRING, "unexpected encoding: \(encoding)")
        }

        /*
         * Instantiate the common code within the closure
         */
        guard let common = Common(forThumbnail: false) else {
            throw makeError(BUFFOON_CONSTANTS.ERRORS.CODES.BAD_HIGHLIGHTER)
        }

        /*
         * Attributed string acquisition
         */

        // Set the language
        let language = common.getLanguage(url.path)
        var attributedCode: NSAttributedString
        if language == "psion" {
            // Special case for psion files, which may contain binary data
            if url.pathExtension.lowercased() == "opl" {
                attributedCode = common.getAttributedString(common.processPsionFile(data, encoding), "scala")
            } else {
                attributedCode = common.getAttributedString(code, "scala")
            }
        } else {
            // Highlight the code
            attributedCode = common.getAttributedString(code, language)
        }

        /*
         * Window and mode configuration
         */

        // FROM 2.2.0
        // Set the parent window's size
        setPreviewWindowSize(common.settings)

        // FROM 2.3.0
        // The force-light-mode-preview-in-dark-mode setting is now a general
        // preview-colours-should-be-opposite-the-mode setting.
        let renderPreviewLight = !common.isThemeDark

        // Update the view mode
        self.renderTextView.backgroundColor = common.themeBackgroundColour
        self.renderTextScrollView.scrollerKnobStyle = renderPreviewLight ? .dark : .light
        self.view.appearance = renderPreviewLight ? NSAppearance(named: .aqua) : NSAppearance(named: .darkAqua)

        // FROM 2.0.0
        // Add a small margin around the preview
        if common.settings.previewMarginWidth > 0.0 {
            self.renderTextView.textContainerInset = NSSize(width: common.settings.previewMarginWidth,
                                                            height: common.settings.previewMarginWidth)
        }

        /*
         * Attributed String Presentation
         */

        guard let renderTextStorage = self.renderTextView.textStorage else {
            throw makeError(BUFFOON_CONSTANTS.ERRORS.CODES.BAD_TS_STRING)
        }

        /*
         * NSTextStorage subclasses that return true from the fixesAttributesLazily
         * method should avoid directly calling fixAttributes(in:) or else bracket
         * such calls with beginEditing() and endEditing() messages.
         */
        renderTextStorage.beginEditing()
        renderTextStorage.setAttributedString(attributedCode)
        renderTextStorage.endEditing()
    }


    // MARK: - Utility Functions

    /**
     Generate an NSError for an internal error, specified by its code.

     Codes are listed in `Constants.swift`

     - Parameters:
        - code:  The internal error code.
        - extra: Additional text for specific errors

     - Returns: The described error as an NSError.
     */
    func makeError(_ code: Int, _ extra: String = "") -> NSError {

        // NSError generation function

        var errDesc: String

        switch(code) {
            case BUFFOON_CONSTANTS.ERRORS.CODES.FILE_INACCESSIBLE:
                errDesc = BUFFOON_CONSTANTS.ERRORS.MESSAGES.FILE_INACCESSIBLE
            case BUFFOON_CONSTANTS.ERRORS.CODES.FILE_WONT_OPEN:
                errDesc = BUFFOON_CONSTANTS.ERRORS.MESSAGES.FILE_WONT_OPEN
            case BUFFOON_CONSTANTS.ERRORS.CODES.BAD_TS_STRING:
                errDesc = BUFFOON_CONSTANTS.ERRORS.MESSAGES.BAD_TS_STRING
            case BUFFOON_CONSTANTS.ERRORS.CODES.BAD_ENC_STRING:
                errDesc = BUFFOON_CONSTANTS.ERRORS.MESSAGES.BAD_ENC_STRING + " \(extra)"
            case BUFFOON_CONSTANTS.ERRORS.CODES.BAD_HIGHLIGHTER:
                errDesc = BUFFOON_CONSTANTS.ERRORS.MESSAGES.BAD_HIGHLIGHTER
            default:
                errDesc = "UNKNOWN ERROR"
        }

        return NSError(domain: BUFFOON_CONSTANTS.APP_CODE_PREVIEWER,
                       code: code,
                       userInfo: [NSLocalizedDescriptionKey: errDesc])
    }


    /**
     Specify the content size of the parent view.

     FROM 2.2.4
    */
    private func setPreviewWindowSize(_ settings: PCSettings) {

        // This app will never be run headless, so this should not really be necessary
        if NSScreen.screens.count > 0 {
            var screen: NSScreen = NSScreen.screens[0]

            // We've set `screen` to the primary, ie. menubar-displaying,
            // screen, but ideally we should pick the screen with user focus.
            // They may be one and the same, of course...
            if let mainScreen = NSScreen.main, mainScreen != screen {
                screen = mainScreen
            }

            let height = screen.frame.size.height * settings.previewWindowScale
            let width = screen.frame.size.width * settings.previewWindowScale
            self.preferredContentSize = NSSize(width: width, height: height)
        }
    }
}
