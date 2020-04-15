//
//  TextEditor.swift
//  ReasonML
//
//  Created by Jacob Parker on 12/04/2020.
//  Copyright © 2020 Jacob Parker. All rights reserved.
//

import SwiftUI

class KeyboardAvoidingTextView: UITextView {
    var errorLocation: (Int, Int)?
    
    override func didMoveToWindow() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidResize), name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardDidResize(aNotification: NSNotification) {
//        if !isFirstResponder {
//            return
//        }
//        
//        let info = aNotification.userInfo
//        let infoNSValue = info![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue
//        let keyboardFrame = infoNSValue.cgRectValue.size
//        contentInset = .init(
//            top: 0,
//            left: 0,
//            bottom: keyboardFrame.height,
//            right: 0
//        )
//        scrollIndicatorInsets = contentInset
    }
    
    @objc func keyboardDidShow(aNotification: NSNotification) {
        let info = aNotification.userInfo
        let infoNSValue = info![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue
        let keyboardFrame = infoNSValue.cgRectValue.size
        let bottom = max(keyboardFrame.height - safeAreaInsets.bottom, 0)
        contentInset = .init(top: 0, left: 0, bottom: bottom, right: 0)
        scrollIndicatorInsets = contentInset
    }

    @objc func keyboardWillHide(aNotification:NSNotification) {
        contentInset = .zero
        scrollIndicatorInsets = .zero
    }

    @objc func selectError() {
        if let (lineNumber, columnNumber) = errorLocation {
            let location = text.location(forLine: lineNumber, column: columnNumber)
            selectedRange = NSRange(location: location, length: 0)
        }
    }
}

struct TextEditor: UIViewRepresentable {
    @Binding var source: String
    var errorLocation: (Int, Int)? = nil
    var isEditable = true
    var onFormat: (() -> Void)? = nil
    @State var selection: NSRange? = nil
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> KeyboardAvoidingTextView {
        let uiView = KeyboardAvoidingTextView()
        uiView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        uiView.autocorrectionType = .no
        uiView.autocapitalizationType = .none
        uiView.alwaysBounceVertical = true
        uiView.textContainerInset = .init(top: 10, left: 10, bottom: 10, right: 10)
        
        let cursorPositionItem = UIBarButtonItem(
            title: "",
            style: .plain,
            target: uiView,
            action: #selector(KeyboardAvoidingTextView.selectError)
        )
        let font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .regular)
        cursorPositionItem.setTitleTextAttributes([.font: font], for: [.normal])
        cursorPositionItem.setTitleTextAttributes([.font: font], for: [.disabled])
        
        let toolbar = UIToolbar()
        toolbar.items = [
            UIBarButtonItem(
                image: UIImage(systemName: "wand.and.stars"),
                style: .plain,
                target: context.coordinator,
                action: #selector(Coordinator.format)
            ),
            UIBarButtonItem(
                barButtonSystemItem: .flexibleSpace,
                target: nil,
                action: nil
            ),
            cursorPositionItem,
            UIBarButtonItem(
                barButtonSystemItem: .done,
                target: uiView,
                action: #selector(UIResponder.resignFirstResponder)
            )
        ]
        toolbar.sizeToFit()
        uiView.inputAccessoryView = toolbar
        
        uiView.delegate = context.coordinator
        
        return uiView
    }
    
    func updateUIView(_ uiView: KeyboardAvoidingTextView, context: Context) {
        uiView.errorLocation = errorLocation
        
        uiView.text = source
        uiView.isEditable = isEditable
        
        let toolbar = uiView.inputAccessoryView as? UIToolbar
        toolbar?.isHidden = !isEditable
        toolbar?.tintColor = uiView.tintColor
        
        if let selection = selection,
            let cursorPositionItem = toolbar?.items?[2] {
            let (line, column) = source.lineAndColumn(for: selection)
            cursorPositionItem.title = "\(line):\(column)"
            cursorPositionItem.isEnabled = errorLocation != nil
        }
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var textEditor: TextEditor

        init(_ textEditor: TextEditor) {
            self.textEditor = textEditor
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            textEditor.selection = textView.selectedRange
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            // Ensure there's no SwiftUI updates when we call this (you can get a warning otherwise)
            DispatchQueue.main.async {
                if textView.isFirstResponder {
                    self.textEditor.selection = textView.selectedRange
                }
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            textEditor.source = textView.text
        }
        
        @objc func format() {
            textEditor.onFormat?()
        }
    }
}

struct TextEditor_Previews: PreviewProvider {
    static var previews: some View {
        TextEditor(source: .constant("Hello world!"))
    }
}

fileprivate extension String {
    func lineAndColumn(for range: NSRange) -> (Int, Int) {
        var lineNumber = 1
        var columnNumber = 1
        
        for (i, char) in self.enumerated() {
            if i >= range.lowerBound {
                break
            } else if char == "\n" {
                lineNumber += 1
                columnNumber = 1
            } else {
                columnNumber += 1
            }
        }
        
        return (lineNumber, columnNumber)
    }
    
    func location(forLine line: Int, column: Int) -> Int {
        var lineNumber = line
        var columnNumber = column
        
        for (i, char) in self.enumerated() {
            if lineNumber != 1 {
                if char == "\n" {
                    lineNumber -= 1
                }
            } else if columnNumber != 1 {
                columnNumber -= 1
            } else {
                return i
            }
        }
        
        return count
    }
}
