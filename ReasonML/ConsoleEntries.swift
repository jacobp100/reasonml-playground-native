//
//  ConsoleEntries.swift
//  ReasonML
//
//  Created by Jacob Parker on 13/04/2020.
//  Copyright © 2020 Jacob Parker. All rights reserved.
//

import SwiftUI

struct ConsoleEntries: View {
    @ObservedObject var file: File
    
    var body: some View {
        List(file.console) { consoleEntry in
            HStack {
                Image(systemName: consoleEntry.systemName)
                .foregroundColor(Color(consoleEntry.tintColor))
                
                Text(consoleEntry.message)
            }
            .contextMenu {
                Button("Copy") {
                    UIPasteboard.general.string = consoleEntry.message
                }
            }
        }
        .introspectTableView { tableView in
            tableView.separatorColor = .clear
        }
    }
}

//struct ConsoleEntries_Previews: PreviewProvider {
//    static var previews: some View {
//        EmptyView()
//    }
//}

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
