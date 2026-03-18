/*
 *  Entities.swift
 *
 *  Created by Tony Smith on 18/03/2026.
 *  Copyright © 2026 Tony Smith. All rights reserved.
 */

import Foundation


public struct FeedbackError: Error, LocalizedError {

    public var code: FeedbackErrorKind                 = .noError
    public var text: String?                           = nil
    public var errorDescription: String? {
        switch self.code {
            case .noError:
                return nil
            case .badEncode:
                return "could not encode the feedback"
            case .badResponse:
                return "received a bad response from the feedback server"
            case .badStatusCode:
                if let text = self.text {
                    return "received a bad status code (\(text)) from the feedback server"
                } else {
                    return "received a bad status code from the feedback server"
                }
            case .badSession:
                return "could not connect to the feedback server — please check your WiFi"
            case .badErrorUnknown:
                return "unknown"
            }
        }
}


public enum FeedbackErrorKind: Int, Error {

    case noError                                = 0
    case badResponse                            = 1
    case badStatusCode                          = 2
    case badSession                             = 3
    case badEncode                              = 4
    case badErrorUnknown                        = 5
}
