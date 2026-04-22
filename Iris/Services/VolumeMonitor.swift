import CoreAudio
import Foundation

enum VolumeMonitor {
    static func current() -> Float {
        guard let deviceID = defaultOutputDevice() else { return 1.0 }
        if let master = readVolume(device: deviceID, element: kAudioObjectPropertyElementMain) {
            return master
        }
        let left = readVolume(device: deviceID, element: 1) ?? 1.0
        let right = readVolume(device: deviceID, element: 2) ?? 1.0
        return (left + right) / 2
    }

    private static func defaultOutputDevice() -> AudioObjectID? {
        var deviceID = AudioObjectID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &size, &deviceID
        )
        guard status == noErr, deviceID != kAudioObjectUnknown else { return nil }
        return deviceID
    }

    private static func readVolume(device: AudioObjectID, element: UInt32) -> Float? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: element
        )
        guard AudioObjectHasProperty(device, &address) else { return nil }
        var volume: Float = 0
        var size = UInt32(MemoryLayout<Float>.size)
        let status = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &volume)
        guard status == noErr else { return nil }
        return max(0, min(1, volume))
    }
}
