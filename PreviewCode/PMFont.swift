/*
 *  Font.swift
 *  PreviewMarkdown
 *
 *  Created by Tony Smith on 02/07/2021.
 *  Copyright © 2021 Tony Smith. All rights reserved.
 */


import Foundation


struct PMFont {

    var postScriptName: String = ""
    var displayName: String = ""
    var styleName: String = ""
    var traits: UInt = 0
    var styles: [PMFont]? = nil
}
