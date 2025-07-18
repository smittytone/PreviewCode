/*
 *  FeedbackExtensions.swift
 *  PreviewCode
 *
 *  Created by Tony Smith on 18/07/2025.
 *  Copyright © 2025 Tony Smith. All rights reserved.
 */

import AppKit


extension AppDelegate {

    // MARK: - Feedback Window Functions

    /**
     Display a window in which the user can submit feedback, or report a bug.
     
     - Parameters:
     - sender: The source of the action.
     */
    @IBAction
    @objc
    private func doShowReportWindow(sender: Any) {
        
        // Hide menus we don't want used while the panel is open
        hidePanelGenerators()
        
        // Reset the UI
        self.connectionProgress.stopAnimation(self)
        self.feedbackText.stringValue = ""
        self.messageSizeLabel.stringValue = "\(self.feedbackText.stringValue.count)/\(BUFFOON_CONSTANTS.MAX_FEEDBACK_SIZE)"
        
        // Present the window
        self.window.beginSheet(self.reportWindow, completionHandler: nil)
    }


    /**
     User has clicked the Report window's 'Cancel' button, so just close the sheet.
     
     - Parameters:
     - sender: The source of the action.
     */
    @IBAction
    @objc
    private func doCancelReportWindow(sender: Any) {
        
        self.connectionProgress.stopAnimation(self)
        self.window.endSheet(self.reportWindow)
        
        // FROM 1.2.5
        // Restore menus
        showPanelGenerators()
    }


    /**
     User has clicked the Report window's 'Send' button.
     
     Get the message (if there is one) from the text field and submit it.
     
     - Parameters:
     - sender: The source of the action.
     */
    @IBAction
    @objc
    private func doSendFeedback(sender: Any) {
        
        let feedback: String = self.feedbackText.stringValue
        
        if feedback.count > 0 {
            // Start the connection indicator if it's not already visible
            self.connectionProgress.startAnimation(self)
            
            /*
             Add your own `func sendFeedback(_ feedback: String) -> URLSessionTask?` function
             */
            self.feedbackTask = sendFeedback(feedback)
            
            if self.feedbackTask != nil {
                // We have a valid URL Session Task, so start it to send
                self.feedbackTask!.resume()
            } else {
                // Report the error
                sendFeedbackError()
            }
            
            return
        }
        
        // No feedback, so close the sheet
        self.window.endSheet(self.reportWindow)
        
        // FROM 1.2.5
        // Restore menus
        showPanelGenerators()
        
        // NOTE sheet closes asynchronously unless there was no feedback to send,
        //      or an error occured with setting up the feedback session
    }


    // MARK: - NSTextFieldDelegate Functions
    
    func controlTextDidChange(_ note: Notification) {
        
        // Trap text changes so that no more than
        // can be entered into the text field

        if self.feedbackText.stringValue.count > BUFFOON_CONSTANTS.MAX_FEEDBACK_SIZE {
            // Prune the feedback to kMaxFeedbackCharacters chars
            let edit: Substring = self.feedbackText.stringValue.prefix(BUFFOON_CONSTANTS.MAX_FEEDBACK_SIZE)
            self.feedbackText.stringValue = String(edit)
            
            // Tell the user about the limit by flashing the
            // text field red and back
            flashField()
        }
        
        // Set the text length label
        self.messageSizeLabel.stringValue = "\(self.feedbackText.stringValue.count)/\(BUFFOON_CONSTANTS.MAX_FEEDBACK_SIZE)"
    }


    /**
     Briefly set the Text Field's background to red.
     */
    func flashField() {
        
        // Set the background to colour red
        self.feedbackText.backgroundColor = .red
        
        // Switch the background back in 0.25 of a second
        _ = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { (timer) in
            self.feedbackText.backgroundColor = nil
        })
    }
}
