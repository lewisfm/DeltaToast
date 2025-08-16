//
//  ToastController.swift
//  DeltaToast
//
//  Created by Lewis McClelland on 8/15/25.
//

import Foundation
import MediaRemoteAdapter

struct Track: Equatable {
    var name: String?
    var artist: String?
    var state: State
    
    enum State: Equatable, Hashable {
        case playing
        case paused
    }
}

@Observable
class ToastController {
    private let media = MediaController()
    
    public private(set) var track: Track?
    
    init() {
        media.onTrackInfoReceived = { [weak self] event in
            guard let self else { return }
            let trackInfo = event.payload
            
            guard let isPlaying = trackInfo.isPlaying else {
                // No active track (e.g. the music app quit)
                self.track = nil
                logger.debug("Displayed track removed")
                return
            }
            
            var name = trackInfo.title ?? self.track?.name
            if name?.isEmpty == true {
                name = nil
            }
            
            var artist = trackInfo.artist ?? self.track?.artist
            if artist?.isEmpty == true {
                artist = nil
            }
            
            let state: Track.State = isPlaying ? .playing : .paused
            
            let track = Track(name: name, artist: artist, state: state)
            self.track = track
            logger.debug("Displayed track updated: \(String(reflecting: track))")
        }
        
        media.startListening()
    }
    
    deinit {
        media.stopListening()
    }
}
