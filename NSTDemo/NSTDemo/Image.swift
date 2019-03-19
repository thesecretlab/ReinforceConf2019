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
    
    func perform<T>(permission: CVPixelBufferLockFlags, action: () -> (T?)) -> T? {
        CVPixelBufferLockBaseAddress(self, permission)      // lock memory
        let output = action()                               // do the thing
        CVPixelBufferUnlockBaseAddress(self, permission)    // unlock memory
        return output                                       // return output of doing thing
    }
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
    
    func makeUIImage() -> UIImage? {
        if let cgImage = self.makeImage() {
            return UIImage(cgImage: cgImage)
        }
        
        return nil
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

extension UIImage{
    
    static var placeholder = UIImage(named: "placeholder.png")!
    
    func styled(with modelSelection: StyleModel) -> UIImage? {
        guard let inputPixelBuffer = self.pixelBuffer() else { return nil }

        let model = StyleTransferModel()
        let transformation = try? model.prediction(image: inputPixelBuffer, index: modelSelection.styleArray)
        guard let outputPixelBuffer = transformation?.stylizedImage else { return nil }
        
        let outputImage = outputPixelBuffer.perform(permission: .readOnly) {
            guard let outputContext = CGContext.createContext(for: outputPixelBuffer) else { return nil }
            return outputContext.makeUIImage()
        } as UIImage?

        return outputImage
    }
    
    func aspectFilled(to size: CGSize) -> UIImage? {
        let (width, height) = (Int(size.width), Int(size.height))
        let aspectRatio: CGFloat = self.size.width / self.size.height
        let intermediateSize: CGSize

        if aspectRatio > 0 {
            intermediateSize = CGSize(width: Int(aspectRatio * size.height), height: height)
        } else {
            intermediateSize = CGSize(width: width, height: Int(aspectRatio * size.width))
        }

        return self.resized(to: intermediateSize)?.cropped(to: size)
    }
    
    func resized(to size: CGSize) -> UIImage? {
        let newRect = CGRect(origin: CGPoint.zero, size: size)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: newRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func cropped(to size: CGSize) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        
        let widthDifference = self.size.width - size.width
        let heightDifference = self.size.height - size.height
        
        if widthDifference + heightDifference == 0 { return self }
        if min(widthDifference, heightDifference) < 0 { return nil }
        
        let newRect = CGRect(x: widthDifference / 2.0, y: heightDifference / 2.0, width: size.width, height: size.height)
        
        UIGraphicsBeginImageContextWithOptions(newRect.size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        
        context?.translateBy(x: 0.0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.draw(cgImage, in: CGRect(x:0, y:0, width: self.size.width, height: self.size.height), byTiling: false)
        context?.clip(to: [newRect])
        
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    
        return croppedImage
    }
    
    func pixelBuffer() -> CVPixelBuffer? {
        guard let image = self.cgImage else { return nil }
        let dimensions: (height: Int, width: Int) = (Int(self.size.width), Int(self.size.height))
        
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

        guard let createdPixelBuffer = pixelBuffer, status == kCVReturnSuccess else { return nil }
        
        let populatedPixelBuffer = createdPixelBuffer.perform(permission: .readAndWrite) {
            guard let graphicsContext = CGContext.createContext(for: createdPixelBuffer) else { return nil }
            graphicsContext.draw(image, in: CGRect(x: 0, y: 0, width: dimensions.width, height: dimensions.height))
            return createdPixelBuffer
        } as CVPixelBuffer?
        
        return populatedPixelBuffer
    }
}
