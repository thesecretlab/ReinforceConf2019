//
//  Image.swift
//  NSTDemo
//
//  (this file is for UIImage and related utilities
//  that are not part of the core app concept)
//
//  Created by Mars Geldard on 4/3/19.
//  Copyright © 2019 Mars and Paris. All rights reserved.
//

import UIKit
import CoreML

extension CVPixelBufferLockFlags {
    static let readAndWrite = CVPixelBufferLockFlags(rawValue: 0)
}

extension UIImage {
    
    static var placeholder = UIImage(named: "placeholder.png")!
    
    func cropped(height: CGFloat, width: CGFloat) -> UIImage? {
        
        // check new dimensions are not larger than original dimensions
        if self.size.height > height || self.size.width > width {
            return self
        }
        
        // calculate new image dimensions and offset
        let heightDifference = self.size.height - height
        let widthDifference = self.size.width - width
        let newRect = CGRect(x: widthDifference / 2.0, y: heightDifference / 2.0, width: self.size.width - widthDifference, height: self.size.height - widthDifference)
        
        // convert to cgimage and back for use of pre-existing functionality for cropping
        guard let croppedCGImage = self.cgImage?.cropping(to: newRect) else {
            print("Casting self.cgImage attribute failed during cropped(height:width:) call of UIImage: " + self.description)
            return nil
        }
        
        return UIImage(cgImage: croppedCGImage)
    }
    
    func pixelBuffer() -> CVPixelBuffer? {
        
        // verify that cgimage conversion was successful before continuing
        guard let image = self.cgImage else {
            print("Casting self.cgImage attribute failed during pixelBuffer() call of UIImage: " + self.description)
            return nil
        }
        
        // get image attributes
        let dimensions = (width: Int(self.size.width), height: Int(self.size.height))
        let attributes = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        
        // attempt creation of a pixel buffer for the given image size
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            dimensions.width,
            dimensions.height,
            kCVPixelFormatType_32BGRA,
            attributes,
            &pixelBuffer
        )
        
        // verify that pixel buffer creation was successful before continuing
        guard let createdPixelBuffer = pixelBuffer, status == kCVReturnSuccess else {
            print("CVPixelBufferCreate failed during pixelBuffer() call of UIImage: " + self.description)
            return nil
        }
        
        // attempt creation of a core graphics context with the given image attributes
        CVPixelBufferLockBaseAddress(createdPixelBuffer, .readAndWrite)
        let pixelData = CVPixelBufferGetBaseAddress(createdPixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)
        let coreGraphicsContext = CGContext(
            data: pixelData,
            width: dimensions.width,
            height: dimensions.height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(createdPixelBuffer),
            space: rgbColorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )
        
        // verify that core graphics context creation was successful before continuing
        guard let graphicsContext = coreGraphicsContext else {
            print("CGContext initialisation failed during pixelBuffer() call of UIImage: " + self.description)
            CVPixelBufferUnlockBaseAddress(createdPixelBuffer, .readAndWrite)
            return nil
        }
        
        // draw image into created core graphics pixel buffer
        graphicsContext.draw(image, in: CGRect(x: 0, y: 0, width: dimensions.width, height: dimensions.height))
        CVPixelBufferUnlockBaseAddress(createdPixelBuffer, .readAndWrite)
        
        return createdPixelBuffer
    }
}
