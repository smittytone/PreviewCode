//
//  PCAppDelegateMisc.swift
//  PreviewCode
//
//  Created by Tony Smith on 21/08/2026.
//

import AppKit

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

}
