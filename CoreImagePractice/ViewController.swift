//
//  ViewController.swift
//  CoreImagePractice
//
//  Created by zhangke on 16/8/9.
//  Copyright © 2016年 zhangke. All rights reserved.
//

import UIKit
import CoreImage

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet var photoImageView: UIImageView!
    @IBOutlet weak var photoFilterCollectionView: UICollectionView!
    
    var originalImage: UIImage {
        return UIImage(named: "f224b1e033f646fedc03bd32bae00c87")!
    }
    var context: CIContext! {
        return CIContext(options: nil)
    }
    var filters = [CIFilter]()

    let filterDescriptors: [(filterName: String, filterDisplayName: String)] = [
        ("CIColorControls", "原图"),
        ("CIPhotoEffectMono", "单色"),
        ("CIPhotoEffectTonal", "色调"),
        ("CIPhotoEffectNoir", "黑白"),
        ("CIPhotoEffectFade", "褪色"),
        ("CIPhotoEffectChrome", "铬黄"),
        ("CIPhotoEffectProcess", "冲印"),
        ("CIPhotoEffectTransfer", "岁月"),
        ("CIPhotoEffectInstant", "怀旧"),
        ]

    override func viewDidLoad() {
        super.viewDidLoad()
    
        for descriptor in CIFilter.filterNames(inCategory: kCICategoryColorEffect) {
            filters.append(CIFilter(name: descriptor)!)
        }
        
        print("kCICategoryDistortionEffect----",CIFilter.filterNames(inCategory: kCICategoryDistortionEffect))
        print("kCICategoryGeometryAdjustment----",CIFilter.filterNames(inCategory: kCICategoryGeometryAdjustment))
        print("kCICategoryCompositeOperation----",CIFilter.filterNames(inCategory: kCICategoryCompositeOperation))
        print("kCICategoryHalftoneEffect----",CIFilter.filterNames(inCategory: kCICategoryHalftoneEffect))
        print("kCICategoryColorAdjustment----",CIFilter.filterNames(inCategory: kCICategoryColorAdjustment))
        print("kCICategoryColorEffect----",CIFilter.filterNames(inCategory: kCICategoryColorEffect))
        print("kCICategoryTransition----",CIFilter.filterNames(inCategory: kCICategoryTransition))
        print("kCICategoryTileEffect----",CIFilter.filterNames(inCategory: kCICategoryTileEffect))
        print("kCICategoryGenerator----",CIFilter.filterNames(inCategory: kCICategoryGenerator))
        print("kCICategoryReduction----",CIFilter.filterNames(inCategory: kCICategoryReduction))
        print("kCICategoryGradient----",CIFilter.filterNames(inCategory: kCICategoryGradient))
        print("kCICategoryStylize----",CIFilter.filterNames(inCategory: kCICategoryStylize))
        print("kCICategorySharpen----",CIFilter.filterNames(inCategory: kCICategorySharpen))
        print("kCICategoryBlur----",CIFilter.filterNames(inCategory: kCICategoryBlur))
        print("kCICategoryVideo----",CIFilter.filterNames(inCategory: kCICategoryVideo))
        print("kCICategoryStillImage----",CIFilter.filterNames(inCategory: kCICategoryStillImage))
        print("kCICategoryInterlaced----",CIFilter.filterNames(inCategory: kCICategoryInterlaced))
        print("kCICategoryNonSquarePixels----",CIFilter.filterNames(inCategory: kCICategoryNonSquarePixels))
        print("kCICategoryHighDynamicRange----",CIFilter.filterNames(inCategory: kCICategoryHighDynamicRange))
        print("kCICategoryBuiltIn----",CIFilter.filterNames(inCategory: kCICategoryBuiltIn))
        print("kCICategoryFilterGenerator----",CIFilter.filterNames(inCategory: kCICategoryFilterGenerator))

    }

    // MARK: - Collection View
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoFilterCell", for: indexPath as IndexPath) as! PhotoFilterCollectionViewCell
        
        cell.inputImage = originalImage
        cell.filter = filters[indexPath.item]
        cell.filterNameLabel.text = filters[indexPath.item].name
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let inputImage = CIImage(image: originalImage)!

        let filter = filters[indexPath.item]

        filter.setValue(inputImage, forKey: kCIInputImageKey)
        let outputImage =  filter.outputImage!
        let attributes = filter.attributes
        let cgImage = context.createCGImage(outputImage, from: outputImage.extent)
        self.photoImageView.image = UIImage(cgImage: cgImage!)
    
    }



}

