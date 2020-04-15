//
//  MainContent.swift
//  ReasonML
//
//  Created by Jacob Parker on 15/04/2020.
//  Copyright © 2020 Jacob Parker. All rights reserved.
//

import SwiftUI

struct MainContent: View {
    @ObservedObject var file: File
    var mode: Mode
    
    var body: some View {
        VStack(spacing: 0) {
            if mode.language == file.language {
                TextEditor(
                    source: $file.source,
                    errorLocation: file.compilationError?.location,
                    isEditable: true,
                    onFormat: { self.file.format() }
                )
                .edgesIgnoringSafeArea(.bottom)
            } else if mode.language != nil {
                TextEditor(
                    source: .constant(self.file.source(translatedTo: mode.language!) ?? ""),
                    isEditable: false
                )

                Toast(
                    message: "You are in a \(file.language) project. To edit, you'll need to convert your project.",
                    label: "Convert project to \(self.mode.language!)"
                ) {
                    self.file.convert(to: self.mode.language!)
                }
                .padding(.horizontal)
                .padding(.bottom)
            } else if mode == .javascript {
                TextEditor(source: $file.javascript, isEditable: false)
                .edgesIgnoringSafeArea(.bottom)
            } else if mode == .console {
                ConsoleEntries(file: file)
                .edgesIgnoringSafeArea(.bottom)
            }
        }
    }
}

struct MainContent_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
    }
}

fileprivate extension Mode {
    var language: File.Language? {
        switch self {
        case .language(let language): return language
        default: return nil
        }
    }
}
