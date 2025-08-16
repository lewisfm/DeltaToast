//
//  DTSettings.swift
//  DeltaToast
//
//  Created by Lewis McClelland on 8/15/25.
//

import SwiftUI

extension String {
    static var toastsShowArtistKey : String { "ToastsShowArtistName" }
}

@Observable
class DTSettings {
    @MainActor
    static let shared = DTSettings()
    
    init() {
        UserDefaults.standard.register(defaults: [
            .toastsShowArtistKey: true,
        ])
        
        toastsShowArtistName = UserDefaults.standard.bool(forKey: .toastsShowArtistKey)
    }

    var toastsShowArtistName: Bool {
        didSet {
            UserDefaults.standard.set(toastsShowArtistName, forKey: .toastsShowArtistKey)
        }
    }
}

struct DTSettingsView: View {
    var settings = DTSettings.shared

    var body: some View {
        @Bindable var settings = settings

        Form {
            Text("DeltaToast Settings")
                .font(.headline)
            
            Toggle("Show Artist Name", isOn: $settings.toastsShowArtistName)
            
            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
        .padding()
        .onAppear {
            NSApp.setActivationPolicy(.regular)
        }
        .onDisappear {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

#Preview {
    DTSettingsView()
}
