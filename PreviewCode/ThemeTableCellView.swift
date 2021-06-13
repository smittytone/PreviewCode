/*
 *  ThemeTableCellView.swift
 *  PreviewCode
 *
 *  Created by Tony Smith on 30/05/2021.
 *  Copyright © 2021 Tony Smith. All rights reserved.
 */


import Cocoa


/**
    A very basic subclass so we can store useful info within the cell.
*/

class ThemeTableCellView: NSTableCellView {

    // MARK:- Class UI Properies
    
    @IBOutlet var themePreviewTitle: NSTextField!
    
    // MARK: - Public Properties
    
    // Record the table row the cell view is placed at
    var themeIndex: Int = -1
    
}
