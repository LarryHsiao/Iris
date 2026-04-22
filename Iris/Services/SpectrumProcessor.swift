import Accelerate
import Foundation

final class SpectrumProcessor {
    let bandCount: Int
    private let fftSize: Int
    private let fft: vDSP.FFT<DSPSplitComplex>
    private var window: [Float]
    private var smoothed: [Float]

    init(bandCount: Int = 32, fftSize: Int = 512) {
        precondition((fftSize & (fftSize - 1)) == 0, "fftSize must be a power of two")
        self.bandCount = bandCount
        self.fftSize = fftSize
        let log2n = UInt(log2(Double(fftSize)))
        self.fft = vDSP.FFT(log2n: log2n, radix: .radix2, ofType: DSPSplitComplex.self)!
        var window = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
        self.window = window
        self.smoothed = [Float](repeating: 0, count: bandCount)
    }

    func process(samples: [Float]) -> [Float] {
        guard samples.count >= fftSize else { return smoothed }

        let input = Array(samples.prefix(fftSize))
        var windowed = [Float](repeating: 0, count: fftSize)
        vDSP.multiply(input, window, result: &windowed)

        var realp = [Float](repeating: 0, count: fftSize / 2)
        var imagp = [Float](repeating: 0, count: fftSize / 2)
        var magnitudes = [Float](repeating: 0, count: fftSize / 2)

        realp.withUnsafeMutableBufferPointer { rp in
            imagp.withUnsafeMutableBufferPointer { ip in
                var split = DSPSplitComplex(realp: rp.baseAddress!, imagp: ip.baseAddress!)
                windowed.withUnsafeBufferPointer { wp in
                    wp.baseAddress!.withMemoryRebound(
                        to: DSPComplex.self,
                        capacity: fftSize / 2
                    ) { cp in
                        vDSP_ctoz(cp, 2, &split, 1, vDSP_Length(fftSize / 2))
                    }
                }
                fft.forward(input: split, output: &split)
                vDSP.absolute(split, result: &magnitudes)
            }
        }

        let fftScale: Float = 2.0 / Float(fftSize)
        vDSP.multiply(fftScale, magnitudes, result: &magnitudes)

        let halfSize = Float(fftSize / 2)
        let logSpan = log2(halfSize)
        var bars = [Float](repeating: 0, count: bandCount)
        for band in 0..<bandCount {
            let lo = max(1, Int(pow(2, Float(band) * logSpan / Float(bandCount))))
            let hi = max(lo + 1, Int(pow(2, Float(band + 1) * logSpan / Float(bandCount))))
            let upper = min(hi, fftSize / 2)
            let count = upper - lo
            guard count > 0 else { continue }
            var avg: Float = 0
            magnitudes.withUnsafeBufferPointer { bp in
                vDSP_meamgv(bp.baseAddress!.advanced(by: lo), 1, &avg, vDSP_Length(count))
            }
            bars[band] = avg
        }

        let floor: Float = -70
        let ceiling: Float = -20
        let span = ceiling - floor
        let tilt: Float = 15
        let volume = VolumeMonitor.current()
        let lastBand = Float(max(bandCount - 1, 1))
        for i in 0..<bandCount {
            let db = 20 * log10(max(bars[i], 1e-6))
            let lowShelf = tilt * (lastBand - Float(i)) / lastBand
            let norm = max(0, min(1, (db - lowShelf - floor) / span))
            let scaled = norm * volume
            smoothed[i] = max(scaled, smoothed[i] * 0.75)
        }
        return smoothed
    }

    func reset() {
        smoothed = [Float](repeating: 0, count: bandCount)
    }
}
