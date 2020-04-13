//
//  Toast.swift
//  ReasonML
//
//  Created by Jacob Parker on 13/04/2020.
//  Copyright © 2020 Jacob Parker. All rights reserved.
//

import SwiftUI

struct Toast: View {
    let message: String
    let label: String?
    let action: (() -> Void)?
    
    init(_ message: String) {
        self.message = message
        self.label = nil
        self.action = nil
    }
    
    init(_ message: String, label: String, action: @escaping () -> Void) {
        self.message = message
        self.label = label
        self.action = action
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(message)
            .lineLimit(nil)
            
            if label != nil && action != nil {
                Button(label!, action: action!)
            }
        }
        .padding()
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .background(Color(.quaternarySystemFill))
    }
}

struct Toast_Previews: PreviewProvider {
    static var previews: some View {
        Toast("Hello world")
    }
}
