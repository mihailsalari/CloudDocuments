//
//  Functional Programming.swift
//  CloudDocuments
//
//  Created by Mihail Salari on 12/29/16.
//  Copyright © 2016 Mihail Salari. All rights reserved.
//

import UIKit
import ImageIO

// MARK: - Resize Image

import ImageIO

/// Resize directly from data
func resizeData(_ data: Data, withSize size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
    if let imageSource = CGImageSourceCreateWithData(data as CFData, nil) {
        let options: [NSString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height),
            kCGImageSourceCreateThumbnailFromImageAlways: true
        ]
        
        if let otherImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary?).flatMap({ UIImage(cgImage: $0) }) {
            if let cgImageFromImage = otherImage.cgImage {
                
                /// Rotate
                return UIImage(cgImage: cgImageFromImage, scale: 1.0, orientation: .right)
            }
        }
    }
    
    return nil
}
