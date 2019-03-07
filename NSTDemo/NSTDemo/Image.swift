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

extension UIColor {
    static let systemBlue = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
}

extension UIButton {
    func enable() {
        self.isEnabled = true
        self.backgroundColor = UIColor.systemBlue
    }
    
    func disable() {
        self.isEnabled = false
        self.backgroundColor = UIColor.lightGray
    }
}

extension UIBarButtonItem {
    func enable() {
        self.isEnabled = true
    }
    
    func disable() {
        self.isEnabled = false
    }
}

extension UIImage {
    
    static var placeholder = UIImage(named: "placeholder.png")!
    
    func styled(with modelSelection: StyleModel) -> UIImage? {
        let ciImage: CIImage = CIImage(cgImage: self.cgImage!)
        let flippedImage = ciImage.transformed(by: CGAffineTransform(scaleX: -1, y: 1))
        let outputImage = UIImage(ciImage: flippedImage)
        return outputImage
//        // verify that image pixel buffer conversion is successful before continuing
//        guard let inputPixelBuffer = self.pixelBuffer() else {
//            completion(nil)
//            return
//        }
//
//        // TODO: fix
//        let input = StyleTransferInputFile(input: inputPixelBuffer)
//        let outFeatures = try! modelSelection.model.prediction(from: input)
//        let output = outFeatures.featureValue(for: "add_37__0")!.imageBufferValue!
//
//        CVPixelBufferLockBaseAddress(output, .readOnly)
//        let width = CVPixelBufferGetWidth(output)
//        let height = CVPixelBufferGetHeight(output)
//        let data = CVPixelBufferGetBaseAddress(output)!
//        let outContext = CGContext(data: data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(output), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageByteOrderInfo.order32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)!
//        let outputImage = outContext.makeImage()!
//        CVPixelBufferUnlockBaseAddress(output, .readOnly)
//
//        completion(UIImage(cgImage: outputImage))
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
