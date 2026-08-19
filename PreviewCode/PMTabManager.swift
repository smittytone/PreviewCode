/*
 *  PMTabManager.swift
 *  PreviewApps
 *
 *  Created by Tony Smith on 30/09/2024.
 *  Copyright © 2026 Tony Smith. All rights reserved.
 */


import AppKit


/**
    Manager class for the tabless NSTabView.
 */

class PMTabManager {

    // MARK: - Public Properties

    var buttons: [NSButton]         = []
    var callbacks: [(()->Void)?]    = []
    var currentIndex: Int           = 0
    weak var parent: AppDelegate?   = nil


    // MARK: - Functions

    /**
     Return the most recently clicked button.

     - Returns The button as an NSButton instance, or `nil`.
     */
    func currentButton() -> NSButton? {

        guard !self.buttons.isEmpty else { return nil }
        guard self.currentIndex >= 0 && self.currentIndex < self.buttons.count else { return nil }
        return self.buttons[self.currentIndex]
    }


    /**
     Process the action of clicking one of the tab manager's buttons.

     - Parameters:
        - button: The NSButton clicked.
     */
    @MainActor
    func buttonClicked(_ button: NSButton) {

        // Check the user isn't just clicking the button for the tab that
        // they're already on. If they do, bail.
        if button == self.buttons[currentIndex] {
            self.buttons[currentIndex].state = .on
            return
        }

        // Make sure we have access to the parent controller
        guard let theAppDelegate = self.parent else {
            return
        }

        // Select the required tab based on the button clicked
        // (this makes sure `button` is within `self.buttons`)
        if let nextIndex = self.buttons.firstIndex(of: button) {
            // Enable the current tab's button and disable the rest
            for i in 0..<self.buttons.count {
                if i != nextIndex {
                    self.buttons[i].state = .off
                } else {
                    self.buttons[i].state = .on
                }
            }

            // Perform tab-specific logic BEFORE switching
            // NOTE The closures are set in the app delegate
            if nextIndex < self.callbacks.count {
                if let handler = self.callbacks[nextIndex] {
                    handler()
                }
            }

            // Select the tab we're going to show
            theAppDelegate.mainTabView.selectTabViewItem(at: nextIndex)
            self.currentIndex = nextIndex
        }
    }


    /**
     Auto-click a button by passing in the 'clicked' button.
     */
    @MainActor
    func programmaticallyClickButton(_ button: NSButton) {

        guard self.buttons.contains(button) else { return }
        buttonClicked(button)
    }


    /**
     Auto-click a button by passing in the index of the 'clicked' button.
     */
    @MainActor
    func programmaticallyClickButton(at index: Int) {

        guard !self.buttons.isEmpty else { return }
        guard index >= 0 && index < self.buttons.count else { return }
        buttonClicked(self.buttons[index])
    }
}
