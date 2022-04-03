/*
 *  Font.swift
 *  PreviewMarkdown
 *
 *  Created by Tony Smith on 02/07/2021.
 *  Copyright © 2022 Tony Smith. All rights reserved.
 */


import Foundation


/**
    A very basic struct so we can record key font details for the **Preferences** panel.
*/
struct PMFont {

    var postScriptName: String = ""
    var displayName: String = ""
    var styleName: String = ""
    var traits: UInt = 0
    var styles: [PMFont]? = nil
}
