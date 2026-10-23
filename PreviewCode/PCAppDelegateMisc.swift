/*
 *  PCAppDelegateMisc.swift
 *  PreviewCode
 *
 *  Created by Tony Smith on 21/08/2026.
 *  Copyright © 2026 Tony Smith. All rights reserved.
 */

import AppKit
import Highlighter


extension AppDelegate {

    /**
     Disable all panel-opening menu items.
     */
    internal func localHides() {

        self.helpMenuReportBug.isEnabled = false
    }


    /**
     Enable all panel-opening menu items.
     */
    internal func localShows() {

        self.helpMenuReportBug.isEnabled = true
    }


    internal func localApplicationDidFinishLaunching() {

#if DEBUG
        // FROM 1.1.0
        // Use for rendering theme selection graphics
        self.helpMenuRenderThemes.isHidden = false
#endif

#if DEBUG
        // FROM 1.2.0
        // Output language list for debugging
        if let hr = Highlighter() {
            let languages = hr.supportedLanguages()
            print("***** Languages  *****")
            for language in languages {
                print(language)
            }
            print("**********************")
        }
#endif
    }

}
