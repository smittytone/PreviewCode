/*
 *  PCThemeTableRowView.swift
 *  PreviewCode
 *
 *  Created by Tony Smith on 29/08/2025.
 *  Copyright © 2026 Tony Smith. All rights reserved.
 */

import AppKit


/**
 Subclass NSTableRowView so we can make sure that auto-selected rows in the `Settings` tab's
 theme table are correctly focused. Click to focus always works anyway.
*/

class PCThemeTableRowView: NSTableRowView {

    override var isEmphasized: Bool {
        get {
            return true
        }

        set {
            // As this property will always return `true`,
            // we don't need to add a setter here.
        }
    }

}

