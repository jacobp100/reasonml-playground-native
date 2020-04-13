//
//  ContentView.swift
//  ReasonML
//
//  Created by Jacob Parker on 12/04/2020.
//  Copyright © 2020 Jacob Parker. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    enum Mode: Equatable, Hashable {
        case language(File.Language)
        case javascript
        case console
        
        var language: File.Language? {
            switch self {
            case .language(let language): return language
            default: return nil
            }
        }
    }
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.pixelLength) var pixelLength: CGFloat
    
    @ObservedObject var file = File()
    @State var mode = Mode.language(.reason)
    @State var errorVisible = false
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                Picker(selection: $mode, label: Text("Language")) {
                    Text("Reason").tag(Mode.language(.reason))
                    Text("OCaml").tag(Mode.language(.ocaml))
                    Text("JavaScript").tag(Mode.javascript)
                    
                    if horizontalSizeClass == .compact {
                        Text("Console").tag(Mode.console)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                if mode.language == file.language {
                    TextEditor(
                        source: $file.source,
                        isEditable: true,
                        onFormat: { self.file.format() }
                    )
                } else if mode.language != nil {
                    TextEditor(
                        source: .constant(self.file.source(translatedTo: mode.language!) ?? ""),
                        isEditable: false
                    )
                } else if mode == .javascript {
                    TextEditor(source: $file.javascript, isEditable: false)
                } else if mode == .console {
                    ConsoleEntries(entries: file.console)
                }
                
                if mode != .console && file.compilationError != nil {
                    Toast("😱 Failed to compile", label: "View build output") {
                        self.errorVisible = true
                    }
                } else if mode.language != nil && mode.language != file.language {
                    Toast(
                        "✏️ You are in a \(file.language) project. To edit, you'll need to convert your project.",
                        label: "Convert project to \(self.mode.language!)"
                    ) {
                        self.file.convert(to: self.mode.language!)
                    }
                } else if mode == .javascript {
                    Toast("🔍 Viewing in read only mode")
                }
            }
            
            if horizontalSizeClass == .regular {
                Divider()
                
                ConsoleEntries(entries: file.console)
            }
        }
        .sheet(isPresented: $errorVisible) {
            NavigationView {
                ScrollView {
                    Text(self.file.compilationError ?? "")
                    .lineLimit(nil)
                    .padding()
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
                }
                .navigationBarTitle("Build Output")
                .navigationBarItems(trailing: Button("Close") {
                    self.errorVisible = false
                })
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

extension ContentView.Mode: CustomStringConvertible {
    var description: String {
        switch self {
        case .language(let language): return "\(language)"
        case .javascript: return "JavaScript"
        case .console: return "Console"
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
