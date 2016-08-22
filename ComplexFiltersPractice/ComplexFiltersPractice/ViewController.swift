//
//  ViewController.swift
//  ComplexFiltersPractice
//
//  Created by ZK on 16/8/22.
//  Copyright © 2016年 ZK. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var photoImageView: UIImageView!

    var originalImage: UIImage {
        return UIImage(named: "f224b1e033f646fedc03bd32bae00c87")!
    }
    var context: CIContext! {
        return CIContext(options: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func oldFilmEffect() {
        let inputImage = CIImage(image: originalImage)!
        // 1.创建CISepiaTone滤镜
        let sepiaToneFilter = CIFilter(name: "CISepiaTone")!
        sepiaToneFilter.setValue(inputImage, forKey: kCIInputImageKey)
        sepiaToneFilter.setValue(1, forKey: kCIInputIntensityKey)
        // 2.创建白班图滤镜
        let whiteSpecksFilter = CIFilter(name: "CIColorMatrix")!
        whiteSpecksFilter.setValue(CIFilter(name: "CIRandomGenerator")!.outputImage!.cropping(to: inputImage.extent), forKey: kCIInputImageKey)
        whiteSpecksFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputRVector")
        whiteSpecksFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
        whiteSpecksFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputBVector")
        whiteSpecksFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBiasVector")
        // 3.把CISepiaTone滤镜和白班图滤镜以源覆盖(source over)的方式先组合起来
        let sourceOverCompositingFilter = CIFilter(name: "CISourceOverCompositing")!
        sourceOverCompositingFilter.setValue(whiteSpecksFilter.outputImage, forKey: kCIInputBackgroundImageKey)
        sourceOverCompositingFilter.setValue(sepiaToneFilter.outputImage, forKey: kCIInputImageKey)
        // ---------上面算是完成了一半
        // 4.用CIAffineTransform滤镜先对随机噪点图进行处理
        let affineTransformFilter = CIFilter(name: "CIAffineTransform")!
        affineTransformFilter.setValue(CIFilter(name: "CIRandomGenerator")!.outputImage!.cropping(to: inputImage.extent), forKey: kCIInputImageKey)
        affineTransformFilter.setValue(NSValue(cgAffineTransform: CGAffineTransform(scaleX: 1.5, y: 25)), forKey: kCIInputTransformKey)
        // 5.创建蓝绿色磨砂图滤镜
        let darkScratchesFilter = CIFilter(name: "CIColorMatrix")!
        darkScratchesFilter.setValue(affineTransformFilter.outputImage, forKey: kCIInputImageKey)
        darkScratchesFilter.setValue(CIVector(x: 4, y: 0, z: 0, w: 0), forKey: "inputRVector")
        darkScratchesFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
        darkScratchesFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
        darkScratchesFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputAVector")
        darkScratchesFilter.setValue(CIVector(x: 0, y: 1, z: 1, w: 1), forKey: "inputBiasVector")
        // 6.用CIMinimumComponent滤镜把蓝绿色磨砂图滤镜处理成黑色磨砂图滤镜
        let minimumComponentFilter = CIFilter(name: "CIMinimumComponent")!
        minimumComponentFilter.setValue(darkScratchesFilter.outputImage, forKey: kCIInputImageKey)
        // ---------上面算是基本完成了
        // 7.最终组合在一起
        let multiplyCompositingFilter = CIFilter(name: "CIMultiplyCompositing")!
        multiplyCompositingFilter.setValue(minimumComponentFilter.outputImage, forKey: kCIInputBackgroundImageKey)
        multiplyCompositingFilter.setValue(sourceOverCompositingFilter.outputImage, forKey: kCIInputImageKey)
        // 8.最后输出
        let outputImage = multiplyCompositingFilter.outputImage!
        let cgImage = context.createCGImage(outputImage, from: outputImage.extent)
        photoImageView.image = UIImage(cgImage: cgImage!)
    }

    @IBAction func replaceBackground() {
        let cubeMap = CubeMap.createCubeMap(-100, maxHueAngle: 100)
        let data = NSData(bytesNoCopy: (cubeMap?.data)!, length: Int((cubeMap?.length)!), freeWhenDone: true)
        let colorCubeFilter = CIFilter(name: "CIColorCube")!
        
        colorCubeFilter.setValue(cubeMap?.dimension, forKey: "inputCubeDimension")
        colorCubeFilter.setValue(data, forKey: "inputCubeData")
        colorCubeFilter.setValue(CIImage(image: photoImageView.image!), forKey: kCIInputImageKey)
        var outputImage = colorCubeFilter.outputImage!
        
        let sourceOverCompositingFilter = CIFilter(name: "CISourceOverCompositing")!
        sourceOverCompositingFilter.setValue(outputImage, forKey: kCIInputImageKey)
        sourceOverCompositingFilter.setValue(CIImage(image: UIImage(named: "0e1629279e95cd5fbc3b698aed9dd1f9")!), forKey: kCIInputBackgroundImageKey)
        
        outputImage = sourceOverCompositingFilter.outputImage!
        let cgImage = context.createCGImage(outputImage, from: outputImage.extent)
        photoImageView.image = UIImage(cgImage: cgImage!)
        
    }
    
    @IBAction func shouldWatermark() {
        let inputImage = CIImage(image: originalImage)!

        let outputImage = inputImage.applyingWWDCDemoEffect()
        
        let cgImage = context.createCGImage(outputImage, from: outputImage.extent)
        photoImageView.image = UIImage(cgImage: cgImage!)
    }

    
    
 
}

private extension CIImage {
    
    
    func applyingWWDCDemoEffect(time: CGFloat = 0, scale: CGFloat = 1, shouldWatermark: Bool = true) -> CIImage {
        
        //coreimage的，没看懂
        // Demo step 1: Crop to square, animating crop position.
        let length = min(extent.width, extent.height)
        let cropOrigin = CGPoint(x: (1 + time) * (extent.width - length) / 2,
                                 y: (1 + time) * (extent.height - length) / 2)
        let cropRect = CGRect(origin: cropOrigin,
                              size: CGSize(width: length, height: length))
        let cropped = self.cropping(to: cropRect)
        
        // Demo step 2: Add vignette effect.
        let vignetted = cropped.applyingFilter("CIVignetteEffect", withInputParameters:
            [ kCIInputCenterKey: CIVector(x: cropped.extent.midX, y: cropped.extent.midY),
              kCIInputRadiusKey: length * CGFloat(M_SQRT1_2),
              ])
        
        // Demo step 3: Add line screen effect.
        let screen = vignetted.applyingFilter("CILineScreen", withInputParameters:
            [ kCIInputAngleKey : CGFloat.pi * 3/4,
              kCIInputCenterKey : CIVector(x: vignetted.extent.midX, y: vignetted.extent.midY),
              kCIInputWidthKey : 50 * scale
            ])
        let screened = screen.applyingFilter("CIMultiplyCompositing", withInputParameters: [kCIInputBackgroundImageKey: self])
        
        // Demo step 5: Add watermark if desired.
        if shouldWatermark {
            // Scale logo to rendering resolution and position it for compositing.
            let logoWidth = ContentEditingController.wwdcLogo.extent.width
            let logoScale = self.extent.width * 0.7 / logoWidth
            let scaledLogo = ContentEditingController.wwdcLogo
                .applying(CGAffineTransform(scaleX: logoScale, y: logoScale))
            let logo = scaledLogo
                .applying(CGAffineTransform(translationX: self.extent.minX + (self.extent.width - scaledLogo.extent.width) / 2, y: self.extent.minY + scaledLogo.extent.height))
            // Composite logo over the main image.
            return logo.applyingFilter("CILinearDodgeBlendMode", withInputParameters: [kCIInputBackgroundImageKey: self])
        } else {
            return screened
        }
    }
}

