//
//  TextEditor.swift
//  ReasonML
//
//  Created by Jacob Parker on 12/04/2020.
//  Copyright © 2020 Jacob Parker. All rights reserved.
//

import SwiftUI

class KeyboardAvoidingTextView: UITextView {
    var bottomInset: CGFloat = 0 { didSet { setNeedsLayout() } }
    override var bounds: CGRect { didSet { setNeedsLayout() } }
    
    override func didMoveToWindow() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardDidShow(aNotification: NSNotification) {
        let info = aNotification.userInfo
        let infoNSValue = info![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue
        let keyboardFrame = infoNSValue.cgRectValue.size
        bottomInset = keyboardFrame.height
    }

    @objc func keyboardWillHide(aNotification:NSNotification) {
        bottomInset = 0
    }
    
    override func layoutSubviews() {
        let screenHeight = UIScreen.main.bounds.height
        let frameInWindow = convert(bounds, to: nil)
        let bottomDistance = max(screenHeight - frameInWindow.maxY, 0)
        contentInset = .init(
            top: 0,
            left: 0,
            bottom: max(0, bottomInset - bottomDistance),
            right: 0
        )
        scrollIndicatorInsets = contentInset
    }
}

struct TextEditor: UIViewRepresentable {
    @Binding var source: String
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
        
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        
        let toolbar = UIToolbar()
        toolbar.items = [
            UIBarButtonItem(customView: label),
            UIBarButtonItem(
                title: "Format",
                style: .plain,
                target: context.coordinator,
                action: #selector(Coordinator.format)
            ),
            UIBarButtonItem(
                barButtonSystemItem: .flexibleSpace,
                target: nil,
                action: nil
            ),
            UIBarButtonItem(
                title: "Done",
                style: .done,
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
        uiView.text = source
        uiView.isEditable = isEditable
        
        let toolbar = uiView.inputAccessoryView as? UIToolbar
        toolbar?.isHidden = !isEditable
        toolbar?.tintColor = uiView.tintColor
        
        if let selection = selection,
            let label = toolbar?.items?.first?.customView as? UILabel {
            let (line, column) = source.lineAndColumn(for: selection)
            label.text = "\(line):\(column)"
            label.sizeToFit()
            toolbar?.setNeedsLayout()
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
            if textView.isFirstResponder {
                textEditor.selection = textView.selectedRange
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
        var columnNumber = 0
        
        for (i, char) in self.enumerated() {
            if i >= range.lowerBound {
                break
            } else if char == "\n" {
                lineNumber += 1
                columnNumber = 0
            } else {
                columnNumber += 1
            }
        }
        
        return (lineNumber, columnNumber)
    }
}
