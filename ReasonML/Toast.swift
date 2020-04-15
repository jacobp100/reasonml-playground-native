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
    let label: String
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(message)
            .lineLimit(nil)

            Button(label, action: action)
        }
        .padding()
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .background(Color(.quaternarySystemFill))
        .cornerRadius(20)
    }
}

struct Toast_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
    }
}
