//
//  SongToast.swift
//  DeltaToast
//
//  Created by Lewis McClelland on 8/15/25.
//

import SwiftUI

extension String {
    static var toastsShowArtistKey : String { "ToastsShowArtistName" }
}

struct SongToast: View {
    enum State {
        case playing
        case paused
    }
    
    var name: String
    var artist: String?
    var state: State
    
    init(_ name: String, artist: String? = nil, state: State) {
        self.name = name
        self.artist = artist
        self.state = state
    }

    var body: some View {
        let icon = switch state {
        case .playing: "♪"
        case .paused: "⏸"
        }
        
        let displayName = if let artist {
            "\(artist) - \(name)"
        } else {
            name
        }
        
        BMFontText("\(icon)~\u{2009}\u{2009}\u{2009}\(displayName)")
    }
}

#Preview {
    VStack {
        SongToast("Black Knife", state: .playing)
        SongToast("Black Knife", state: .paused)
        SongToast("Black Knife", artist: "Toby Fox", state: .playing)
        SongToast("Black Knife", artist: "Toby Fox", state: .paused)
    }
    .padding()
    .environment(try! Bundle.main.font(name: "MusicTitleFont"))
}
