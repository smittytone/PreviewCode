/*
 *  AppDelegateFeedback.swift
 *  PreviewCode
 *  Extension for AppDelegate providing feedback handling functionality.
 *
 *  Created by Tony Smith on 18/07/2025.
 *  Copyright © 2026 Tony Smith. All rights reserved.
 */

import AppKit


extension AppDelegate {

    /**
     Set up the UI for the first time.

     FROM 2.0.0
     */
    internal func initialiseFeedback() {

        // Reset the UI
        self.connectionProgress.stopAnimation(self)
        self.feedbackText.stringValue = ""
        self.messageSizeLabel.stringValue = "0/512"
        self.messageSendButton.isEnabled = false
    }


    /**
     Update UI when we are about to switch to it.

     // FROM 2.0.0
     */
    internal func willShowFeedbackPage() {

        // Disable the Feedback > Send button if we have sent a message.
        // It will be re-enabled by typing something
        self.messageSendButton.isEnabled = (!self.feedbackText.stringValue.isEmpty && !self.hasSentFeedback)

        // Make the text field the first responder
        //self.themeTable.resignFirstResponder()
        //self.window.makeFirstResponder(self.feedbackText)
        self.feedbackText.currentEditor()?.beginDocument()
    }


    /**
     Check if feedback has been entered and, if so, whether it has been sent.

     FROM 2.0.0

     - Returns: `true` if there is feedback to warn the user about, otherwise `false`.
     */
    internal func checkFeedbackOnQuit() -> Bool {

        // If the user has never accessed the page
        if self.feedbackText.stringValue.isEmpty || self.hasSentFeedback {
            return false
        }

        return true
    }


    /**
     User has clicked the `Send` button.

     Get the message (if there is one) from the text field and submit it.
     
     - Parameters:
        - sender: The source of the action.
     */
    @IBAction
    @objc
    private func doSendFeedback(sender: Any) {

        let feedback: String = self.feedbackText.stringValue
        if !feedback.isEmpty  && !self.hasSentFeedback {
            // FROM 2.2.4
            // Use Swift Concurrency
            // NOTE Use of Task and closure required because @IBAction functions cannot be `async`,
            //      but we make an `await` call later on
            Task { @MainActor in
                // Start the connection indicator if it's not already visible,
                // and block tab switching via menus
                self.connectionProgress.startAnimation(self)
                hidePanelGenerators()

                // Post the feedback asynchronously
                let error: FeedbackError = await self.nuSendFeedback(feedback)
                self.connectionProgress.stopAnimation(self)
                if error.code != .noError {
                    // Error - inform the user
                    presentFeedbackError(error)
                } else {
                    // No error - feedback sent successfully
                    presentFeedbackSuccess()
                }
            }
        }
    }


    // MARK: - Alert Functions

    /**
     Present an error message specific to sending feedback.

     - Parameters:
        - error - An Error of type struct FeedbackError.
     */
    internal func presentFeedbackError(_ error: FeedbackError) {

        let alert: NSAlert = showAlert("Feedback Could Not Be Sent",
                                       "Unfortunately, your comments could not be send at this time. Please try again later.\n\nReason: \(error.localizedDescription)")
        alert.beginSheetModal(for: self.window) { (resp) in
            // FROM 2.2.4
            // Run call on main thread using Swift Concurrency
            Task {
                @MainActor in
                    self.showPanelGenerators()
            }
        }
    }


    /**
     Present a message on successfully sending feedback.

     FROM 2.2.4
     */
    internal func presentFeedbackSuccess() {

        let alert: NSAlert = showAlert("Thanks For Your Feedback!",
                                       "Your comments have been received and we’ll take a look at them shortly.")
        alert.beginSheetModal(for: self.window) { (resp) in
            // Close the feedback window when the modal alert returns
            let _: Timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { timer in
                // Run call on main thread using Swift Concurrency
                Task {
                    @MainActor in
                        self.showPanelGenerators()
                        self.hasSentFeedback = true
                        self.messageSendButton.isEnabled = false
                }
            }
        }
    }


    // MARK: - NSTextFieldDelegate Functions

    func controlTextDidChange(_ note: Notification) {
        
        // Trap text changes so that no more than
        // can be entered into the text field

        if self.feedbackText.stringValue.count > BUFFOON_CONSTANTS.MAX_FEEDBACK_SIZE {
            // FROM 2.2.4
            // Chop the feedback field's attributed string, not its plain string
            let attStr = NSMutableAttributedString(attributedString: self.feedbackText.attributedStringValue)
            attStr.deleteCharacters(in: NSRange(location: BUFFOON_CONSTANTS.MAX_FEEDBACK_SIZE, length: attStr.length - BUFFOON_CONSTANTS.MAX_FEEDBACK_SIZE))
            self.feedbackText.attributedStringValue = attStr as NSAttributedString

            // Tell the user about the limit by flashing the
            // text field red and back
            self.flashField()
        }

        // Set the button title according to the amount of feedback text
        self.messageSendButton.isEnabled = !self.feedbackText.stringValue.isEmpty
        if self.hasSentFeedback {
            self.hasSentFeedback = false
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
            // FROM 2.2.4
            // Migrate to Swift Concurrency
            Task {
                @MainActor in
                self.feedbackText.backgroundColor = .white
            }
        })
    }



    // MARK: - URLSession Delegate Functions

    /*
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {

        // Some sort of connection error - report it
        self.connectionProgress.stopAnimation(self)
        sendFeedbackError()
    }


    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {

        // The operation to send the comment completed
        self.connectionProgress.stopAnimation(self)
        if let _ = error {
            // An error took place - report it
            sendFeedbackError()
        } else {
            // The comment was submitted successfully
            let alert: NSAlert = showAlert("Thanks For Your Feedback!",
                                           "Your comments have been received and we’ll take a look at them shortly.")
            alert.beginSheetModal(for: self.window) { (resp) in
                // Close the feedback window when the modal alert returns
                let _: Timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { timer in
                    // FROM 2.2.4
                    // Run call on main thread using Swift Concurrency
                    Task {
                        @MainActor in
                            //self.window.endSheet(self.window)
                            self.showPanelGenerators()
                            self.hasSentFeedback = true
                            self.messageSendButton.isEnabled = false
                    }
                }
            }
        }
    }
     */
}
