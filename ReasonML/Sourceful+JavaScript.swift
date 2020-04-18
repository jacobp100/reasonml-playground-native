import Foundation
@testable import Sourceful

class JavaScriptLexer: SourceCodeRegexLexer {
    public init() {}
    
    lazy var generators: [TokenGenerator] = {
        var generators = [TokenGenerator?]()
        
        let keywords = "in of if for while finally var new function do return void else break catch instanceof with throw case default try this switch continue typeof delete let yield const export super debugger as async await static import from as true false null undefined NaN Infinity".components(separatedBy: " ")
        generators.append(keywordGenerator(keywords, tokenType: .keyword))
        
        // Numbers
        // https://github.com/highlightjs/highlight.js/blob/master/src/languages/reasonml.js#L43
        generators.append(regexGenerator("\\b(0[bB][01]+)n?|\\b(0[oO][0-7]+)n?|(-?)(\\b0[xX][a-fA-F0-9]+|(\\b\\d+(\\.\\d*)?|\\.\\d+)([eE][-+]?\\d+)?)", tokenType: .number))
        
        // Booleans
        let booleans = "true false".components(separatedBy: " ")
        generators.append(keywordGenerator(booleans, tokenType: .keyword))
        
        // Line comment
        generators.append(regexGenerator("//(.*)", tokenType: .comment))
        
        // Block comment
        generators.append(regexGenerator("(/\\*)(.*)(\\*/)", options: [.dotMatchesLineSeparators], tokenType: .comment))
        
        // Single-line string literal
        generators.append(regexGenerator("\"(\\\\\"|[^\"\\n])*\"", tokenType: .string))
        generators.append(regexGenerator("'(\\\\'|[^'\\n])*'", tokenType: .string))
        
        return generators.compactMap { $0 }
    }()
    
    public func generators(source: String) -> [TokenGenerator] {
        return generators
    }
}
