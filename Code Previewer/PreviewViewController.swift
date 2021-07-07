/*
 *  PreviewViewController.swift
 *  PreviewCode
 *
 *  Created by Tony Smith on 30/05/2021.
 *  Copyright © 2021 Tony Smith. All rights reserved.
 */


import Cocoa
import Quartz


class PreviewViewController: NSViewController,
                             QLPreviewingController {

    // MARK:- Class UI Properties

    @IBOutlet var renderTextView: NSTextView!
    @IBOutlet var renderTextScrollView: NSScrollView!


    // MARK:- Public Properties

    override var nibName: NSNib.Name? {
        return NSNib.Name("PreviewViewController")
    }


    // MARK:- QLPreviewingController Required Functions

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {

        /*
         * This is the main entry point for macOS' preview system
         */

        // Get an error message ready for use
        var reportError: NSError? = nil

        // Load and process the source file
        if FileManager.default.isReadableFile(atPath: url.path) {
            // Only proceed if the file is accessible from here
            do {
                // Get the file contents as a string
                let data: Data = try Data.init(contentsOf: url, options: [.uncached])
                if let codeFileString: String = String.init(data: data, encoding: .utf8) {
                    // Instantiate the common code within the closure
                    let common: Common = Common.init(false)

                    // Set the language
                    let language: String = common.getLanguage(url.path, false)

                    // Get the key string first
                    let codeAttString: NSAttributedString = common.getAttributedString(codeFileString, language, false)

                    // Set text and scroll view attributes according to style
                    // TODO Do a better job of checking whether theme is dark or light
                    self.renderTextView.backgroundColor = common.themeBackgroundColour
                    self.renderTextScrollView.scrollerKnobStyle = common.isThemeDark ? .light : .dark

                    if let renderTextStorage: NSTextStorage = self.renderTextView.textStorage {
                        /*
                         * NSTextStorage subclasses that return true from the fixesAttributesLazily
                         * method should avoid directly calling fixAttributes(in:) or else bracket
                         * such calls with beginEditing() and endEditing() messages.
                         */
                        renderTextStorage.beginEditing()
                        renderTextStorage.setAttributedString(codeAttString)
                        renderTextStorage.endEditing()
                    } else {
                        handler(setError(BUFFOON_CONSTANTS.ERRORS.CODES.BAD_TS_STRING))
                        return
                    }

                    // Add the subview to the instance's own view and draw
                    self.view.display()

                    // Call the QLPreviewingController indicating no error
                    // (argument is nil)
                    handler(nil)
                    return
                } else {
                    // We couldn't get the markdwn string so set an appropriate error to report back
                    reportError = setError(BUFFOON_CONSTANTS.ERRORS.CODES.BAD_MD_STRING)
                }
            } catch {
                // We couldn't read the file so set an appropriate error to report back
                reportError = setError(BUFFOON_CONSTANTS.ERRORS.CODES.FILE_WONT_OPEN)
            }
        } else {
            // We couldn't access the file so set an appropriate error to report back
            reportError = setError(BUFFOON_CONSTANTS.ERRORS.CODES.FILE_INACCESSIBLE)
        }

        // Call the QLPreviewingController indicating an error
        // (argumnet is not nil)
        handler(reportError)
    }


    func preparePreviewOfSearchableItem(identifier: String, queryString: String?, completionHandler handler: @escaping (Error?) -> Void) {

        // Is this ever called?
        NSLog("BUFFOON searchable identifier: \(identifier)")
        NSLog("BUFFOON searchable query:      " + (queryString ?? "nil"))

        // Hand control back to QuickLook
        handler(nil)
    }


    // MARK:- Utility Functions

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

}
