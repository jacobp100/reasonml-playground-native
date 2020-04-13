//
//  ConsoleEntries.swift
//  ReasonML
//
//  Created by Jacob Parker on 13/04/2020.
//  Copyright © 2020 Jacob Parker. All rights reserved.
//

import SwiftUI

struct ConsoleEntries: View {
    let entries: [ConsoleEntry]
    
    var body: some View {
        List(entries) { (consoleEntry: ConsoleEntry) in
            HStack {
                Image(systemName: consoleEntry.systemName)
                .foregroundColor(Color(consoleEntry.tintColor))
                
                Text(consoleEntry.message)
            }
        }
    }
}

struct ConsoleEntries_Previews: PreviewProvider {
    static var previews: some View {
        ConsoleEntries(entries: [])
    }
}

fileprivate extension ConsoleEntry {
    var systemName: String {
        switch self.level {
        case .log: return "info.circle"
        case .warn: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }
    
    var tintColor: UIColor {
        switch self.level {
        case .log: return .systemBlue
        case .warn: return .systemYellow
        case .error: return .systemRed
        }
    }
}
