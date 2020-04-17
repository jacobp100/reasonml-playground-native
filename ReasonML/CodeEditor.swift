//
//  CodeEditor.swift
//  ReasonML
//
//  Created by Jacob Parker on 16/04/2020.
//  Copyright © 2020 Jacob Parker. All rights reserved.
//

import SwiftUI
import Sourceful

class CustomSyntaxTextView: SyntaxTextView {
    var errorLocation: (Int, Int)?
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
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
        let bottom = max(keyboardFrame.height - safeAreaInsets.bottom, 0)
        contentInset = .init(top: 0, left: 0, bottom: bottom, right: 0)
    }

    @objc func keyboardWillHide(aNotification:NSNotification) {
        contentInset = .zero
    }

    @objc func selectError() {
        if let (lineNumber, columnNumber) = errorLocation {
            let location = text.location(forLine: lineNumber, column: columnNumber)
            contentTextView.selectedRange = NSRange(location: location, length: 0)
        }
    }
}

struct CodeEditor: UIViewRepresentable {
    enum Language {
        case reason, ocaml, javascript
        
        init(language: File.Language) {
            switch language {
            case .reason: self = .reason
            case .ocaml: self = .ocaml
            }
        }
    }
    
    enum Action { case format }
    
    var language: Language
    @Binding var source: String
    @State var selection: NSRange? = nil
    var errorLocation: (Int, Int)? = nil
    var isEditable = true
    var onAction: ((Action) -> Void)? = nil
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> CustomSyntaxTextView {
        let uiView = CustomSyntaxTextView()
        uiView.theme = CustomTheme()
        uiView.delegate = context.coordinator
        uiView.contentTextView.keyboardAppearance = .default
        uiView.contentTextView.alwaysBounceVertical = true
        
        let cursorPositionItem = UIBarButtonItem(
            title: "",
            style: .plain,
            target: uiView,
            action: #selector(CustomSyntaxTextView.selectError)
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
                target: uiView.contentTextView,
                action: #selector(UIResponder.resignFirstResponder)
            )
        ]
        toolbar.sizeToFit()
        uiView.contentTextView.inputAccessoryView = toolbar
        
        return uiView
    }
    
    func updateUIView(_ uiView: CustomSyntaxTextView, context: Context) {
        if uiView.text != source {
            uiView.text = source
        }
        
        uiView.errorLocation = errorLocation
        uiView.contentTextView.isEditable = isEditable
        
        let toolbar = uiView.contentTextView.inputAccessoryView as? UIToolbar
        toolbar?.isHidden = !isEditable
        toolbar?.tintColor = uiView.tintColor
        
        if let selection = selection,
            let cursorPositionItem = toolbar?.items?[2] {
            let (line, column) = source.lineAndColumn(for: selection)
            cursorPositionItem.title = "\(line):\(column)"
            cursorPositionItem.isEnabled = errorLocation != nil
        }
    }
    
    class Coordinator: NSObject, SyntaxTextViewDelegate {
        fileprivate lazy var reasonLexer = ReasonLexer()
        fileprivate lazy var ocamlLexer = OCamlLexer()
        fileprivate lazy var javascriptLexer = JavaScriptLexer()
        
        var codeEditor: CodeEditor

        init(_ codeEditor: CodeEditor) {
            self.codeEditor = codeEditor
        }
        
        func lexerForSource(_ source: String) -> Lexer {
            switch codeEditor.language {
            case .reason: return reasonLexer
            case .ocaml: return ocamlLexer
            case .javascript: return javascriptLexer
            }
        }
        
        func textViewDidBeginEditing(_ syntaxTextView: SyntaxTextView) {
            self.codeEditor.selection = syntaxTextView.contentTextView.selectedRange
        }
        
        func didChangeSelectedRange(_ syntaxTextView: SyntaxTextView, selectedRange: NSRange) {
            self.codeEditor.selection = selectedRange
        }
        
        func didChangeText(_ syntaxTextView: SyntaxTextView) {
            codeEditor.source = syntaxTextView.text
        }
        
        @objc func format() {
            codeEditor.onAction?(.format)
        }
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
