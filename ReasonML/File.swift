//
//  File.swift
//  ReasonML
//
//  Created by Jacob Parker on 12/04/2020.
//  Copyright © 2020 Jacob Parker. All rights reserved.
//

import Foundation
import JavaScriptCore
import Combine

struct ConsoleEntry: Equatable, Hashable, Identifiable {
    enum Level: Int { case log = 0, warn = 1, error = 2 }
    
    let id = UUID()
    let level: Level
    let message: String
}

struct CompilationError: Equatable {
    static func == (lhs: CompilationError, rhs: CompilationError) -> Bool {
        lhs.message == rhs.message
    }
    
    fileprivate static let compilationErrorLocationRegex = try? NSRegularExpression(
        pattern: "Preview (\\d+):(\\d+)",
        options: []
    )
    
    let message: String
    let location: (Int, Int)?
    
    init(_ message: String) {
        self.message = message
        
        if let matches = CompilationError.compilationErrorLocationRegex?.matches(
                in: message,
                options: [],
                range: NSRange(location: 0, length: message.utf16.count)
            ),
            let match = matches.first,
            let lineRange = Range(match.range(at: 1), in: message),
            let columnRange = Range(match.range(at: 2), in: message),
            let lineNumber = Int(message[lineRange]),
            let columnNumber = Int(message[columnRange]) {
            self.location = (lineNumber, columnNumber)
        } else {
            self.location = nil
        }
    }
}

class File: ObservableObject {
    enum Language: Equatable, Hashable {
        case reason, ocaml
        
        var jsRepresentation: String {
            switch (self) {
            case .reason: return "re"
            case .ocaml: return "ml"
            }
        }
    }
    
    fileprivate var subscriptions = Set<AnyCancellable>()
    fileprivate var jsContext = JSContext()
    
    @Published var language = Language.reason
    @Published var source = "let x = 5;\nJs.log(x);\n"
    @Published var javascript = ""
    @Published var console = Array<ConsoleEntry>()
    @Published var compilationError: CompilationError? = nil
    
    init() {
        if let url = Bundle.main.url(forResource: "main", withExtension: "js"),
            let source = try? String(contentsOf: url) {
            jsContext?.evaluateScript(source)
        }
        
        Publishers.CombineLatest($source, $language)
            .debounce(for: 1, scheduler: RunLoop.main)
            .sink { (source, language) in
                guard let jsContext = self.jsContext,
                    let window = jsContext.globalObject,
                    let runtime = window.objectForKeyedSubscript("runtime"),
                    let out = runtime.invokeMethod(
                        "compile",
                        withArguments: [language.jsRepresentation, source]
                    ),
                    let errors = out.objectAtIndexedSubscript(0),
                    let javascript = out.objectAtIndexedSubscript(1) else {
                    self.javascript = ""
                    self.compilationError = nil
                    return
                }
                
                if errors.isNull && javascript.isString {
                    self.javascript = javascript.toString()
                    self.compilationError = nil
                } else if errors.isString {
                    self.javascript = ""
                    self.compilationError = CompilationError(errors.toString())
                }
            }
            .store(in: &subscriptions)
        
        $javascript
            .sink { javascript in
                guard !javascript.isEmpty,
                    let jsContext = self.jsContext,
                    let window = jsContext.globalObject,
                    let runtime = window.objectForKeyedSubscript("runtime"),
                    let out = runtime.invokeMethod(
                        "evalScript",
                        withArguments: [javascript]
                    ),
                    let console = out.toArray() else {
                    self.console = []
                    return
                }
                
                self.console = console.compactMap { entry -> ConsoleEntry? in
                    if let entry = entry as? NSDictionary,
                        let levelInt = entry["level"] as? Int,
                        let level = ConsoleEntry.Level(rawValue: levelInt),
                        let message = entry["message"] as? String {
                        return ConsoleEntry(level: level, message: message)
                    } else {
                        return nil
                    }
                }
            }
            .store(in: &subscriptions)
    }
    
    func format() {
        if let source = source(translatedTo: language) {
            self.source = source
        }
    }
    
    func convert(to language: Language) {
        self.source = source(translatedTo: language) ?? ""
        self.language = language
    }
    
    func source(translatedTo language: Language) -> String? {
        guard let jsContext = self.jsContext,
            let window = jsContext.globalObject,
            let runtime = window.objectForKeyedSubscript("runtime"),
            let out = runtime.invokeMethod(
                "translate",
                withArguments: [
                    self.language.jsRepresentation,
                    language.jsRepresentation,
                    source
                ]
            ),
            let errors = out.objectAtIndexedSubscript(0),
            let source = out.objectAtIndexedSubscript(1) else {
            return nil
        }
        
        if errors.isNull && source.isString {
            return source.toString()
        } else {
            return nil
        }
    }
}

extension File.Language: CustomStringConvertible {
    var description: String {
        switch self {
        case .reason: return "Reason"
        case .ocaml: return "OCaml"
        }
    }
}
