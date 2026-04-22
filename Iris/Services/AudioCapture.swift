import AVFoundation
import CoreGraphics
import CoreMedia
import ScreenCaptureKit

@MainActor
final class AudioCapture {
    static let bandCount = 32

    enum Status: Equatable {
        case idle
        case running
        case permissionDenied
        case failed(String)
    }

    private var stream: SCStream?
    private let processor = SpectrumProcessor(bandCount: bandCount)
    private let output = Output()
    private let queue = DispatchQueue(label: "iris.audio.capture", qos: .userInitiated)

    var onBands: (([Float]) -> Void)?
    var onStatus: ((Status) -> Void)?

    func start() async {
        guard stream == nil else { return }

        let granted = CGPreflightScreenCaptureAccess()
        if !granted {
            print("[AudioCapture] screen recording permission not granted; requesting")
            let approved = CGRequestScreenCaptureAccess()
            print("[AudioCapture] permission prompt returned \(approved)")
            if !approved {
                onStatus?(.permissionDenied)
                return
            }
            // After first grant, macOS requires the app to relaunch before SCStream works.
            onStatus?(.permissionDenied)
            return
        }

        do {
            let content = try await SCShareableContent.excludingDesktopWindows(
                true,
                onScreenWindowsOnly: true
            )
            guard let display = content.displays.first else {
                onStatus?(.failed("no display"))
                return
            }
            let filter = SCContentFilter(display: display, excludingWindows: [])
            let config = SCStreamConfiguration()
            config.capturesAudio = true
            config.excludesCurrentProcessAudio = true
            config.sampleRate = 48_000
            config.channelCount = 2
            config.width = 2
            config.height = 2
            config.showsCursor = false
            config.minimumFrameInterval = CMTime(value: 1, timescale: 4)

            output.processor = processor
            output.onBands = { [weak self] bands in
                Task { @MainActor in self?.onBands?(bands) }
            }

            let s = SCStream(filter: filter, configuration: config, delegate: nil)
            try s.addStreamOutput(output, type: .audio, sampleHandlerQueue: queue)
            try s.addStreamOutput(output, type: .screen, sampleHandlerQueue: queue)
            try await s.startCapture()
            stream = s
            onStatus?(.running)
            print("[AudioCapture] stream started")
        } catch {
            print("[AudioCapture] start failed: \(error)")
            stream = nil
            onStatus?(.failed(error.localizedDescription))
        }
    }

    func stop() async {
        guard let s = stream else { return }
        try? await s.stopCapture()
        stream = nil
        processor.reset()
        onBands?([Float](repeating: 0, count: Self.bandCount))
        onStatus?(.idle)
    }
}

private final class Output: NSObject, SCStreamOutput {
    var processor: SpectrumProcessor?
    var onBands: (([Float]) -> Void)?

    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of outputType: SCStreamOutputType
    ) {
        guard outputType == .audio, let processor else { return }
        guard let mono = Self.mono(from: sampleBuffer) else { return }
        let bands = processor.process(samples: mono)
        onBands?(bands)
    }

    private static func mono(from sampleBuffer: CMSampleBuffer) -> [Float]? {
        var listSize: Int = 0
        var status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: &listSize,
            bufferListOut: nil,
            bufferListSize: 0,
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: 0,
            blockBufferOut: nil
        )
        guard status == noErr, listSize > 0 else { return nil }

        let raw = UnsafeMutableRawPointer.allocate(
            byteCount: listSize,
            alignment: MemoryLayout<AudioBufferList>.alignment
        )
        defer { raw.deallocate() }
        let ablPtr = raw.assumingMemoryBound(to: AudioBufferList.self)

        var blockBuffer: CMBlockBuffer?
        status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: nil,
            bufferListOut: ablPtr,
            bufferListSize: listSize,
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: 0,
            blockBufferOut: &blockBuffer
        )
        guard status == noErr else { return nil }

        let buffers = UnsafeMutableAudioBufferListPointer(ablPtr)
        var channels: [[Float]] = []
        var minFrames = Int.max
        for buf in buffers {
            guard let data = buf.mData else { continue }
            let chans = max(1, Int(buf.mNumberChannels))
            let totalFloats = Int(buf.mDataByteSize) / MemoryLayout<Float>.size
            let frames = totalFloats / chans
            guard frames > 0 else { continue }
            let ptr = data.bindMemory(to: Float.self, capacity: totalFloats)
            if chans == 1 {
                channels.append(Array(UnsafeBufferPointer(start: ptr, count: frames)))
            } else {
                for c in 0..<chans {
                    var arr = [Float](repeating: 0, count: frames)
                    for i in 0..<frames { arr[i] = ptr[i * chans + c] }
                    channels.append(arr)
                }
            }
            minFrames = min(minFrames, frames)
        }
        guard !channels.isEmpty, minFrames > 0, minFrames != .max else { return nil }

        var mono = [Float](repeating: 0, count: minFrames)
        let divisor = Float(channels.count)
        for i in 0..<minFrames {
            var sum: Float = 0
            for ch in channels { sum += ch[i] }
            mono[i] = sum / divisor
        }
        return mono
    }
}
