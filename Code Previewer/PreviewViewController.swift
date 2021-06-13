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
        
        // Set the base values
        setBaseValues(false)
        
        // Load and process the source file
        if FileManager.default.isReadableFile(atPath: url.path) {
            // Only proceed if the file is accessible from here
            do {
                // Get the file contents as a string
                let data: Data = try Data.init(contentsOf: url, options: [.uncached])
                if let codeFileString: String = String.init(data: data, encoding: .utf8) {
                    // Set the language
                    let language: String = getLanguage(url.path, false)
                    
                    // Get the key string first
                    let codeAttString: NSAttributedString = getAttributedString(codeFileString, language, false)
                    
                    // Set text and scroll view attributes according to style
                    // TODO Do a better job of checking whether theme is dark or light
                    self.renderTextView.backgroundColor = getBackgroundColour()
                    self.renderTextScrollView.scrollerKnobStyle = getMode() ? .light : .dark

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

}
