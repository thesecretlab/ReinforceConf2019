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

// MARK: CVPixelBuffer Extensions

extension CVPixelBufferLockFlags {
    static let readAndWrite = CVPixelBufferLockFlags(rawValue: 0)
}

extension CVPixelBuffer {
    var width: Int { return CVPixelBufferGetWidth(self) }
    var height: Int { return CVPixelBufferGetHeight(self) }
    var bytesPerRow: Int { return CVPixelBufferGetBytesPerRow(self) }
    var baseAddress: UnsafeMutableRawPointer? { return CVPixelBufferGetBaseAddress(self) }
}

// MARK: CGContext Extensions

extension CGColorSpace {
    static var deviceRGB: CGColorSpace { return CGColorSpaceCreateDeviceRGB() }
}

extension CGContext {
    static func createContext(for pixelBuffer: CVPixelBuffer) -> CGContext? {
        return CGContext(
            data: pixelBuffer.baseAddress,
            width: pixelBuffer.width,
            height: pixelBuffer.height,
            bitsPerComponent: 8,
            bytesPerRow: pixelBuffer.bytesPerRow,
            space: CGColorSpace.deviceRGB,
            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue
        )
    }
}

// MARK: UIColor Extensions

extension UIColor {
    static let systemBlue = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
}

// MARK: UIButton/UIControl  Extensions

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
    func enable() { self.isEnabled = true }
    func disable() { self.isEnabled = false }
}

// MARK: UIImage Extensions

extension UIImage {
    
    static var placeholder = UIImage(named: "placeholder.png")!
    
    func styled(with modelSelection: StyleModel) -> UIImage? {
        let ciImage: CIImage = CIImage(cgImage: self.cgImage!)
        let flippedImage = ciImage.transformed(by: CGAffineTransform(scaleX: -1, y: 1))
        let outputImage = UIImage(ciImage: flippedImage)
        return outputImage
        
//        // verify that image pixel buffer conversion is successful before continuing
//        guard let inputPixelBuffer = self.pixelBuffer() else {
//            // TODO: error
//            // TODO: recover
//            return nil
//        }
//
//        // TODO: fix
//        let input = StyleTransferInputFile(input: inputPixelBuffer)
//        let outFeatures = try! modelSelection.model.prediction(from: input)
//        let output = outFeatures.featureValue(for: "add_37__0")!.imageBufferValue!
//        let outputPixelBuffer = inputPixelBuffer
//
//        CVPixelBufferLockBaseAddress(outputPixelBuffer, .readOnly)
//        guard let outputContext = CGContext.createContext(for: outputPixelBuffer) else {
//            print("CGContext initialisation failed during styled(with:) call of UIImage: " + self.description)
//            CVPixelBufferUnlockBaseAddress(outputPixelBuffer, .readOnly)
//            return nil
//        }
//        let outputImage = outputContext.makeImage()!
//        CVPixelBufferUnlockBaseAddress(outputPixelBuffer, .readOnly)
//
//        return UIImage(cgImage: outputImage)
    }
    
    func pixelBuffer() -> CVPixelBuffer? {
        let dimensions: (height: Int, width: Int) = (Int(self.size.width), Int(self.size.height))
        
        // verify that cgimage conversion was successful before continuing
        guard let image = self.cgImage else {
            print("Casting self.cgImage attribute failed during pixelBuffer() call of UIImage: " + self.description)
            return nil
        }
        
        // attempt creation of a pixel buffer for the given image size
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            dimensions.width,
            dimensions.height,
            kCVPixelFormatType_32BGRA,
            [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
             kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary,
            &pixelBuffer
        )
        
        // verify that image pixel buffer creation was successful before continuing
        guard let createdPixelBuffer = pixelBuffer, status == kCVReturnSuccess else {
            print("CVPixelBufferCreate failed during pixelBuffer() call of UIImage: " + self.description)
            return nil
        }
        
        CVPixelBufferLockBaseAddress(createdPixelBuffer, .readAndWrite)
        guard let graphicsContext = CGContext.createContext(for: createdPixelBuffer) else {
            print("CGContext initialisation failed during pixelBuffer() call of UIImage: " + self.description)
            CVPixelBufferUnlockBaseAddress(createdPixelBuffer, .readAndWrite)
            return nil
        }
        graphicsContext.draw(image, in: CGRect(x: 0, y: 0, width: dimensions.width, height: dimensions.height))
        CVPixelBufferUnlockBaseAddress(createdPixelBuffer, .readAndWrite)
        
        return createdPixelBuffer
    }
}
