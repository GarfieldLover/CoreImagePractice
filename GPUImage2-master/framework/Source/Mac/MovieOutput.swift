import AVFoundation

public protocol AudioEncodingTarget {
    func activateAudioTrack()
    func processAudioBuffer(sampleBuffer:CMSampleBuffer)
}

public class MovieOutput: ImageConsumer, AudioEncodingTarget {
    public let sources = SourceContainer()
    public let maximumInputs:UInt = 1

    let assetWriter:AVAssetWriter
    let assetWriterVideoInput:AVAssetWriterInput
    var assetWriterAudioInput:AVAssetWriterInput?
    let assetWriterPixelBufferInput:AVAssetWriterInputPixelBufferAdaptor
    let size:Size
    private var isRecording = false
    private var videoEncodingIsFinished = false
    private var audioEncodingIsFinished = false
    private var startTime:CMTime?
    private var previousFrameTime = kCMTimeNegativeInfinity
    private var previousAudioTime = kCMTimeNegativeInfinity
    private var encodingLiveVideo:Bool
    
    public init(URL:NSURL, size:Size, fileType:String = AVFileTypeQuickTimeMovie, liveVideo:Bool = false, settings:[String:AnyObject]? = nil) throws {
        self.size = size
        assetWriter = try AVAssetWriter(URL:URL, fileType:fileType)
        // Set this to make sure that a functional movie is produced, even if the recording is cut off mid-stream. Only the last second should be lost in that case.
        assetWriter.movieFragmentInterval = CMTimeMakeWithSeconds(1.0, 1000)

        var localSettings:[String:AnyObject]
        if let settings = settings {
            localSettings = settings
        } else {
            localSettings = [String:AnyObject]()
        }

        localSettings[AVVideoWidthKey] = localSettings[AVVideoWidthKey] ?? NSNumber(float:size.width)
        localSettings[AVVideoHeightKey] = localSettings[AVVideoHeightKey] ?? NSNumber(float:size.height)
        localSettings[AVVideoCodecKey] =  localSettings[AVVideoCodecKey] ?? AVVideoCodecH264

        assetWriterVideoInput = AVAssetWriterInput(mediaType:AVMediaTypeVideo, outputSettings:localSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = liveVideo
        encodingLiveVideo = liveVideo
        
        // You need to use BGRA for the video in order to get realtime encoding. I use a color-swizzling shader to line up glReadPixels' normal RGBA output with the movie input's BGRA.
        let sourcePixelBufferAttributesDictionary:[String:AnyObject] = [kCVPixelBufferPixelFormatTypeKey as String:NSNumber(int:Int32(kCVPixelFormatType_32BGRA)),
                                                     kCVPixelBufferWidthKey as String:NSNumber(float:size.width),
                                                     kCVPixelBufferHeightKey as String:NSNumber(float:size.height)]
        
        assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput:assetWriterVideoInput, sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary)
        assetWriter.addInput(assetWriterVideoInput)
    }
    
    public func startRecording() {
        startTime = nil
        sharedImageProcessingContext.runOperationSynchronously{
            self.isRecording = self.assetWriter.startWriting()
        }
    }
    
    public func finishRecording(completionCallback:(() -> Void)? = nil) {
        sharedImageProcessingContext.runOperationSynchronously{
            self.isRecording = false
            
            if (self.assetWriter.status == .Completed || self.assetWriter.status == .Cancelled || self.assetWriter.status == .Unknown) {
                sharedImageProcessingContext.runOperationAsynchronously{
                    completionCallback?()
                }
                return
            }
            if ((self.assetWriter.status == .Writing) && (!self.videoEncodingIsFinished)) {
                self.videoEncodingIsFinished = true
                self.assetWriterVideoInput.markAsFinished()
            }
            if ((self.assetWriter.status == .Writing) && (!self.audioEncodingIsFinished)) {
                self.audioEncodingIsFinished = true
                self.assetWriterAudioInput?.markAsFinished()
            }

            // Why can't I use ?? here for the callback?
            if let callback = completionCallback {
                self.assetWriter.finishWritingWithCompletionHandler(callback)
            } else {
                self.assetWriter.finishWritingWithCompletionHandler{}
                
            }
        }
    }
    
    public func newFramebufferAvailable(framebuffer:Framebuffer, fromSourceIndex:UInt) {
        defer {
            framebuffer.unlock()
        }
        
        guard isRecording else { return }
        // Ignore still images and other non-video updates (do I still need this?)
        guard let frameTime = framebuffer.timingStyle.timestamp?.asCMTime else { return }
        // If two consecutive times with the same value are added to the movie, it aborts recording, so I bail on that case
        guard (frameTime != previousFrameTime) else { return }
        
        if (startTime == nil) {
            if (assetWriter.status != .Writing) {
                assetWriter.startWriting()
            }
            
            assetWriter.startSessionAtSourceTime(frameTime)
            startTime = frameTime
        }

        // TODO: Run the following on an internal movie recording dispatch queue, context
        guard (assetWriterVideoInput.readyForMoreMediaData || (!encodingLiveVideo)) else {
            debugPrint("Had to drop a frame at time \(frameTime)")
            return
        }
        
        var pixelBufferFromPool:CVPixelBuffer? = nil

        let pixelBufferStatus = CVPixelBufferPoolCreatePixelBuffer(nil, assetWriterPixelBufferInput.pixelBufferPool!, &pixelBufferFromPool)
        guard let pixelBuffer = pixelBufferFromPool where (pixelBufferStatus == kCVReturnSuccess) else { return }

        
        
        renderIntoPixelBuffer(pixelBuffer, framebuffer:framebuffer)

        if (!assetWriterPixelBufferInput.appendPixelBuffer(pixelBuffer, withPresentationTime:frameTime)) {
            print("Problem appending pixel buffer at time: \(frameTime)")
        }
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0)
    }
    
    func renderIntoPixelBuffer(pixelBuffer:CVPixelBuffer, framebuffer:Framebuffer) {
        let renderFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:framebuffer.orientation, size:GLSize(self.size))
        renderFramebuffer.lock()
        
        renderFramebuffer.activateFramebufferForRendering()
        clearFramebufferWithColor(Color.Black)

        renderQuadWithShader(sharedImageProcessingContext.passthroughShader, uniformSettings:ShaderUniformSettings(), vertices:standardImageVertices, inputTextures:[framebuffer.texturePropertiesForOutputRotation(.NoRotation)])

        CVPixelBufferLockBaseAddress(pixelBuffer, 0)
        glReadPixels(0, 0, renderFramebuffer.size.width, renderFramebuffer.size.height, GLenum(GL_BGRA), GLenum(GL_UNSIGNED_BYTE), CVPixelBufferGetBaseAddress(pixelBuffer))
        renderFramebuffer.unlock()
    }
    
    // MARK: -
    // MARK: Audio support
    
    public func activateAudioTrack() {
        // TODO: Add ability to set custom output settings
        assetWriterAudioInput = AVAssetWriterInput(mediaType:AVMediaTypeAudio, outputSettings:nil)
        assetWriter.addInput(assetWriterAudioInput!)
        assetWriterAudioInput?.expectsMediaDataInRealTime = encodingLiveVideo
    }
    
    public func processAudioBuffer(sampleBuffer:CMSampleBuffer) {
        guard let assetWriterAudioInput = assetWriterAudioInput else { return }
        
        sharedImageProcessingContext.runOperationSynchronously{
            let currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
            if (self.startTime == nil) {
                if (self.assetWriter.status != .Writing) {
                    self.assetWriter.startWriting()
                }
                
                self.assetWriter.startSessionAtSourceTime(currentSampleTime)
                self.startTime = currentSampleTime
            }
            
            guard (assetWriterAudioInput.readyForMoreMediaData || (!self.encodingLiveVideo)) else {
                return
            }
            
            if (!assetWriterAudioInput.appendSampleBuffer(sampleBuffer)) {
                print("Trouble appending audio sample buffer")
            }
        }
    }
}


public extension Timestamp {
    public init(_ time:CMTime) {
        self.value = time.value
        self.timescale = time.timescale
        self.flags = TimestampFlags(rawValue:time.flags.rawValue)
        self.epoch = time.epoch
    }
    
    public var asCMTime:CMTime {
        get {
            return CMTimeMakeWithEpoch(value, timescale, epoch)
        }
    }
}