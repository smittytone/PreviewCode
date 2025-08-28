/*
 *  PMTabManager.swift
 *  PreviewMarkdown
 *
 *  Created by Tony Smith on 30/09/2024.
 *  Copyright © 2025 Tony Smith. All rights reserved.
 */


import AppKit


/**
    Manager class for the tabless NSTabView.
 */

class PMTabManager {

    // MARK: - Public Properties
    
    var buttons: [NSButton] = []
    var callbacks: [(()->Void)?] = []
    var parent: AppDelegate? = nil
    var currentIndex: Int = 0


    // MARK: - Functions
    
    /**
     Return the most recently clicked button.
     
     - Returns The button as an NSButton instance.
     */
    func currentButton() -> NSButton {
        
        return self.buttons[self.currentIndex]
    }


    /**
     Process the action of clicking one of the tab manager's buttons.
     
     - Parameters:
        - button: The NSButton clicked.
     */
    func buttonClicked(_ button: NSButton) {
        
        // Check the user isn't just clicking the button for the tab that
        // they're already on. If they do, bail.
        if button == self.buttons[currentIndex] {
            self.buttons[currentIndex].state = .on
            return
        }

        // Make sure we have access to the parent controller
        guard let appDelegate: AppDelegate = self.parent else {
            return
        }
        
        // Select the required tab based on the button clicked
        if let nextIndex: Int = self.buttons.firstIndex(of: button) {
            self.currentIndex = nextIndex
            
            // Enable the current tab's button and disable the rest
            for i in 0..<self.buttons.count {
                if i != nextIndex {
                    self.buttons[i].state = .off
                } else {
                    self.buttons[i].state = .on
                }
            }
            
            // Perform tab-specific logic BEFORE switching
            // NOTE These closures are set in the app delegate
            switch self.currentIndex {
                case 1:
                    if let handler = self.callbacks[1] {
                        handler()
                    }
                case 2:
                    if let handler = self.callbacks[2] {
                        handler()
                    }
                default: // 0
                    if let handler = self.callbacks[0] {
                        handler()
                    }
            }
            
            // Select the tab we're going to show
            appDelegate.mainTabView.selectTabViewItem(at: nextIndex)
        }
    }


    /**
     Auto-click a button by passing in the 'clicked' button.
     */
    func programmaticallyClickButton(_ button: NSButton) {
        
        buttonClicked(button)
    }


    /**
     Auto-click a button by passing in the index of the 'clicked' button.
     */
    func programmaticallyClickButton(at index: Int) {
        
        buttonClicked(self.buttons[index])
    }
}
