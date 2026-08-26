/*
 *  PAAppDelegateMisc.swift
 *  PreviewApps
 *  Extension for AppDelegate providing functionality used across PreviewApps.
 *
 *  These functions can be used by all PreviewApps
 *
 *  Created by Tony Smith on 18/06/20214.
 *  Copyright © 2026 Tony Smith. All rights reserved.
 */


import AppKit
import WebKit
import UniformTypeIdentifiers


extension AppDelegate {

    // MARK: - Alert Handler Functions

    /**
     Generic alert generator.

     - Parameters:
        - head:        The alert's title.
        - message:     The alert's message.
        - addOkButton: Should we add an OK button?
        - isCritical:  Should we make this a crirical alert

     - Returns: The NSAlert.
     */
    internal func makeAlert(_ head: String, _ message: String, _ addOkButton: Bool = true, _ isCritical: Bool = false) -> NSAlert {

        let alert = NSAlert()
        alert.messageText = head
        alert.informativeText = message
        if addOkButton { alert.addButton(withTitle: "OK") }
        if isCritical { alert.alertStyle = .critical }
        return alert
    }


    // MARK: - Data Generator Functions

    /**
     Build a basic 'major-manor' version string for prefs usage.

     - Returns: The version string.
     */
    internal func getVersion() -> String {

        let bundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown.unknown"
        let parts = bundleVersion.components(separatedBy: ".")
        return parts.joined(separator: "-")
    }


    /**
     Build a date string string for feedback usage.

     - Returns: The date string.
     */
    internal func getFeedbackDate() -> String {

        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter.string(from: date)
    }


    /**
     Build a user-agent string string for feedback usage.

     - Returns: The user-agent string.
     */
    internal func getUserAgent() -> String {

        let sysVer = ProcessInfo.processInfo.operatingSystemVersion
        let bundle = Bundle.main
        let app = bundle.object(forInfoDictionaryKey: "CFBundleExecutable") as? String ?? BUFFOON_CONSTANTS.APP_NAME
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
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

        var localUTI = "NONE"
        let samplePath = Bundle.main.resourcePath! + "/" + filename

        if FileManager.default.fileExists(atPath: samplePath) {
            // Create a URL reference to the sample file
            // NOTE Call below is DEPRECATED, but replacement requires macOS 13
            let sampleURL = URL(fileURLWithPath: samplePath)
            if let uti = try? sampleURL.resourceValues(forKeys: [.contentTypeKey]).contentType {
                localUTI = uti.identifier
            }
        }

        return localUTI
    }


    // MARK: - Support Functions

    /**
     Disable all panel-opening menu items.
     */
    internal func hidePanelGenerators() {

        self.helpMenuWhatsNew.isEnabled = false
        self.mainMenuSettings.isEnabled = false
        localHides()
    }


    /**
     Enable all panel-opening menu items.
     */
    internal func showPanelGenerators() {

        self.helpMenuWhatsNew.isEnabled = true
        self.mainMenuSettings.isEnabled = true
        localShows()
    }


    func applicationSupportsSecureRestorableState() -> Bool {

        return true
    }


    // MARK: - WKWebNavigation Delegate Functions

    /**
     Asynchronously show the sheet once the HTML has loaded
     (triggered by delegate method)
     */
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {

        if let nav = self.whatsNewNav {
            if nav == navigation {
                // Display the sheet after a timer to prevent the 'white flash' of the default view
                // background appearing for a moment before the new content is rendered
                let _ = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { timer in
                    timer.invalidate()

                    Task { @MainActor in
                        self.window.beginSheet(self.whatsNewWindow, completionHandler: nil)
                    }
                }
            }
        }
    }


    // MARK: - NSWindowDelegate Functions

    /**
      Catch when the user clicks on the window's red close button.
     */
    public func windowShouldClose(_ sender: NSWindow) -> Bool {

        if !checkFeedbackOnQuit() && !checkSettingsOnQuit() {
            // No unsaved settings or unsent feedback, so we're good to close
            return true
        }

        // Close mmanually
        // NOTE The above check will fail if there are settings changes and/or
        //      unsent feedback, in which case the following calls will trigger
        //      alerts
        doClose(self)
        return false
    }

}
