//
//  ModePicker.swift
//  ReasonML
//
//  Created by Jacob Parker on 15/04/2020.
//  Copyright © 2020 Jacob Parker. All rights reserved.
//

import Foundation
import SwiftUI

struct ModePicker: View {
    @Binding var mode: Mode
    var hideConsole: Bool
    
    var body: some View {
        Picker(selection: $mode, label: Text("Language")) {
            Text("RE").tag(Mode.language(.reason))
            Text("ML").tag(Mode.language(.ocaml))
            Text("JS").tag(Mode.javascript)
            
            if !hideConsole {
                Text("$_").tag(Mode.console)
            }
        }
        .introspectSegmentedControl { segmentedControl in
            // https://stackoverflow.com/a/59092590
            for i in 0..<segmentedControl.numberOfSegments  {
                let backgroundSegmentView = segmentedControl.subviews[i]
                backgroundSegmentView.isHidden = true
            }
            
            segmentedControl.selectedSegmentTintColor = self.mode.tintColor
            segmentedControl.setTitleTextAttributes(
                [
                    .font: UIFont.systemFont(ofSize: 14, weight: .heavy),
                    .foregroundColor: UIColor.tertiaryLabel
                ],
                for: .normal
            )
            segmentedControl.setTitleTextAttributes(
                [
                .font: UIFont.systemFont(ofSize: 14, weight: .black),
                    .foregroundColor: self.mode.foregroundColor
                ],
                for: .selected
            )
        }
        .pickerStyle(SegmentedPickerStyle())
        .frame(width: 48 * (hideConsole ? 3 : 4))
    }
}

fileprivate extension UIImage {
    convenience init(color: UIColor, size: CGSize) {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        color.set()
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.fill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        self.init(data: image.pngData()!)!
    }
}

fileprivate extension Mode {
    var tintColor: UIColor {
        switch self {
        case .language(.reason): return UIColor(named: "Tint")!
        case .language(.ocaml): return UIColor(red: 240 / 255, green: 143 / 255, blue: 32 / 255, alpha: 1)
        case .javascript: return UIColor(red: 247 / 255, green: 223 / 255, blue: 50 / 255, alpha: 1)
        case .console: return .label
        }
    }

    var foregroundColor: UIColor {
        switch self {
        case .javascript: return .black
        case .console: return .systemBackground
        default: return .white
        }
    }
}
