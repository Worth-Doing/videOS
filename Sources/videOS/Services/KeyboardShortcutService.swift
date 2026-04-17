import SwiftUI

enum KeyboardAction {
    case togglePlay
    case seekForward
    case seekForwardLarge
    case seekForwardSmall
    case seekBackward
    case seekBackwardLarge
    case seekBackwardSmall
    case volumeUp
    case volumeDown
    case toggleMute
    case toggleFullscreen
    case speedUp
    case speedDown
    case speedReset
    case nextTrack
    case previousTrack
    case snapshot
}

struct KeyboardShortcuts {
    static let bindings: [(KeyEquivalent, EventModifiers, KeyboardAction)] = [
        (" ",          [],        .togglePlay),
        (.rightArrow,  [],        .seekForward),
        (.rightArrow,  .shift,    .seekForwardLarge),
        (.rightArrow,  .option,   .seekForwardSmall),
        (.leftArrow,   [],        .seekBackward),
        (.leftArrow,   .shift,    .seekBackwardLarge),
        (.leftArrow,   .option,   .seekBackwardSmall),
        (.upArrow,     [],        .volumeUp),
        (.downArrow,   [],        .volumeDown),
        ("m",          [],        .toggleMute),
        ("f",          .command,  .toggleFullscreen),
        ("]",          [],        .speedUp),
        ("[",          [],        .speedDown),
        ("=",          [],        .speedReset),
        ("n",          .command,  .nextTrack),
        ("p",          .command,  .previousTrack),
    ]

    static let seekInterval: Double = AppConstants.seekInterval
    static let seekIntervalLarge: Double = AppConstants.seekIntervalLarge
    static let seekIntervalSmall: Double = AppConstants.seekIntervalSmall
    static let volumeStep: Int = AppConstants.volumeStep
    static let speedSteps: [Float] = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 3.0, 4.0]
}
