//
//  ViewController.swift
//  CaptureVideoFilterPractice
//
//  Created by ZK on 16/8/25.
//  Copyright © 2016年 ZK. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary
import Photos


class ViewController: UIViewController , AVCaptureVideoDataOutputSampleBufferDelegate , AVCaptureMetadataOutputObjectsDelegate {
    
    // MARK: - Photos
    var image: UIImage!
    var assetCollection: PHAssetCollection!
    var albumFound : Bool = false
    var photosAsset: PHFetchResult<PHAsset>!
    var assetThumbnailSize:CGSize!
    var collection: PHAssetCollection!
    var assetCollectionPlaceholder: PHObjectPlaceholder!
    
    // MARK: - CIFilter
    @IBOutlet var filterButtonsContainer: UIView!
    var captureSession: AVCaptureSession!
    var previewLayer: CALayer!
    var filter: CIFilter!
    lazy var context: CIContext = {
        let testEAGLContext = EAGLContext.init(api: .openGLES2)
        let testContext = CIContext.init(eaglContext: testEAGLContext!)
        return testContext
    }()
    lazy var filterNames: [String] = {
        return ["CIColorInvert","CIPhotoEffectMono","CIPhotoEffectInstant","CIPhotoEffectTransfer"]
    }()
    var ciImage: CIImage!
    
    // 标记人脸
    // var faceLayer: CALayer?
    var faceObject: AVMetadataFaceObject?
    
    // Video Records
    @IBOutlet var recordsButton: UIButton!
    var assetWriter: AVAssetWriter?
    var assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor?
    var isWriting = false
    var currentSampleTime: CMTime?
    var currentVideoDimensions: CMVideoDimensions?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        previewLayer = CALayer()
        // previewLayer.bounds = CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width);
        // previewLayer.position = CGPointMake(self.view.frame.size.width / 2.0, self.view.frame.size.height / 2.0);
        // previewLayer.setAffineTransform(CGAffineTransformMakeRotation(CGFloat(M_PI / 2.0)));
        previewLayer.anchorPoint = CGPoint.zero
        previewLayer.bounds = view.bounds
        
        filterButtonsContainer.isHidden = true
        
        self.view.layer.insertSublayer(previewLayer, at: 0)
        
        if TARGET_IPHONE_SIMULATOR == 1 {
            //UIAlertView(title: "提示", message: "不支持模拟器", delegate: nil, cancelButtonTitle: "确定").show()
        } else {
            setupCaptureSession()
        }
    }
    
    func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        previewLayer.bounds.size = size
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        let deviceInput = try! AVCaptureDeviceInput(device: captureDevice)
        if captureSession.canAddInput(deviceInput) {
            captureSession.addInput(deviceInput)
        }
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey : Int(kCVPixelFormatType_32BGRA)]
        dataOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(dataOutput) {
            captureSession.addOutput(dataOutput)
        }
        
        let queue = DispatchQueue(label: "VideoQueue")
        dataOutput.setSampleBufferDelegate(self, queue: queue)
        
        // 为了检测人脸
        let metadataOutput = AVCaptureMetadataOutput()
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            print(metadataOutput.availableMetadataObjectTypes)
            metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeFace]
        }
        
        captureSession.commitConfiguration()
    }
    
    @IBAction func openCamera(sender: UIButton) {
        sender.isEnabled = false
        captureSession.startRunning()
        self.filterButtonsContainer.isHidden = false
    }
    
    @IBAction func applyFilter(sender: UIButton) {
        let filterName = filterNames[sender.tag]
        filter = CIFilter(name: filterName)
    }
    
    @IBAction func takePicture(sender: UIButton) {
        if ciImage == nil || isWriting {
            return
        }
        sender.isEnabled = false
        captureSession.stopRunning()
        
        let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
        
        image = UIImage.init(cgImage: cgImage!)
        self.createAlbum()
        self.saveImage()
    }
    
    func createAlbum() {
        //Get PHFetch Options
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", "camcam")
        let collection : PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        //Check return value - If found, then get the first album out
        if let _: AnyObject = collection.firstObject {
            self.albumFound = true
            assetCollection = collection.firstObject
        } else {
            //If not found - Then create a new album
            PHPhotoLibrary.shared().performChanges({
                let createAlbumRequest : PHAssetCollectionChangeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: "camcam")
                self.assetCollectionPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
                }, completionHandler: { success, error in
                    self.albumFound = (success ? true: false)
                    
                    if (success) {
                        let collectionFetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [self.assetCollectionPlaceholder.localIdentifier], options: nil)
                        print(collectionFetchResult)
                        self.assetCollection = collectionFetchResult.firstObject
                    }
            })
        }
    }
    
    func saveImage(){
        PHPhotoLibrary.shared().performChanges({
            let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: self.image)
            let assetPlaceholder = assetRequest.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest.init(for: self.assetCollection, assets: self.photosAsset)
            albumChangeRequest!.addAssets([assetPlaceholder!])
            }, completionHandler: { success, error in
                print("added image to album")
                print(error)
                
                //self.showImages()
        })
    }
    
    func saveVideo(){
        PHPhotoLibrary.shared().performChanges({
            let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.movieURL() as URL)
            let assetPlaceholder = assetRequest?.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest.init(for: self.assetCollection, assets: self.photosAsset)
            albumChangeRequest!.addAssets([assetPlaceholder!])
            }, completionHandler: { success, error in
                print("added image to album")
                print(error)
                
                //self.showImages()
        })
    }
    

    #if false
    func showImages() {
        //This will fetch all the assets in the collection
        
        let assets : PHFetchResult = PHAsset.fetchAssets(in: assetCollection, options: nil)
        print(assets)
        
        let imageManager = PHCachingImageManager()
        //Enumerating objects to get a chached image - This is to save loading time
        assets.en{(object: AnyObject!,
            count: Int,
            stop: UnsafeMutablePointer<ObjCBool>) in
            
            if object is PHAsset {
                let asset = object as! PHAsset
                print(asset)
                
                let imageSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
                
                let options = PHImageRequestOptions()
                options.deliveryMode = .FastFormat
                
                imageManager.requestImageForAsset(asset, targetSize: imageSize, contentMode: .AspectFill, options: options, resultHandler: {(image: UIImage?,
                    info: [NSObject : AnyObject]?) in
                    print(info)
                    print(image)
                })
            }
        }
    }
    #endif
    
    // MARK: - Video Records
    @IBAction func record() {
        if isWriting {
            self.isWriting = false
            assetWriterPixelBufferInput = nil
            recordsButton.isEnabled = false
            assetWriter?.finishWriting(completionHandler: {[unowned self] () -> Void in
                print("录制完成")
                self.recordsButton.setTitle("处理中...", for: UIControlState.normal)
                self.saveVideo()
                })
        } else {
            createWriter()
            recordsButton.setTitle("停止录制...", for: UIControlState.normal)
            assetWriter?.startWriting()
            assetWriter?.startSession(atSourceTime: currentSampleTime!)
            isWriting = true
        }
    }
    
    #if false
    func saveMovieToCameraRoll() {
        ALAssetsLibrary().writeVideoAtPathToSavedPhotosAlbum(movieURL() as URL!, completionBlock: { (url: NSURL!, error: NSError?) -> Void in
            if let errorDescription = error?.localizedDescription {
                print("写入视频错误：\(errorDescription)")
            } else {
                self.checkForAndDeleteFile()
                print("写入视频成功")
            }
            self.recordsButton.enabled = true
            self.recordsButton.setTitle("开始录制", forState: UIControlState.Normal)
        })
    }
    #endif

    func movieURL() -> NSURL {
        let tempDir = NSTemporaryDirectory()
        let url = NSURL(fileURLWithPath: tempDir).appendingPathComponent("tmpMov.mov")
        return url!
    }
    
    func checkForAndDeleteFile() {
        let fm = FileManager.default
        let url = movieURL()
        let exist = fm.fileExists(atPath: url.path!)
        
        if exist {
            print("删除之前的临时文件")
            do {
                try fm.removeItem(at: url as URL)
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
    }
    
    func createWriter() {
        self.checkForAndDeleteFile()
        
        do {
            assetWriter = try AVAssetWriter.init(url: movieURL() as URL, fileType: AVFileTypeQuickTimeMovie)
        } catch let error as NSError {
            print("创建writer失败")
            print(error.localizedDescription)
            return
        }
        
        let outputSettings = [
            AVVideoCodecKey : AVVideoCodecH264,
            AVVideoWidthKey : Int(currentVideoDimensions!.width),
            AVVideoHeightKey : Int(currentVideoDimensions!.height)
        ]
        
        let assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: outputSettings as? [String : AnyObject])
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        assetWriterVideoInput.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI / 2.0))
        
        let sourcePixelBufferAttributesDictionary = [
            String(kCVPixelBufferPixelFormatTypeKey) : Int(kCVPixelFormatType_32BGRA),
            String(kCVPixelBufferWidthKey) : Int(currentVideoDimensions!.width),
            String(kCVPixelBufferHeightKey) : Int(currentVideoDimensions!.height),
            String(kCVPixelFormatOpenGLESCompatibility) : Int(kCFBooleanTrue)
        ]
        
        assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput,
                                                                           sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        
        if assetWriter!.canAdd(assetWriterVideoInput) {
            assetWriter!.add(assetWriterVideoInput)
        } else {
            print("不能添加视频writer的input \(assetWriterVideoInput)")
        }
    }
    
    func makeFaceWithCIImage(inputImage: CIImage, faceObject: AVMetadataFaceObject) -> CIImage {
        let filter = CIFilter(name: "CIPixellate")!
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        // 1.
        filter.setValue(max(inputImage.extent.size.width, inputImage.extent.size.height) / 60, forKey: kCIInputScaleKey)
        
        let fullPixellatedImage = filter.outputImage
        
        var maskImage: CIImage!
        let faceBounds = faceObject.bounds
        
        // 2.
        let centerX = inputImage.extent.size.width * (faceBounds.origin.x + faceBounds.size.width / 2)
        let centerY = inputImage.extent.size.height * (1 - faceBounds.origin.y - faceBounds.size.height / 2)
        let radius = faceBounds.size.width * inputImage.extent.size.width / 2
        let radialGradient = CIFilter(name: "CIRadialGradient",
                                      withInputParameters: [
                                        "inputRadius0" : radius,
                                        "inputRadius1" : radius + 1,
                                        "inputColor0" : CIColor(red: 0, green: 1, blue: 0, alpha: 1),
                                        "inputColor1" : CIColor(red: 0, green: 0, blue: 0, alpha: 0),
                                        kCIInputCenterKey : CIVector(x: centerX, y: centerY)
            ])!
        
        let radialGradientOutputImage = radialGradient.outputImage!.cropping(to: inputImage.extent)
        if maskImage == nil {
            maskImage = radialGradientOutputImage
        } else {
            print(radialGradientOutputImage)
            maskImage = CIFilter(name: "CISourceOverCompositing",
                                 withInputParameters: [
                                    kCIInputImageKey : radialGradientOutputImage,
                                    kCIInputBackgroundImageKey : maskImage
                ])!.outputImage
        }
        
        let blendFilter = CIFilter(name: "CIBlendWithMask")!
        blendFilter.setValue(fullPixellatedImage, forKey: kCIInputImageKey)
        blendFilter.setValue(inputImage, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(maskImage, forKey: kCIInputMaskImageKey)
        
        return blendFilter.outputImage!
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ captureOutput: AVCaptureOutput!,didOutputSampleBuffer sampleBuffer: CMSampleBuffer!,from connection: AVCaptureConnection!) {
        autoreleasepool {
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
            
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)!
            self.currentVideoDimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
            self.currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
            
            // CVPixelBufferLockBaseAddress(imageBuffer, 0)
            // let width = CVPixelBufferGetWidthOfPlane(imageBuffer, 0)
            // let height = CVPixelBufferGetHeightOfPlane(imageBuffer, 0)
            // let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0)
            // let lumaBuffer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
            //
            // let grayColorSpace = CGColorSpaceCreateDeviceGray()
            // let context = CGBitmapContextCreate(lumaBuffer, width, height, 8, bytesPerRow, grayColorSpace, CGBitmapInfo.allZeros)
            // let cgImage = CGBitmapContextCreateImage(context)
            var outputImage = CIImage.init(cvPixelBuffer: imageBuffer)
            
            if self.filter != nil {
                self.filter.setValue(outputImage, forKey: kCIInputImageKey)
                outputImage = self.filter.outputImage!
            }
            if self.faceObject != nil {
                outputImage = self.makeFaceWithCIImage(inputImage: outputImage, faceObject: self.faceObject!)
            }
            
            // 录制视频的处理
            if self.isWriting {
                if self.assetWriterPixelBufferInput?.assetWriterInput.isReadyForMoreMediaData == true {
                    var newPixelBuffer: CVPixelBuffer? = nil
                    
                    CVPixelBufferPoolCreatePixelBuffer(nil, self.assetWriterPixelBufferInput!.pixelBufferPool!, &newPixelBuffer)
                    
                    self.context.render(outputImage, to: newPixelBuffer!, bounds: outputImage.extent, colorSpace: nil)
                    
                    let success = self.assetWriterPixelBufferInput?.append(newPixelBuffer!, withPresentationTime: self.currentSampleTime!)
                    
                    if success == false {
                        print("Pixel Buffer没有附加成功")
                    }
                }
            }
            
            let orientation = UIDevice.current.orientation
            var t: CGAffineTransform!
            if orientation == UIDeviceOrientation.portrait {
                t = CGAffineTransform(rotationAngle: CGFloat(-M_PI / 2.0))
            } else if orientation == UIDeviceOrientation.portraitUpsideDown {
                t = CGAffineTransform(rotationAngle: CGFloat(M_PI / 2.0))
            } else if (orientation == UIDeviceOrientation.landscapeRight) {
                t = CGAffineTransform(rotationAngle: CGFloat(M_PI))
            } else {
                t = CGAffineTransform(rotationAngle: 0)
            }
            outputImage = outputImage.applying(t)
            
            let cgImage = self.context.createCGImage(outputImage, from: outputImage.extent)
            self.ciImage = outputImage
            
            DispatchQueue.main.sync(execute: {
                self.previewLayer.contents = cgImage
            })
        }
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, from connection: AVCaptureConnection!) {
        // print(metadataObjects)
        if metadataObjects.count > 0 {
            //识别到的第一张脸
            faceObject = metadataObjects.first as? AVMetadataFaceObject
            
            /*
             if faceLayer == nil {
             faceLayer = CALayer()
             faceLayer?.borderColor = UIColor.redColor().CGColor
             faceLayer?.borderWidth = 1
             view.layer.addSublayer(faceLayer)
             }
             let faceBounds = faceObject.bounds
             let viewSize = view.bounds.size
             
             faceLayer?.position = CGPoint(x: viewSize.width * (1 - faceBounds.origin.y - faceBounds.size.height / 2),
             y: viewSize.height * (faceBounds.origin.x + faceBounds.size.width / 2))
             
             faceLayer?.bounds.size = CGSize(width: faceBounds.size.height * viewSize.width,
             height: faceBounds.size.width * viewSize.height)
             print(faceBounds.origin)
             print("###")
             print(faceLayer!.position)
             print("###")
             print(faceLayer!.bounds)
             */
        }
    }
}



