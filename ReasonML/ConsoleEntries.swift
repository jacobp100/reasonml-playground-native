//
//  ConsoleEntries.swift
//  ReasonML
//
//  Created by Jacob Parker on 13/04/2020.
//  Copyright © 2020 Jacob Parker. All rights reserved.
//

import Foundation
import SwiftUI

fileprivate func fragment(
    for value: ConsoleEntry.Value,
    collapse: Bool
) -> Text {
    let canCollapse = collapse && (value.format == .array || value.format == .object)
    let shouldCollaspe = canCollapse && value.description.count > 30
    let description = shouldCollaspe
        ? "\(value.description.prefix(20))..."
        : value.description
    
    return Text(description)
        .foregroundColor(Color(value.format.foreground))
}

struct ConsoleEntryOverview: View {
    var part: ConsoleEntry.Part
    
    func section(for value: ConsoleEntry.Value) -> some View {
        Section(header: Text(String("\(value.format)"))) {
            fragment(for: value, collapse: false)
            .contextMenu {
                Button("Copy") {
                    UIPasteboard.general.string = "\(value)"
                }
            }
        }
    }
    
    var body: some View {
        List {
            section(for: part.label)
            
            ForEach(part.alternate ?? []) {
                self.section(for: $0)
            }
        }
        .listStyle(GroupedListStyle())
    }
}

struct ConsoleEntries: View {
    @ObservedObject var file: File
    @State var entry: ConsoleEntry? = nil
    
    func message(for entry: ConsoleEntry) -> Text {
        let parts = entry.parts.reduce(nil) { (accum: Text?, part) in
            let text = fragment(for: part.label, collapse: true)
            
            if let current = accum {
                return current + Text(" ") + text
            } else {
                return text
            }
        }
        
        return parts ?? Text("")
    }
    
    var body: some View {
        List(file.console) { entry in
            HStack {
                self.message(for: entry)
                
                Spacer()
                
                Image(systemName: entry.level.systemName)
                .foregroundColor(Color(entry.level.tintColor))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                self.entry = entry
            }
            .contextMenu {
                Button("Copy") {
                    UIPasteboard.general.string = "\(entry)"
                }
            }
        }
        .introspectTableView { tableView in
            tableView.separatorColor = .clear
        }
        .sheet(item: $entry) { entry in
            NavigationView {
                List(entry.parts) { part in
                    NavigationLink(
                        destination: ConsoleEntryOverview(part: part)
                            .navigationBarItems(trailing: Button("Close") {
                                self.entry = nil
                            })
                    ) {
                        fragment(for: part.label, collapse: true)
                    }
                }
                .navigationBarTitle(Text(String("Console \(entry.level)")))
                .navigationBarItems(trailing: Button("Close") {
                    self.entry = nil
                })
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

fileprivate extension ConsoleEntry.Level {
    var systemName: String {
        switch self {
        case .log: return "info.circle"
        case .warn: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }
    
    var tintColor: UIColor {
        switch self {
        case .log: return .systemBlue
        case .warn: return .systemYellow
        case .error: return .systemRed
        }
    }
}

fileprivate extension ConsoleEntry.Format {
    var foreground: UIColor {
        switch self {
        case .other: return .label
        case .string: return .label
        case .number: return .systemBlue
        case .boolean: return .systemPurple
        case .null: return .systemIndigo
        case .undefined: return .systemIndigo
        case .array: return .systemOrange
        case .object: return .systemOrange
        case .list: return .systemOrange
        }
    }
}
