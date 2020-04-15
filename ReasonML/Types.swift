//
//  Types.swift
//  ReasonML
//
//  Created by Jacob Parker on 15/04/2020.
//  Copyright © 2020 Jacob Parker. All rights reserved.
//

import Foundation

enum Mode: Equatable, Hashable {
    case language(File.Language)
    case javascript
    case console
}

extension Mode: CustomStringConvertible {
    var description: String {
        switch self {
        case .language(let language): return "\(language)"
        case .javascript: return "JavaScript"
        case .console: return "Console"
        }
    }
}
