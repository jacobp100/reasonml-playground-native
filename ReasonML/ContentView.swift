//
//  ContentView.swift
//  ReasonML
//
//  Created by Jacob Parker on 12/04/2020.
//  Copyright © 2020 Jacob Parker. All rights reserved.
//

import SwiftUI
import Introspect

struct ContentView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.pixelLength) var pixelLength: CGFloat
    
    @State var file = File()
    @State var mode = Mode.language(.reason)
    
    var body: some View {
        VStack(spacing: 0) {
            Header(file: file, mode: $mode, hideConsole: horizontalSizeClass == .regular)
            .padding()
            
            HStack(spacing: 0) {
                MainContent(file: file, mode: mode)
                
                if horizontalSizeClass == .regular {
                    Divider()
                    
                    ConsoleEntries(file: file)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
