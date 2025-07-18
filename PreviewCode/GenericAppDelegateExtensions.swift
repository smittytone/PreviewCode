/*
 *  GenericExtensions.swift
 *  PreviewApps
 *
 *  These functions can be used by all PreviewApps
 *
 *  Created by Tony Smith on 18/06/2021.
 *  Copyright © 2025 Tony Smith. All rights reserved.
 */


import Foundation
import Cocoa
import WebKit
import UniformTypeIdentifiers


extension AppDelegate {

    // MARK: - Process Handling Functions

    /**
     Generic macOS process creation and run function.

     Make sure we clear the preference flag for this minor version, so that
     the sheet is not displayed next time the app is run (unless the version changes)

     - Parameters:
        - app:  The location of the app.
        - with: Array of arguments to pass to the app.

     - Returns: `true` if the operation was successful, otherwise `false`.
     */
    internal func runProcess(app path: String, with args: [String]) -> Bool {

        let task: Process = Process()
        task.executableURL = URL.init(fileURLWithPath: path)
        task.arguments = args

        // Pipe out the output to avoid putting it in the log
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = outputPipe

        do {
            try task.run()
        } catch {
            return false
        }

        // Block until the task has completed (short tasks ONLY)
        task.waitUntilExit()

        if !task.isRunning {
            if (task.terminationStatus != 0) {
                // Command failed -- collect the output if there is any
                let outputHandle = outputPipe.fileHandleForReading
                var outString: String = ""
                if let line = String(data: outputHandle.availableData, encoding: String.Encoding.utf8) {
                    outString = line
                }

                if outString.count > 0 {
                    print("\(outString)")
                } else {
                    print("Error", "Exit code \(task.terminationStatus)")
                }
                return false
            }
        }

        return true
    }


    // MARK: - Misc Functions

    /**
     Present an error message specific to sending feedback.

     This is called from multiple locations: if the initial request can't be created,
     there was a send failure, or a server error.
     */
    internal func sendFeedbackError() {

        let alert: NSAlert = showAlert("Feedback Could Not Be Sent",
                                       "Unfortunately, your comments could not be send at this time. Please try again later.")
        alert.beginSheetModal(for: self.reportWindow) { (resp) in
            self.window.endSheet(self.reportWindow)
            self.showPanelGenerators()
        }
    }


    /**
     Generic alert generator.

     - Parameters:
        - head:        The alert's title.
        - message:     The alert's message.
        - addOkButton: Should we add an OK button?

     - Returns:     The NSAlert.
     */
    internal func showAlert(_ head: String, _ message: String, _ addOkButton: Bool = true) -> NSAlert {

        let alert: NSAlert = NSAlert()
        alert.messageText = head
        alert.informativeText = message
        if addOkButton { alert.addButton(withTitle: "OK") }
        return alert
    }


    /**
     Build a basic 'major.manor' version string for prefs usage.

     - Returns: The version string.
     */
    internal func getVersion() -> String {

        let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let parts: [String] = (version as NSString).components(separatedBy: ".")
        return parts[0] + "-" + parts[1]
    }


    /**
     Build a date string string for feedback usage.

     - Returns: The date string.
     */
    internal func getDateForFeedback() -> String {

        let date: Date = Date()
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter.string(from: date)
    }


    /**
     Build a user-agent string string for feedback usage.

     - Returns: The user-agent string.
     */
    internal func getUserAgentForFeedback() -> String {

        // Refactor code out into separate function for clarity

        let sysVer: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
        let bundle: Bundle = Bundle.main
        let app: String = bundle.object(forInfoDictionaryKey: "CFBundleExecutable") as! String
        let version: String = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let build: String = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        return "\(app)/\(version)-\(build) (macOS/\(sysVer.majorVersion).\(sysVer.minorVersion).\(sysVer.patchVersion))"
    }


    /**
     Read back the host system's registered UTI for the specified file.
     
     This is not PII. It used solely for debugging purposes
     
     - Parameters:
        - filename: The file we'll use to get the UTI.
     
     - Returns: The file's UTI.
     */
    internal func getLocalFileUTI(_ filename: String) -> String {
        
        var localUTI: String = "NONE"
        let samplePath = Bundle.main.resourcePath! + "/" + filename
        
        if FileManager.default.fileExists(atPath: samplePath) {
            // Create a URL reference to the sample file
            let sampleURL = URL.init(fileURLWithPath: samplePath)
            
            do {
                // Read back the UTI from the URL
                // Use Big Sur's UTType API
                if #available(macOS 11, *) {
                    if let uti: UTType = try sampleURL.resourceValues(forKeys: [.contentTypeKey]).contentType {
                        localUTI = uti.identifier
                    }
                } else {
                    // NOTE '.typeIdentifier' yields an optional
                    if let uti: String = try sampleURL.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
                        localUTI = uti
                    }
                }
            } catch {
                // NOP
            }
        }
        
        return localUTI
    }
    
    
    /**
     Disable all panel-opening menu items.
     */
    internal func hidePanelGenerators() {
        
        self.helpMenuReportBug.isEnabled = false
        self.helpMenuWhatsNew.isEnabled = false
        self.mainMenuSettings.isEnabled = false
    }
    
    
    /**
     Enable all panel-opening menu items.
     */
    internal func showPanelGenerators() {
        
        self.helpMenuReportBug.isEnabled = true
        self.helpMenuWhatsNew.isEnabled = true
        self.mainMenuSettings.isEnabled = true
    }
    
    
    /**
     Get system and state information and record it for use during run.
     */
    internal func recordSystemState() {
        
        // First ensure we are running on Mojave or above - Dark Mode is not supported by earlier versons
        let sysVer: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
        self.isMontereyPlus = (sysVer.majorVersion >= 12)
    }
    
    
    /**
     Determine whether the host Mac is in light mode.
     
     - Returns: `true` if the Mac is in light mode, otherwise `false`.
     */
    internal func isMacInLightMode() -> Bool {
        
        let appearNameString: String = NSApp.effectiveAppearance.name.rawValue
        return (appearNameString == "NSAppearanceNameAqua")
    }
    
    
    // MARK: - URLSession Delegate Functions

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
            alert.beginSheetModal(for: self.reportWindow) { (resp) in
                // Close the feedback window when the modal alert returns
                let _: Timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { timer in
                    self.window.endSheet(self.reportWindow)
                    self.showPanelGenerators()
                }
            }
        }
    }


    // MARK: - WKWebNavigation Delegate Functions

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {

        // Asynchronously show the sheet once the HTML has loaded
        // (triggered by delegate method)

        if let nav = self.whatsNewNav {
            if nav == navigation {
                // Display the sheet
                // FROM 1.3.2 -- add timer to prevent 'white flash'
                Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { timer in
                    timer.invalidate()
                    self.window.beginSheet(self.whatsNewWindow, completionHandler: nil)
                }
            }
        }
    }
}


// MARK: -

extension NSApplication {
    
    func isMacInLightMode() -> Bool {
        
        return (self.effectiveAppearance.name.rawValue == "NSAppearanceNameAqua")
    }
}

