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
    
        for descriptor in CIFilter.filterNames(inCategory: kCICategoryDistortionEffect) {
            filters.append(CIFilter(name: descriptor)!)
        }
        
        print("kCICategoryDistortionEffect----",CIFilter.filterNames(inCategory: kCICategoryDistortionEffect))   //扭曲
        print("kCICategoryGeometryAdjustment----",CIFilter.filterNames(inCategory: kCICategoryGeometryAdjustment))  //几何
        print("kCICategoryCompositeOperation----",CIFilter.filterNames(inCategory: kCICategoryCompositeOperation))  //复合操作
        print("kCICategoryHalftoneEffect----",CIFilter.filterNames(inCategory: kCICategoryHalftoneEffect))    //半色调
        print("kCICategoryColorAdjustment----",CIFilter.filterNames(inCategory: kCICategoryColorAdjustment)) //颜色调整
        print("kCICategoryColorEffect----",CIFilter.filterNames(inCategory: kCICategoryColorEffect))    //色彩效果
        print("kCICategoryTransition----",CIFilter.filterNames(inCategory: kCICategoryTransition))   //过渡
        print("kCICategoryTileEffect----",CIFilter.filterNames(inCategory: kCICategoryTileEffect))    //瓷砖效果
        print("kCICategoryGenerator----",CIFilter.filterNames(inCategory: kCICategoryGenerator))  //发生器
        print("kCICategoryReduction----",CIFilter.filterNames(inCategory: kCICategoryReduction))  //减少
        print("kCICategoryGradient----",CIFilter.filterNames(inCategory: kCICategoryGradient))  //梯度
        print("kCICategoryStylize----",CIFilter.filterNames(inCategory: kCICategoryStylize))  //风格化
        print("kCICategorySharpen----",CIFilter.filterNames(inCategory: kCICategorySharpen))  //磨
        print("kCICategoryBlur----",CIFilter.filterNames(inCategory: kCICategoryBlur))     //模糊
        print("kCICategoryVideo----",CIFilter.filterNames(inCategory: kCICategoryVideo)) //动态影像
        print("kCICategoryStillImage----",CIFilter.filterNames(inCategory: kCICategoryStillImage))  //静止图像
        print("kCICategoryInterlaced----",CIFilter.filterNames(inCategory: kCICategoryInterlaced))  //交错
        print("kCICategoryNonSquarePixels----",CIFilter.filterNames(inCategory: kCICategoryNonSquarePixels))  //非方形像素
        print("kCICategoryHighDynamicRange----",CIFilter.filterNames(inCategory: kCICategoryHighDynamicRange))  //高动态范围
        print("kCICategoryBuiltIn----",CIFilter.filterNames(inCategory: kCICategoryBuiltIn))  //固有
        print("kCICategoryFilterGenerator----",CIFilter.filterNames(inCategory: kCICategoryFilterGenerator)) //过滤发生器
        
    }

    // MARK: - Collection View
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoFilterCell", for: indexPath as IndexPath) as! PhotoFilterCollectionViewCell
        
        cell.inputImage = originalImage
        cell.filter = filters[indexPath.item]
        cell.filterNameLabel.text = CIFilter.localizedName(forFilterName: cell.filter.name)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let inputImage = CIImage(image: originalImage)!

        let filter: CIFilter = filters[indexPath.item]
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        let outputImage =  filter.outputImage!
        let cgImage = context.createCGImage(outputImage, from: outputImage.extent)
        if  cgImage != nil {
            self.photoImageView.image = UIImage(cgImage: cgImage!)

        }
        
    
    }



}

