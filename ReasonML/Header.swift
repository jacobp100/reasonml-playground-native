//
//  Header.swift
//  ReasonML
//
//  Created by Jacob Parker on 15/04/2020.
//  Copyright © 2020 Jacob Parker. All rights reserved.
//

import Foundation
import SwiftUI

struct Header: View {
    @ObservedObject var file: File
    @Binding var mode: Mode
    var hideConsole: Bool
    @State var errorVisible = false
    
    var body: some View {
        HStack {
            ModePicker(mode: $mode, hideConsole: hideConsole)
            
            Spacer()
            
            if file.compilationError != nil {
                Button(action: {
                    self.errorVisible = true
                }) {
                    Text("Error")
                    Image(systemName: "exclamationmark.circle.fill")
                }
            }
        }
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
