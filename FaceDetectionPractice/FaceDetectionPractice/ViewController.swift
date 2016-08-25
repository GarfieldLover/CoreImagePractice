//
//  ViewController.swift
//  FaceDetectionPractice
//
//  Created by ZK on 16/8/25.
//  Copyright © 2016年 ZK. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var photoImageView: UIImageView!
    
    var originalImage: UIImage {
        return UIImage(named: "962bd40735fae6cd0592fc430cb30f2442a70fe9")!
    }
    var context: CIContext! {
        let testEAGLContext = EAGLContext.init(api: .openGLES3)
        let testContext = CIContext.init(eaglContext: testEAGLContext!)
        return testContext
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func faceDetecing() {
        let inputImage = CIImage(image: originalImage)!
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        var faceFeatures: [CIFaceFeature]!
        if let orientation: AnyObject = inputImage.properties[kCIInputImageOrientationKey as String] {
            faceFeatures = detector?.features(in: inputImage, options: [CIDetectorImageOrientation: orientation]) as! [CIFaceFeature]
        } else {
            faceFeatures = detector?.features(in: inputImage)as! [CIFaceFeature]
        }
        //取得CIFaceFeature
        
        // 1.
        let inputImageSize = inputImage.extent.size
        var transform = CGAffineTransform.identity
        transform = transform.scaledBy(x: 1, y: -1)
        transform = transform.translatedBy(x: 0, y: -inputImageSize.height)
        
        for faceFeature in faceFeatures {
            //坐标反转？
            var faceViewBounds = faceFeature.bounds.applying(transform)
            
            // 2.
            let scale = min(photoImageView.bounds.size.width / inputImageSize.width,
                            photoImageView.bounds.size.height / inputImageSize.height)
            let offsetX = (photoImageView.bounds.size.width - inputImageSize.width * scale) / 2
            let offsetY = (photoImageView.bounds.size.height - inputImageSize.height * scale) / 2
            //按图片 view比例
            faceViewBounds = faceViewBounds.applying(CGAffineTransform(scaleX: scale, y: scale))
            faceViewBounds.origin.x += offsetX
            faceViewBounds.origin.y += offsetY
            
            let faceView = UIView(frame: faceViewBounds)
            faceView.layer.borderColor = UIColor.orange.cgColor
            faceView.layer.borderWidth = 1
            
            photoImageView.addSubview(faceView)
            
            if faceFeature.hasLeftEyePosition {
                var leftEyePosition = faceFeature.leftEyePosition.applying(transform)
                leftEyePosition = leftEyePosition.applying(CGAffineTransform(scaleX: scale, y: scale))
                let LeftEyeBounds = CGRect.init(x: leftEyePosition.x-2, y: leftEyePosition.y-2, width: 4, height: 4)

                let LeftEyeView = UIView(frame: LeftEyeBounds)
                LeftEyeView.layer.borderColor = UIColor.green.cgColor
                LeftEyeView.layer.borderWidth = 1
                photoImageView.addSubview(LeftEyeView)
            }
            
            if faceFeature.hasRightEyePosition {
                var RightEyePosition = faceFeature.rightEyePosition.applying(transform)
                RightEyePosition = RightEyePosition.applying(CGAffineTransform(scaleX: scale, y: scale))
                let RightEyeBounds = CGRect.init(x: RightEyePosition.x-2, y: RightEyePosition.y-2, width: 4, height: 4)
                
                let RightEyeView = UIView(frame: RightEyeBounds)
                RightEyeView.layer.borderColor = UIColor.green.cgColor
                RightEyeView.layer.borderWidth = 1
                photoImageView.addSubview(RightEyeView)
            }
            
            if faceFeature.hasMouthPosition {
                var RightEyePosition = faceFeature.mouthPosition.applying(transform)
                RightEyePosition = RightEyePosition.applying(CGAffineTransform(scaleX: scale, y: scale))
                let RightEyeBounds = CGRect.init(x: RightEyePosition.x-2, y: RightEyePosition.y-2, width: 4, height: 4)
                
                let RightEyeView = UIView(frame: RightEyeBounds)
                RightEyeView.layer.borderColor = UIColor.green.cgColor
                RightEyeView.layer.borderWidth = 1
                photoImageView.addSubview(RightEyeView)
            }
            if faceFeature.hasFaceAngle {
                print(faceFeature.faceAngle)
            }
            if faceFeature.hasSmile {

            }
            if faceFeature.leftEyeClosed {
                
            }
            if faceFeature.rightEyeClosed {
                
            }
        }
    }
    
    @IBAction func pixellated() {
        // 1.
        //马赛克，全图
        let filter = CIFilter(name: "CIPixellate")!
        print(filter.attributes)
        let inputImage = CIImage(image: originalImage)!
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        let fullPixellatedImage = filter.outputImage
        
        // 2.
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: context, options: nil)
        let faceFeatures = detector?.features(in: inputImage)
        // 3.
        var maskImage: CIImage!
        let scale = min(photoImageView.bounds.size.width / inputImage.extent.size.width,
                        photoImageView.bounds.size.height / inputImage.extent.size.height)
        for faceFeature in faceFeatures! {
            // 4.
            //圆形mask
            let centerX = faceFeature.bounds.origin.x + faceFeature.bounds.size.width / 2
            let centerY = faceFeature.bounds.origin.y + faceFeature.bounds.size.height / 2
            let radius = min(faceFeature.bounds.size.width, faceFeature.bounds.size.height) * scale
            let radialGradient = CIFilter(name: "CIRadialGradient",
                                          withInputParameters: [
                                            "inputRadius0" : radius,
                                            "inputRadius1" : radius + 1,
                                            "inputColor0" : CIColor(red: 0, green: 1, blue: 0, alpha: 1),
                                            "inputColor1" : CIColor(red: 0, green: 0, blue: 0, alpha: 0),
                                            kCIInputCenterKey : CIVector(x: centerX, y: centerY)
                ])!
            
            // 5.
            let radialGradientOutputImage = radialGradient.outputImage!.cropping(to: inputImage.extent)
            if maskImage == nil {
                maskImage = radialGradientOutputImage
            } else {
                //合成多个mask
                print(radialGradientOutputImage)
                maskImage = CIFilter(name: "CISourceOverCompositing",
                                     withInputParameters: [
                                        kCIInputImageKey : radialGradientOutputImage,
                                        kCIInputBackgroundImageKey : maskImage
                    ])!.outputImage
            }
            print(maskImage.extent)
        }
        // 6.
        //用mask混合，有mask的地方才有fullPixellatedImage
        let blendFilter = CIFilter(name: "CIBlendWithMask")!
        blendFilter.setValue(fullPixellatedImage, forKey: kCIInputImageKey)
        blendFilter.setValue(inputImage, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(maskImage, forKey: kCIInputMaskImageKey)
        // 7.
        let blendOutputImage = blendFilter.outputImage!
        let blendCGImage = context.createCGImage(blendOutputImage, from: blendOutputImage.extent)
        photoImageView.image = UIImage(cgImage: blendCGImage!)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

