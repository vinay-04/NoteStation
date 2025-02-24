import Vision
import AVFoundation

class HandGestureDetector: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var captureSession: AVCaptureSession?
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var gestureCallback: ((Int) -> Void)?
    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession,
              let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            captureSession.addInput(input)
            videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            captureSession.addOutput(videoDataOutput)
            
            DispatchQueue.global(qos: .background).async {
                captureSession.startRunning()
            }
        } catch {
            print("Camera setup error: \(error)")
        }
    }
    
    func startDetection(callback: @escaping (Int) -> Void) {
        self.gestureCallback = callback
    }
    
    func stopDetection() {
        captureSession?.stopRunning()
    }
    
    private func detectGesture(observation: VNHumanHandPoseObservation) -> Int? {
        guard let points = try? observation.recognizedPoints(.all) else { return nil }
        
        let tipToMCPDistances = [
            calculateDistance(from: points[.indexTip]!, to: points[.indexMCP]!),
            calculateDistance(from: points[.middleTip]!, to: points[.middleMCP]!),
            calculateDistance(from: points[.ringTip]!, to: points[.ringMCP]!),
            calculateDistance(from: points[.littleTip]!, to: points[.littleMCP]!)
        ]
        
        let tipToPIPDistances = [
            calculateDistance(from: points[.indexTip]!, to: points[.indexPIP]!),
            calculateDistance(from: points[.middleTip]!, to: points[.middlePIP]!),
            calculateDistance(from: points[.ringTip]!, to: points[.ringPIP]!),
            calculateDistance(from: points[.littleTip]!, to: points[.littlePIP]!)
        ]
        
        let avgTipToMCP = tipToMCPDistances.reduce(0, +) / Float(tipToMCPDistances.count)
        let avgTipToPIP = tipToPIPDistances.reduce(0, +) / Float(tipToPIPDistances.count)
        
        if avgTipToMCP > 0.15 && avgTipToPIP > 0.1 {
            return 1 
        } else if avgTipToMCP < 0.12 && avgTipToPIP < 0.08 {
            return 0
        }
        return -1  
    }
    
    private func calculateDistance(from point1: VNRecognizedPoint, to point2: VNRecognizedPoint) -> Float {
        let dx = point1.location.x - point2.location.x
        let dy = point1.location.y - point2.location.y
        return Float(sqrt(dx * dx + dy * dy))
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectHumanHandPoseRequest { [weak self] request, error in
            guard let observations = request.results as? [VNHumanHandPoseObservation],
                  observations.count == 1,
                  let gesture = self?.detectGesture(observation: observations[0]) else {
                self?.gestureCallback?(0)
                return
            }
            self?.gestureCallback?(gesture)
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}
