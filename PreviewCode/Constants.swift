/*
 *  Constants.swift
 *  PreviewCode
 *
 *  Created by Tony Smith on 30/05/2021.
 *  Copyright © 2025 Tony Smith. All rights reserved.
 */

import Foundation


/*
 * Combine the app's various constants into a struct
 */
struct BUFFOON_CONSTANTS {

    struct ERRORS {

        struct CODES {
            static let NONE                 = 0
            static let FILE_INACCESSIBLE    = 400
            static let FILE_WONT_OPEN       = 401
            static let BAD_MD_STRING        = 402
            static let BAD_TS_STRING        = 403
            static let BAD_HIGHLIGHTER      = 404
        }

        struct MESSAGES {
            static let NO_ERROR             = "No error"
            static let FILE_INACCESSIBLE    = "Can't access file"
            static let FILE_WONT_OPEN       = "Can't open file"
            static let BAD_MD_STRING        = "Source code uses an unsupported encoding"
            static let BAD_TS_STRING        = "Can't access NSTextView's TextStorage"
            static let BAD_HIGHLIGHTER      = "Can’t set up the highlighting engine"
        }
    }

    struct THUMBNAIL {

        static let ORIGIN_X                 = 0
        static let ORIGIN_Y                 = 0
        static let WIDTH                    = 768
        static let HEIGHT                   = 1024
        static let ASPECT                   = 0.75
        static let TAG_HEIGHT               = 204.8
        static let LINE_COUNT               = 38
        static let THEME                    = "light.atom-one-light"
        static let FONT_SIZE                = 18.0
    }
    
    struct DISPLAY_MODE {
        
        static let ALL                      = 0 // DEPRECATED - DON'T USE
        static let DARK                     = 1
        static let LIGHT                    = 2
        static let AUTO                     = 3
    }

    struct DEFAULTS {

        static let FONT                 = "Menlo-Regular"
        static let FONT_NAME            = "Menlo"
        static let FONT_SIZE            = 16.0
        static let LINE_SPACING         = 1.0
        static let LANGUAGE_UTI         = "swift-source"
        static let LANGUAGE             = "swift"
        // FROM 2.0.0
        static let DARK_THEME           = "dark.atom-one-dark"
        static let LIGHT_THEME          = "light.atom-one-light"
    }

    struct APP_URLS {
        
        static let PM                       = "https://apps.apple.com/us/app/previewmarkdown/id1492280469?ls=1"
        static let PC                       = "https://apps.apple.com/us/app/previewcode/id1571797683?ls=1"
        static let PY                       = "https://apps.apple.com/us/app/previewyaml/id1564574724?ls=1"
        static let PJ                       = "https://apps.apple.com/us/app/previewjson/id6443584377?ls=1"
        static let PT                       = "https://apps.apple.com/us/app/previewtext/id1660037028?ls=1"
    }

    struct PREFS_IDS {
        
        static let MAIN_WHATS_NEW               = "com-bps-previewcode-do-show-whats-new-"
        static let PREVIEW_FONT_SIZE            = "com-bps-previewcode-base-font-size"
        static let PREVIEW_FONT_NAME            = "com-bps-previewcode-base-font-name"
        static let PREVIEW_LINE_SPACING         = "com-bps-previewcode-line-spacing"
        static let PREVIEW_LIGHT_NAME           = "com-bps-previewcode-light-theme-name"
        static let PREVIEW_DARK_NAME            = "com-bps-previewcode-dark-theme-name"
        static let PREVIEW_THEME_MODE           = "com-bps-previewcode-theme-mode"
        // FROM 2.0.0
        static let PREVIEW_SHOW_LINE_NUMBERS    = "com-bps-previewcode-show-line-numbers"
    }
    
    static let PREVIEW_ERR_DOMAIN               = "com.bps.PreviewCode.Code-Previewer"
    static let FILE_CODE_SAMPLE                 = "code-sample"
    static let FILE_THEME_LIST                  = "themes-list"
    static let SUITE_NAME                       = ".suite.preview-code"
    static let APP_STORE                        = "https://apps.apple.com/gb/app/previewcode/id1571797683"
    static let MAIN_URL                         = "https://smittytone.net/previewcode/index.html"
    static let MAX_FEEDBACK_SIZE                = 512
    static let FONT_SIZE_OPTIONS: [CGFloat]     = [10.0, 12.0, 14.0, 16.0, 18.0, 24.0, 28.0]




    /*
     These entries are now no longer used. They are retained here for reference
     *
    struct PREFS_IDS {

        static let PREVIEW_USE_LIGHT            = "com-bps-previewcode-do-use-light"
        static let THUMB_FONT_SIZE              = "com-bps-previewcode-thumb-font-size"
        static let PREVIEW_THEME_NAME           = "com-bps-previewcode-theme-name"
    }
     */
}
