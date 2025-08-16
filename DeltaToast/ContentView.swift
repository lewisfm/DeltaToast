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

    var body: some View {
        VStack {
            if let track = toastController.track, allowToast {
                SongToast(track, defaultName: "<unknown>")
                    .compositingGroup()
                    .shadow(color: .black.opacity(0.75), radius: 5)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.smooth, value: toastController.track)
        .onChange(of: toastController.track, initial: true) {
            hideTask?.cancel()
            withAnimation {
                allowToast = true
            }
            
            hideTask = Task {
                do {
                    try await Task.sleep(for: .seconds(3))
                    
                    withAnimation {
                        allowToast = false
                    }
                } catch {}
            }
        }
        .padding(15)
        .padding(.horizontal, 50)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .environment(try! Bundle.main.font(name: "MusicTitleFont"))
        .environment(DTSettings.shared)
    }
}

#Preview {
    ContentView()
}
