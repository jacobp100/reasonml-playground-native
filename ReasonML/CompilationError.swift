//
//  CompilationError.swift
//  ReasonML
//
//  Created by Jacob Parker on 18/04/2020.
//  Copyright © 2020 Jacob Parker. All rights reserved.
//

import Foundation

struct CompilationError: Equatable {
    static func == (lhs: CompilationError, rhs: CompilationError) -> Bool {
        lhs.message == rhs.message
    }
    
    fileprivate static let compilationErrorLocationRegex = try? NSRegularExpression(
        pattern: "Preview (\\d+):(\\d+)",
        options: []
    )
    
    let message: String
    let location: (Int, Int)?
    
    init(_ message: String) {
        self.message = message
        
        if let matches = CompilationError.compilationErrorLocationRegex?.matches(
                in: message,
                options: [],
                range: NSRange(location: 0, length: message.utf16.count)
            ),
            let match = matches.first,
            let lineRange = Range(match.range(at: 1), in: message),
            let columnRange = Range(match.range(at: 2), in: message),
            let lineNumber = Int(message[lineRange]),
            let columnNumber = Int(message[columnRange]) {
            self.location = (lineNumber, columnNumber)
        } else {
            self.location = nil
        }
    }
}
