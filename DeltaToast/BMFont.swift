//
//  BMFont.swift
//  DeltaToast
//
//  Created by Lewis McClelland on 8/14/25.
//

import Observation
import SwiftUI

@Observable
public class BMFont {
    var meta: BMFontMetadata
    var texture: Image
    var characters: [Character: BMFontChar]

    init(meta: BMFontMetadata, texture: Image) {
        self.meta = meta
        self.texture = texture

        characters = Dictionary(
            uniqueKeysWithValues: meta.chars.compactMap { char in
                guard let scalar = Unicode.Scalar(char.id) else {
                    return nil
                }
                let character = Character(scalar)
                return (character, char)
            })
    }
    
    func get(char: Character) -> BMFontChar {
        characters[char]
            ?? characters["\u{25AF}"]
            ?? characters["?"]!
    }
}

extension Bundle {
    func font(name: String) throws -> BMFont {
        let metaUrl = url(forResource: name, withExtension: "fnt")!
        let metaData = String(
            data: try Data(contentsOf: metaUrl), encoding: .utf8)!
        let meta = try BMFontMetadata(data: metaData)
        let texture = Image(meta.pages[0].file)

        return BMFont(meta: meta, texture: texture)
    }
}

extension EnvironmentValues {
    /// A multiplier that will be applied to the size of the font.
    @Entry var bitmapFontScale: Double = 2.0
}

private struct BMFontCharView: View {
    var char: Character
    
    @Environment(BMFont.self) var font
    @Environment(\.bitmapFontScale) var scaleFactor

    var charData: BMFontChar {
        font.get(char: char)
    }

    var body: some View {
        let x = Double(charData.x)
        let y = Double(charData.y)
        
        let height = Double(charData.height)
        let width = Double(charData.width)

        font.texture
            .interpolation(.none)
            .offset(x: -x, y: -y)
            .scaleEffect(scaleFactor, anchor: .topLeading)
            .frame(width: width * scaleFactor,
                   height: height * scaleFactor,
                   alignment: .topLeading)
            .clipped()
    }
}

public struct BMFontText: View {
    var text: String
    
    @Environment(BMFont.self) var font
    @Environment(\.bitmapFontScale) var scaleFactor
    @Environment(\.multilineTextAlignment) var textAlignment
    
    init(_ text: String) {
        self.text = text
    }
    
    struct RenderableCharacter: Equatable, Hashable {
        var index: Int
        var previous: Character?
        var character: Character
    }
    
    private var lines: [[RenderableCharacter]] {
        text.split(separator: "\n").map { line in
            let characters = Array(line)
            
            return characters.enumerated().map { offset, char in
                var renderable = RenderableCharacter(index: offset, character: char)
                if offset > 0 {
                    renderable.previous = characters[offset - 1]
                }
                return renderable
            }
        }
    }
    
    private var alignment: HorizontalAlignment {
        switch textAlignment {
        case .leading:
            return .leading
        case .trailing:
            return .trailing
        case .center:
            return .center
        }
    }

    public var body: some View {
        let lineHeight = Double(font.meta.common.lineHeight) * scaleFactor
        
        VStack(alignment: alignment, spacing: 0) {
            ForEach(lines, id: \.self) { line in
                HStack(spacing: 0) {
                    ForEach(line, id: \.self) { item in
                        let fontChar = font.get(char: item.character)
                        
                        let xadvance = Double(fontChar.xadvance) * scaleFactor
                        
                        BMFontCharView(char: item.character)
                            .frame(width: xadvance, alignment: .topLeading)
                    }
                }
                .frame(height: lineHeight, alignment: .topLeading)
            }
        }
    }
}

#Preview {
    VStack {
        HStack {
            let chars: [Character] = ["B", "!", "@"]
            
            ForEach(chars, id: \.self) { char in
                BMFontCharView(char: char)
                    .border(.red)
            }
        }
        
        BMFontText("♪~\u{2009}\u{2009}\u{2009}The quick brown fox jumps\nover the lazy dog!")
        
        BMFontText("This text will wrap onto\nmultiple lines!")
            .multilineTextAlignment(.center)
    }
    .frame(width: 500, height: 500)
    .environment(try! Bundle.main.font(name: "MusicTitleFont"))
}
