//
//  PhotoFilterCollectionViewCell.swift
//  Core Image Explorer
//
//  Created by Warren Moore on 1/12/15.
//  Copyright (c) 2015 objc.io. All rights reserved.
//

import UIKit

let kCellWidth: CGFloat = 90
let kLabelHeight: CGFloat = 20

class PhotoFilterCollectionViewCell: UICollectionViewCell {
    var filterNameLabel: UILabel!
    var filteredImageView: UIImageView!
    
    var context: CIContext! {
        return CIContext(options: nil)
    }
    
    var inputImage: UIImage! {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var filter: CIFilter! {
        didSet {
            let inputCIImage = CIImage(image: inputImage)
            filter.setValue(inputCIImage, forKey: kCIInputImageKey)
            if let outputImage = filter.outputImage {
                let cgImage = context.createCGImage(outputImage, from: outputImage.extent)
                filteredImageView.image = UIImage(cgImage: cgImage!)
            }
        }
    }
    


    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        addSubviews()
    }

    //override func intrinsicContentSize() -> CGSize {
    //    return CGSizeMake(kCellWidth, kCellWidth + kLabelHeight);
    //}

    func addSubviews() {
        if (filteredImageView == nil) {
            let rect: CGRect = CGRect.init(x: 0, y: 0, width: kCellWidth, height: kCellWidth)
            filteredImageView = UIImageView.init(frame: rect)
            filteredImageView.layer.borderColor = tintColor.cgColor
            contentView.addSubview(filteredImageView)
        }

        if (filterNameLabel == nil) {
            filterNameLabel = UILabel.init(frame: CGRect.init(x: 0, y: kCellWidth, width: kCellWidth, height: kLabelHeight))
            filterNameLabel.textAlignment = .center
            filterNameLabel.textColor = UIColor.black
            filterNameLabel.highlightedTextColor = tintColor
            filterNameLabel.font = UIFont.systemFont(ofSize: 14)
            contentView.addSubview(filterNameLabel)
        }
    }

    override var isSelected: Bool {
        didSet {
            filteredImageView.layer.borderWidth = isSelected ? 2 : 0
        }
    }
}
