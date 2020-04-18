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
                guard !source.contains("//") else {
                    // Crashes the JS engine
                    self.javascript = ""
                    self.compilationError = CompilationError("Line comments are not yet supported.\n\nUse /* block comments */ instead.")
                    return
                }
                
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
                    guard let entry = entry as? NSDictionary,
                        let levelInt = entry["level"] as? Int,
                        let level = ConsoleEntry.Level(rawValue: levelInt),
                        let partsArray = entry["parts"] as? [Any] else {
                        return nil
                    }
                    
                    let parts = partsArray.compactMap { part -> ConsoleEntry.Part? in
                        guard let part = part as? NSDictionary,
                            let labelDict = part["label"] as? NSDictionary,
                            let label = self.consoleValue(from: labelDict) else {
                            return nil
                        }
                        
                        let alternate = (part["alternate"] as? NSArray)?
                            .compactMap { self.consoleValue(from: $0) }
                        
                        return ConsoleEntry.Part(label: label, alternate: alternate)
                    }
                    
                    return ConsoleEntry(level: level, parts: parts)
                }
            }
            .store(in: &subscriptions)
    }
    
    fileprivate func consoleValue(from arg: Any) -> ConsoleEntry.Value? {
        guard let argDict = arg as? NSDictionary,
            let formatInt = argDict["format"] as? Int,
            let format = ConsoleEntry.Format(rawValue: formatInt),
            let description = argDict["description"] as? String else {
            return nil
        }
        
        return ConsoleEntry.Value(description: description, format: format)
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
