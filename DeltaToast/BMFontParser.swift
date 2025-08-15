//
//  BMFont.swift
//  DeltaToast
//
//  Created by Lewis McClelland on 8/13/25.
//

import Foundation

public enum BMFontParseError: Error {
    case unexpectedEOF
    case badEOL
    case wrongType
    case expected(Character)
    case eolNotValidInString
    case conversionFailed
}

enum AdvanceDistance {
    case oneCharacter
    case whitespace
    case eol
}

fileprivate extension Character {
    var isWhitespace: Bool {
        [" ", "\t"].contains(self)
    }
    
    var isEol: Bool {
        ["\r", "\n"].contains(self)
    }
}

public struct BMFontReader {
    var data: String
    var index: String.Index?
    var line: Int = 0
    
    public init(data: String) {
        self.data = data
        index = if data.isEmpty { nil } else { data.startIndex }
    }
    
    var character: Character? {
        guard let index else { return nil }
        return data[index]
    }
    
    mutating func advance(past distance: AdvanceDistance = .oneCharacter) throws {
        guard let index else { return }

        switch distance {
        case .oneCharacter:
            let newIndex = data.index(after: index)
            self.index = if newIndex >= data.endIndex {
                 nil
            } else {
                newIndex
            }
 
        case .whitespace:
            while character?.isWhitespace == true {
                try advance()
            }

        case .eol:
            guard character?.isEol == true else { return }
            
            if character == "\r" {
                try advance()
            }
            
            guard character == "\n" else {
                throw BMFontParseError.badEOL
            }
            
            self.line += 1
            try advance()
        }
    }
    
    mutating func expect(char: Character) throws {
        guard character == char else {
            throw BMFontParseError.expected(char)
        }
        try advance()
    }
    
    mutating func nextWord(stopOnEq: Bool = false) throws -> String? {
        try advance(past: .whitespace)
        guard let startIndex = self.index else {
            return nil
        }
        var endIndex = startIndex
    
        while let index {
            let char = data[index]
            
            if char.isWhitespace || char.isEol || char == "\0" {
                break
            }
            
            if stopOnEq && char == "=" {
                break
            }
            
            endIndex = index
            try advance()
        }
        
        return String(data[startIndex...endIndex])
    }
    
    mutating func nextString() throws -> String? {
        try expect(char: "\"")
        
        guard let startIndex = self.index else {
            return nil
        }
    
        while let index {
            let char = data[index]
            
            if char.isEol {
                throw BMFontParseError.eolNotValidInString
            }
            
            if char == "\"" {
                break
            }

            try advance()
        }
        
        let slice = data[startIndex..<index!]
        
        try expect(char: "\"")
        
        return String(slice)
    }
    
    mutating func nextLine() throws -> BMFontEntry? {
        try advance(past: .whitespace)
        while character?.isEol == true {
            try advance(past: .eol)
            try advance(past: .whitespace)
        }
        
        if self.index == nil {
            return nil
        }
        
        let tag = try nextWord()!
        var attrs = [String: String]()
        
        try advance(past: .whitespace)
        
        while let start = character, !start.isEol {
            let name = try nextWord(stopOnEq: true)!
        
            try expect(char: "=")
            
            let value = if character == "\"" {
                try nextString()
            } else {
                try nextWord()
            }
            guard let value else {
                throw BMFontParseError.unexpectedEOF
            }
            
            attrs[name] = value
        }
        
        return BMFontEntry(tag: tag, attributes: attrs)
    }
}

public struct BMFontEntry {
    public var tag: String
    public var attributes: [String: String]
    
    func forEach(execute body: (_ name: String, _ value: BMFontAttribute) throws -> Void) rethrows {
        for (name, value) in attributes {
            try body(name, BMFontAttribute(value: value))
        }
    }
}

public struct BMFontAttribute {
    var value: String
    
    func string() -> String {
        value
    }
    
    func parsed<T>(_ factory: (String) -> T?) throws -> T {
        guard let num = factory(string()) else {
            throw BMFontParseError.conversionFailed
        }
        return num
    }
    
    func bool() throws -> Bool {
        return try parsed(Int.init) != 0
    }
    
    func array<T>(_ factory: (String) -> T?) throws -> [T] {
        return try string().split(separator: ",").map { item in
            guard let parsed = factory(String(item)) else {
                throw BMFontParseError.conversionFailed
            }
            
            return parsed
        }
    }
}

public struct BMFontMetadata {
    public var info = BMFontInfo()
    public var common = BMFontCommon()
    public var pages = [BMFontPage]()
    public var chars = [BMFontChar]()
    public var kernings = [BMFontKerning]()
    
    public init(data: String) throws {
        var reader = BMFontReader(data: data)
        while let entry = try reader.nextLine() {
            switch entry.tag {
            case "info": info = try BMFontInfo(entry: entry)
            case "common": common = try BMFontCommon(entry: entry)
            case "page": pages.append(try BMFontPage(entry: entry))
                
            case "chars":
                if let countString = entry.attributes["count"],
                   let count = Int(countString)
                {
                    chars.reserveCapacity(count)
                }
            case "char": chars.append(try BMFontChar(entry: entry))
                
            case "kernings":
                if let countString = entry.attributes["count"],
                   let count = Int(countString)
                {
                    kernings.reserveCapacity(count)
                }
            case "kerning": kernings.append(try BMFontKerning(entry: entry))
                
            default: break
            }
        }
    }
}

public struct BMFontInfo {
    public var face: String = ""
    public var size: Int16 = 0
    public var bold: Bool = false
    public var italic: Bool = false
    public var charset: String = ""
    public var stretchH: UInt16 = 0
    public var smooth: Bool = false
    public var aa: UInt8 = 0
    public var padding: [UInt8] = [0, 0, 0, 0]
    public var spacing: [UInt8] = [0, 0]
    public var outline: UInt8 = 0
    
    init() {}
    
    init(entry: BMFontEntry) throws {
        try entry.forEach { name, attr in
            switch name {
            case "face": face = attr.string()
            case "size": size = try attr.parsed(Int16.init)
            case "bold": bold = try attr.bool()
            case "italic": italic = try attr.bool()
            case "charset": charset = attr.string()
            case "stretchH": stretchH = try attr.parsed(UInt16.init)
            case "smooth": smooth = try attr.bool()
            case "aa": aa = try attr.parsed(UInt8.init)
            case "padding": padding = try attr.array(UInt8.init)
            case "spacing": spacing = try attr.array(UInt8.init)
            case "outline": outline = try attr.parsed(UInt8.init)
            default:
                break
            }
        }
    }
}

public struct BMFontCommon {
    public var lineHeight: UInt16 = 0
    public var base: UInt16 = 0
    public var scaleW: UInt16 = 0
    public var scaleH: UInt16 = 0
    public var pages: UInt8 = 0
    public var packed: Bool = false
    
    public var alphaChnl: BMFontPacking = .glyph
    public var redChnl: BMFontPacking = .glyph
    public var greenChnl: BMFontPacking = .glyph
    public var blueChnl: BMFontPacking = .glyph
    
    init() {}
    
    init(entry: BMFontEntry) throws {
        try entry.forEach { name, attr in
            switch name {
            case "lineHeight": lineHeight = try attr.parsed(UInt16.init)
            case "base": base = try attr.parsed(UInt16.init)
            case "scaleW": scaleW = try attr.parsed(UInt16.init)
            case "scaleH": scaleH = try attr.parsed(UInt16.init)
            case "pages": pages = try attr.parsed(UInt8.init)
            case "packed": packed = try attr.bool()
            case "alphaChnl": alphaChnl = try attr.parsed(BMFontPacking.init)
            case "redChnl": redChnl = try attr.parsed(BMFontPacking.init)
            case "greenChnl": greenChnl = try attr.parsed(BMFontPacking.init)
            case "blueChnl": blueChnl = try attr.parsed(BMFontPacking.init)
            default: break
            }
        }
    }
}

/// Channel packing description.
///
/// Used when character packing is specified to describe what is stored in each texture
/// channel.
public enum BMFontPacking: UInt8 {
    /// Channel holds glyph data.
    case glyph = 0
    /// Channel holds outline data.
    case outline = 1
    /// Channel holds glyph and outline data.
    case glyphOutline = 2
    /// Channel is set to zero.
    case zero = 3
    /// Channel is set to one.
    case one = 4
    
    init?(_ string: String) {
        guard let number = UInt8(string) else {
            return nil
        }
        
        self.init(rawValue: number)
    }
}

public struct BMFontPage {
    public var id: UInt16 = 0
    public var file: String = ""
    
    init() {}
    
    init(entry: BMFontEntry) throws {
        try entry.forEach { name, attr in
            switch name {
            case "id": id = try attr.parsed(UInt16.init)
            case "file": file = attr.string()
            default: break
            }
        }
    }
}


public struct BMFontChar {
    /// The character id.
    public var id: UInt32 = 0
    /// The left position of the character image in the texture.
    public var x: UInt16 = 0
    /// The top position of the character image in the texture.
    public var y: UInt16 = 0
    /// The width of the character image in the texture.
    public var width: UInt16 = 0
    /// The height of the character image in the texture.
    public var height: UInt16 = 0
    /// How much the current position should be offset when copying the image from the texture to
    /// the screen.
    public var xoffset: Int16 = 0
    /// How much the current position should be offset when copying the image from the texture to
    /// the screen.
    public var yoffset: Int16 = 0
    /// How much the current position should be advanced after drawing the character.
    public var xadvance: Int16 = 0
    /// The texture page where the character image is found.
    public var page: UInt8 = 0
    /// The texture channel where the character image is found.
    public var chnl: Channel = .All
    
    init() {}
    
    init(entry: BMFontEntry) throws {
        try entry.forEach { name, attr in
            switch name {
            case "id": id = try attr.parsed(UInt32.init)
            case "x": x = try attr.parsed(UInt16.init)
            case "y": y = try attr.parsed(UInt16.init)
            case "width": width = try attr.parsed(UInt16.init)
            case "height": height = try attr.parsed(UInt16.init)
            case "xoffset": xoffset = try attr.parsed(Int16.init)
            case "yoffset": yoffset = try attr.parsed(Int16.init)
            case "xadvance": xadvance = try attr.parsed(Int16.init)
            case "page": page = try attr.parsed(UInt8.init)
            case "chnl": chnl = Channel(rawValue: try attr.parsed(UInt8.init))
            default: break
            }
        }
    }
}

public struct Channel: OptionSet, Sendable {
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    public let rawValue: UInt8
    
    static let Blue = Channel(rawValue: 1 << 0)
    static let Green = Channel(rawValue: 1 << 1)
    static let Red = Channel(rawValue: 1 << 2)
    static let Alpha = Channel(rawValue: 1 << 3)
    static let All = Channel(rawValue: 15)
}

public struct BMFontKerning {
    /// The first character id.
    public var first: UInt32 = 0
    /// The second character id.
    public var second: UInt32 = 0
    /// How much the x position should be adjusted when drawing the second character immediately
    /// following the first.
    public var amount: Int16 = 0
    
    init() {}
    
    init(entry: BMFontEntry) throws {
        try entry.forEach { name, attr in
            switch name {
            case "first": first = try attr.parsed(UInt32.init)
            case "second": second = try attr.parsed(UInt32.init)
            case "amount": amount = try attr.parsed(Int16.init)
            default: break
            }
        }
    }
}
