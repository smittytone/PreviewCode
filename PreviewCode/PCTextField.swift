/*
 *  PCTextField.swift
 *  PreviewCode
 *
 *  Created by Tony Smith on 29/08/2025.
 *  Copyright © 2025 Tony Smith. All rights reserved.
 */

import AppKit


/**
 Subclass NSTableRowView so we can make sure that auto-selected rows in the `Settings` tab's
 theme table are correctly focused. Click to focus always works anyway.

*/

class PCTextField: NSTextField {

    override var acceptsFirstResponder: Bool {
        get {
            return true
        }
    }

}

