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
    enum Level { case log, warn, error }
    
    let id = UUID()
    let level: Level
    let message: String
}

@objc protocol ConsoleJSExports: JSExport {
    @objc func log(_ a: Any, _ b: Any, _ c: Any, _ d: Any, _ e: Any, _ f: Any)
    @objc func warn(_ a: Any, _ b: Any, _ c: Any, _ d: Any, _ e: Any, _ f: Any)
    @objc func error(_ a: Any, _ b: Any, _ c: Any, _ d: Any, _ e: Any, _ f: Any)
}

 @objc class Console: NSObject, ConsoleJSExports {
    var entries = Array<ConsoleEntry>()
    
    fileprivate func append(_ level: ConsoleEntry.Level, _ a: Any, _ b: Any, _ c: Any, _ d: Any, _ e: Any, _ f: Any) {
        let message = [a, b, c, d, e, f]
            .compactMap { arg -> String? in
                if let arg = arg as? CustomStringConvertible {
                    return "\(arg)"
                } else {
                    return nil
                }
            }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !message.isEmpty {
            entries.append(ConsoleEntry(level: level, message: message))
        }
    }
    
    @objc func log(_ a: Any, _ b: Any, _ c: Any, _ d: Any, _ e: Any, _ f: Any) {
        append(.log, a, b, c, d, e, f)
    }
    
    @objc func warn(_ a: Any, _ b: Any, _ c: Any, _ d: Any, _ e: Any, _ f: Any) {
        append(.warn, a, b, c, d, e, f)
    }
    
    @objc func error(_ a: Any, _ b: Any, _ c: Any, _ d: Any, _ e: Any, _ f: Any) {
        append(.error, a, b, c, d, e, f)
    }
}

class File: ObservableObject {
    enum Language: Equatable, Hashable {
        case reason, ocaml
    }
    
    fileprivate var subscriptions = Set<AnyCancellable>()
    fileprivate var jsContext = JSContext()
    
    @Published var language = Language.reason
    @Published var source = "let x = 5;\nJs.log(x);\n"
    @Published var javascript = ""
    @Published var console = Array<ConsoleEntry>()
    @Published var compilationError: String? = nil
    
    init() {
        ["refmt", "bsReasonReact", "main"].forEach { resource in
            if let url = Bundle.main.url(forResource: resource, withExtension: "js"),
                let source = try? String(contentsOf: url) {
                jsContext?.evaluateScript(source)
            }
        }
        
        if let jsContext = jsContext {
            jsContext.globalObject?.setValue(JSValue(nullIn: jsContext), forProperty: "console")
        }
        
        $source
            .debounce(for: 1, scheduler: RunLoop.main)
            .sink { source in
                guard let jsContext = self.jsContext,
                    let window = jsContext.globalObject else {
                    return
                }
                
                let console = Console()
                window.setValue(console, forProperty: "console")
                
                let code = window
                    .objectForKeyedSubscript(self.language == .reason ? "reason" : "ocaml")?
                    .invokeMethod("compile_super_errors_ppx_v2", withArguments: [source])?
                    .objectForKeyedSubscript("js_code")
                
                window.setValue(JSValue(nullIn: jsContext), forProperty: "console")
                
                if let code = code, code.isString {
                    self.compilationError = nil
                    self.javascript = code.toString()
                } else {
                    let regex = try! NSRegularExpression(
                        pattern: "\\e\\[[^m]*m",
                        options: .init()
                    )
                    
                    self.compilationError = console.entries
                        .map(\.message)
                        .filter { !$0.contains("WARN: File \"js_cmj_load.ml\"") }
                        .map { $0.replacingOccurrences(of: "(No file name)", with: "") }
                        .map {
                            regex.stringByReplacingMatches(
                                in: $0,
                                options: [],
                                range: NSMakeRange(0, $0.count),
                                withTemplate: ""
                            )
                        }
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .joined(separator: "\n")
                    self.javascript = ""
                }
            }
            .store(in: &subscriptions)
        
        $javascript
            .sink { source in
                guard !source.isEmpty else {
                    self.console = []
                    return
                }
                
                guard let jsContext = self.jsContext,
                    let window = jsContext.globalObject else {
                    return
                }
                
                let console = Console()
                window.setValue(console, forProperty: "console")
                
                window.invokeMethod("evalScript", withArguments: [source])
                
                window.setValue(JSValue(nullIn: jsContext), forProperty: "console")
                
                self.console = console.entries
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
        guard let window = jsContext?.globalObject else {
            return nil
        }
        
        let parseSource = self.language == .reason ? "parseRE" : "parseML"
        let printAst = language == .reason ? "printRE" : "printML"

        if let ast = window.invokeMethod(parseSource, withArguments: [source]),
            let source = window.invokeMethod(printAst, withArguments: [ast]),
            source.isString {
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
