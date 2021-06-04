/*
 *  ThemeTableCellView.swift
 *  PreviewCode
 *
 *  Created by Tony Smith on 30/05/2021.
 *  Copyright © 2021 Tony Smith. All rights reserved.
 */


import Cocoa


class ThemeTableCellView: NSTableCellView {

    // MARK:- Class UI Properies
    
    @IBOutlet var themePreviewTitle: NSTextField!
    
    // MARK: - Public Properties
    
    // Record the table row the cell view is placed at
    var rowValue: Int = -1
    
}
