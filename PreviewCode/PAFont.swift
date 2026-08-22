/*
 *  PAFont.swift
 *  PreviewApps
 *
 *  Created by Tony Smith on 02/07/2021.
 *  Copyright © 2026 Tony Smith. All rights reserved.
 */


import Foundation


/**
 Internal font record structure.
 */

struct PAFont {

    var postScriptName: String = ""
    var displayName: String = ""
    var styleName: String = ""
    var traits: UInt = 0
    var styles: [PAFont]? = nil
}
