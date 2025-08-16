//
//  DTSettings.swift
//  DeltaToast
//
//  Created by Lewis McClelland on 8/15/25.
//

import SwiftUI

extension String {
    static var toastsShowArtistKey : String { "ToastsShowArtistName" }
    static var allowToastWindowSharingKey : String { "AllowToastWindowSharing" }
    static var toastScaleFactorKey : String { "ToastScaleFactor" }
    static var toastAutoHideDelaySecondsKey : String { "ToastAutoHideDelaySeconds" }
    static var toastPositionKey : String { "ToastPosition" }
}

@Observable
class DTSettings {
    @MainActor
    static let shared = DTSettings()
    
    init() {
        UserDefaults.standard.register(defaults: [
            .toastsShowArtistKey: true,
            .allowToastWindowSharingKey: true,
            .toastScaleFactorKey: 2.0,
            .toastAutoHideDelaySecondsKey: 3.0,
            .toastPositionKey: Position.default.rawValue,
        ])
        
        toastsShowArtistName = UserDefaults.standard.bool(forKey: .toastsShowArtistKey)
        allowToastWindowSharing = UserDefaults.standard.bool(forKey: .allowToastWindowSharingKey)
        scaleFactor = UserDefaults.standard.double(forKey: .toastScaleFactorKey)
        toastAutoHideDelay = UserDefaults.standard.double(forKey: .toastAutoHideDelaySecondsKey)
        toastPosition = UserDefaults.standard.string(forKey: .toastPositionKey).flatMap(Position.init) ?? .default
    }

    /// Do toasts include the artist's name, or just the song name?
    var toastsShowArtistName: Bool {
        didSet {
            UserDefaults.standard.set(toastsShowArtistName, forKey: .toastsShowArtistKey)
        }
    }
    
    /// Do toasts appear in screen captures?
    var allowToastWindowSharing: Bool {
        didSet {
            UserDefaults.standard.set(allowToastWindowSharing, forKey: .allowToastWindowSharingKey)
        }
    }
    
    var windowSharingType: NSWindow.SharingType {
        if allowToastWindowSharing {
            .readOnly
        } else {
            .none
        }
    }
    
    /// How big is the toast's font size?
    var scaleFactor: Double {
        didSet {
            UserDefaults.standard.set(scaleFactor, forKey: .toastScaleFactorKey)
        }
    }
    
    /// How long does the toast stay on the screen?
    var toastAutoHideDelay: TimeInterval {
        didSet {
            UserDefaults.standard.set(toastAutoHideDelay, forKey: .toastAutoHideDelaySecondsKey)
        }
    }
    
    /// Where does the toast appear on screen?
    var toastPosition: Position {
        didSet {
            UserDefaults.standard.set(toastPosition.rawValue, forKey: .toastPositionKey)
        }
    }
    
    enum Position: String, Codable {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
        
        static let `default`: Position = .topRight
        
        var slideInEdge: Edge {
            if self == .topLeft || self == .topRight {
                .top
            } else {
                .bottom
            }
        }
        
        var alignment: Alignment {
            switch self {
            case .topLeft: .topLeading
            case .topRight: .topTrailing
            case .bottomLeft: .bottomLeading
            case .bottomRight: .bottomTrailing
            }
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
            Toggle("Visible in Screen Captures", isOn: $settings.allowToastWindowSharing)
            
            let scaleRange = 1.0...3.0
            Slider(value: $settings.scaleFactor, in: scaleRange, step: 0.5) {
                Text("Banner Size")
            } minimumValueLabel: {
                Text("\(scaleRange.lowerBound, format: .percent)")
            } maximumValueLabel: {
                Text("\(scaleRange.upperBound, format: .percent)")
            }
            .frame(width: 300)
            
            Picker("Banner Position", selection: $settings.toastPosition) {
                Text("Top Left").tag(DTSettings.Position.topLeft)
                Text("Top Right").tag(DTSettings.Position.topRight)
                Text("Bottom Left").tag(DTSettings.Position.bottomLeft)
                Text("Bottom Right").tag(DTSettings.Position.bottomRight)
            }
            .pickerStyle(.radioGroup)
            
            
            let autoHideRange = 2.0...6.0
            let start = Date.now
            
            Slider(value: $settings.toastAutoHideDelay, in: autoHideRange, step: 1.0) {
                
                Text("Auto-hide Delay")
            } minimumValueLabel: {
                let end = start + autoHideRange.lowerBound
                Text("\(start..<end, format: .components(style: .abbreviated))")
            } maximumValueLabel: {
                let end = start + autoHideRange.upperBound
                Text("\(start..<end, format: .components(style: .abbreviated))")
            }
            .frame(width: 300)
            
            Spacer()
            
            Button {
                NSApp.terminate(nil)
            } label: {
                Text("Quit")
                    .frame(minWidth: 75)
                    .foregroundStyle(.red)
            }
            .controlSize(.large)
            
        }
        .padding()
        .frame(width: 400, height: 300, alignment: .top)
#if !DEBUG
        .onAppear {
            NSApp.setActivationPolicy(.regular)
        }
        .onDisappear {
            NSApp.setActivationPolicy(.accessory)
        }
#endif
    }
}

#Preview {
    DTSettingsView()
}
