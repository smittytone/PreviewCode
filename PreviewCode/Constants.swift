/*
 *  Constants.swift
 *  PreviewCode
 *
 *  Created by Tony Smith on 30/05/2021.
 *  Copyright © 2021 Tony Smith. All rights reserved.
 */

// Combine the app's various constants into a struct
import Foundation


struct BUFFOON_CONSTANTS {

    struct ERRORS {

        struct CODES {
            static let NONE                 = 0
            static let FILE_INACCESSIBLE    = 400
            static let FILE_WONT_OPEN       = 401
            static let BAD_MD_STRING        = 402
            static let BAD_TS_STRING        = 403
        }

        struct MESSAGES {
            static let NO_ERROR             = "No error"
            static let FILE_INACCESSIBLE    = "Can't access file"
            static let FILE_WONT_OPEN       = "Can't open file"
            static let BAD_MD_STRING        = "Can't get source code"
            static let BAD_TS_STRING        = "Can't access NSTextView's TextStorage"
        }
    }

    struct THUMBNAIL_SIZE {

        static let ORIGIN_X                 = 0
        static let ORIGIN_Y                 = 0
        static let WIDTH                    = 768
        static let HEIGHT                   = 1024
        static let ASPECT                   = 0.75
        static let TAG_HEIGHT               = 180
    }

    static let BASE_PREVIEW_FONT_SIZE       = 16.0
    static let BASE_THUMB_FONT_SIZE         = 24.0
    static let THEME_PREVIEW_FONT_SIZE      = 7.0

    static let FONT_SIZE_OPTIONS: [CGFloat] = [10.0, 12.0, 14.0, 16.0, 18.0, 24.0, 28.0]
    
    static let DEFAULT_THEME                = "dark.agate"
    static let DEFAULT_FONT                 = "menlo"
    static let DEFAULT_LANGUAGE_UTI         = "swift-source"
    static let DEFAULT_LANGUAGE             = "swift"
    static let DEFAULT_THUMB_THEME          = "light.atom-one-light"
    
    static let FILE_CODE_SAMPLE             = "code-sample"
    static let FILE_THEME_LIST              = "themes-list"
    
    static let TAG_TEXT_SIZE                = 146
    static let TAG_TEXT_MIN_SIZE            = 118
    
    static let SUITE_NAME                   = ".suite.preview-code"
    static let APP_STORE                    = ""
    static let MAIN_URL                     = "https://smittytone.net/previewcode/index.html"
}
