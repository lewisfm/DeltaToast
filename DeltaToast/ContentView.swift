//
//  ContentView.swift
//  DeltaToast
//
//  Created by Lewis McClelland on 8/12/25.
//

import SwiftUI

struct ContentView: View {
    @State private var toastController = ToastController()
    @State private var allowToast = false
    @State private var hideTask: Task<Void, Never>?
    @State private var settings = DTSettings.shared

    var body: some View {
        VStack {
            if let track = toastController.track, allowToast {
                SongToast(track, defaultName: "<unknown>")
                    .compositingGroup()
                    .shadow(color: .black.opacity(0.75), radius: 5)
                    .transition(.move(edge: settings.toastPosition.slideInEdge).combined(with: .opacity))
                    .environment(\.bitmapFontScale, settings.scaleFactor)
            }
        }
        .animation(.smooth, value: toastController.track)
        .animation(.smooth, value: settings.scaleFactor)
        .animation(.smooth, value: settings.toastPosition)
        .onChange(of: toastController.track, initial: true, show)
        .onChange(of: settings.toastsShowArtistName, show)
        .onChange(of: settings.scaleFactor, show)
        .onChange(of: settings.toastAutoHideDelay, show)
        .onChange(of: settings.toastPosition, show)
        .padding(15)
        .padding(.horizontal, 50)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: settings.toastPosition.alignment)
        .environment(try! Bundle.main.font(name: "MusicTitleFont"))
        .environment(settings)
    }
    
    func show() {
        hideTask?.cancel()
        withAnimation {
            allowToast = true
        }
        
        hideTask = Task {
            do {
                try await Task.sleep(for: .seconds(settings.toastAutoHideDelay))
                
                withAnimation {
                    allowToast = false
                }
            } catch {}
        }
    }
}

#Preview {
    ContentView()
}
