/*
 *  PMFont.swift
 *  PreviewApps
 *
 *  Created by Tony Smith on 02/07/2021.
 *  Copyright © 2025 Tony Smith. All rights reserved.
 */


import Foundation

/**
 Internal font record structure.
 */

struct PMFont {

    var postScriptName: String = ""         // Individual font PostScript name - font records only
    var displayName: String = ""            // Font family menu display name - family records only
    var styleName: String = ""              // Individual font style name - font records only
    var traits: UInt = 0
    var styles: [PMFont]? = nil
}
