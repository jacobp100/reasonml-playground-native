//
//  ConsoleEntries.swift
//  ReasonML
//
//  Created by Jacob Parker on 13/04/2020.
//  Copyright © 2020 Jacob Parker. All rights reserved.
//

import Foundation
import SwiftUI

struct ConsoleEntries: View {
    @ObservedObject var file: File
    @State var entry: ConsoleEntry? = nil
    
    func fragment(
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
    
    func sheet(_ entry: ConsoleEntry) -> some View {
        NavigationView {
            List {
                ForEach(entry.parts) { part in
                    Section {
                        ForEach([part.label] + (part.alternate ?? [])) { value in
                            VStack(alignment: .leading) {
                                Text(value.format.description)
                                .font(.footnote)
                                .foregroundColor(Color(.secondaryLabel))
                                
                                self.fragment(for: value, collapse: false)
                            }
                            .copy(value.description)
                        }
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle(Text(String("Console \(entry.level)")))
            .navigationBarItems(trailing: Button("Close") {
                self.entry = nil
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
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
            .copy("\(entry)")
        }
        .introspectTableView { tableView in
            tableView.separatorColor = .clear
        }
        .sheet(item: $entry, content: self.sheet)
    }
}

fileprivate extension View {
    func copy(_ string: String) -> some View {
        self
        .contextMenu {
            Button("Copy") {
                UIPasteboard.general.string = string
            }
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
