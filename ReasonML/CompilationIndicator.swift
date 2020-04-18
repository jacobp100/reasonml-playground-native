//
//  Header.swift
//  ReasonML
//
//  Created by Jacob Parker on 15/04/2020.
//  Copyright © 2020 Jacob Parker. All rights reserved.
//

import Foundation
import SwiftUI

struct CompilationIndicator: View {
    @ObservedObject var file: File
    @State var errorVisible = false
    
    var body: some View {
        let disabled = file.compilationError == nil
        
        return Button(action: {
            self.errorVisible = true
        }) {
            Text("Error")
            Image(systemName: "exclamationmark.circle.fill")
        }
        .opacity(disabled ? 0 : 1)
        .disabled(disabled)
        .sheet(isPresented: $errorVisible) {
            NavigationView {
                ScrollView {
                    Text(self.file.compilationError?.message ?? "")
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
