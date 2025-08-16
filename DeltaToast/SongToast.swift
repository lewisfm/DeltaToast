//
//  SongToast.swift
//  DeltaToast
//
//  Created by Lewis McClelland on 8/15/25.
//

import SwiftUI

struct SongToast: View {
    var name: String
    var artist: String?
    var state: Track.State
    
    @Environment(DTSettings.self) private var settings
    
    init(_ track: Track, defaultName: String) {
        name = track.name ?? defaultName
        artist = track.artist
        state = track.state
    }
    
    init(_ name: String, artist: String? = nil, state: Track.State) {
        self.name = name
        self.artist = artist
        self.state = state
    }

    var body: some View {
        let icon = switch state {
        case .playing: "♪"
        case .paused: "⏸"
        }
        
        let displayName = if let artist, settings.toastsShowArtistName {
            "\(artist) - \(name)"
        } else {
            name
        }
        
        HStack(spacing: 0) {
            // Icon should transition separately from the rest of the string
            BMFontText(icon)
            BMFontText("~\u{2009}\u{2009}\u{2009}")
            BMFontText(displayName)
        }
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
    .environment(DTSettings.shared)
}
