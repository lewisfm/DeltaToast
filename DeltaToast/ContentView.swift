//
//  ContentView.swift
//  DeltaToast
//
//  Created by Lewis McClelland on 8/12/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            SongToast("Black Knife", artist: "Toby Fox", state: .playing)
                .compositingGroup()
                .shadow(color: .black.opacity(0.75), radius: 5)
        }
        .padding(15)
        .padding(.horizontal, 50)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .border(.red)
        .environment(try! Bundle.main.font(name: "MusicTitleFont"))
    }
}

#Preview {
    ContentView()
}
