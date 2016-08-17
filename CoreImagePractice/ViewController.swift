//
//  ViewController.swift
//  CoreImagePractice
//
//  Created by zhangke on 16/8/9.
//  Copyright © 2016年 zhangke. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet var photoImageView: UIImageView!
    @IBOutlet weak var photoFilterCollectionView: UICollectionView!
    
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
    
        for descriptor in filterDescriptors {
            filters.append(CIFilter(name: descriptor.filterName)!)
        }
    
    }

    // MARK: - Collection View
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filterDescriptors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoFilterCell", for: indexPath as IndexPath) as! PhotoFilterCollectionViewCell
        cell.inputImage = photoImageView.image
        cell.filter = filters[indexPath.item]
        cell.filterNameLabel.text = filterDescriptors[indexPath.item].filterDisplayName
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let inputImage = CIImage(image: originalImage)
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        let outputImage =  filter.outputImage!
        let cgImage = context.createCGImage(outputImage, fromRect: outputImage.extent)
        self.imageView.image = UIImage(CGImage: cgImage)
    
    }



}

