//
//  ViewController.swift
//  NSTDemo
//
//  Created by Paris BA on 4/3/19.
//  Copyright © 2019 Mars and Paris. All rights reserved.
//

import UIKit
import MobileCoreServices
import Photos
import CoreML

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    private let model = wave().model

    private var inputImage: UIImage?
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func pickPhoto(_ sender: Any) {
        
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        
        imagePicker.delegate = self
        
        imagePicker.allowsEditing = true
        
        imagePicker.mediaTypes = [kUTTypeImage as String]
    
        present(imagePicker, animated: true, completion: nil)
        
        print("In the photo picker.")
    }
    
    @IBAction func doTheThingTouched(_ sender: Any) {
        
        let image = inputImage?.cgImage
        
        DispatchQueue.global(qos: .userInteractive).async {
            let styled = self.styleImage(cgImage: image!, model: self.model)
            
            DispatchQueue.main.async {
                self.imageView.image = UIImage(cgImage: styled)
            }
        }
    }
    
    private func styleImage(cgImage: CGImage, model: MLModel) -> CGImage {
        
        let input = StyleTransferInputFile(input: pixelBuffer(cgImage: cgImage, width: 883, height: 720))
        
        let outFeatures = try! model.prediction(from: input)
        
        let output = outFeatures.featureValue(for: "add_37__0")!.imageBufferValue!
        
        CVPixelBufferLockBaseAddress(output, .readOnly)
        
        let width = CVPixelBufferGetWidth(output)
        
        let height = CVPixelBufferGetHeight(output)
        
        let data = CVPixelBufferGetBaseAddress(output)!
        
        let outContext = CGContext(data: data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(output), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageByteOrderInfo.order32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)!
        
        let outImage = outContext.makeImage()!
        
        CVPixelBufferUnlockBaseAddress(output, .readOnly)
        
        return outImage
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info [UIImagePickerController.InfoKey.editedImage] as? UIImage {
            inputImage = image
            imageView.image = image
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    private func pixelBuffer(cgImage: CGImage, width: Int, height: Int) -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer? = nil
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA , nil, &pixelBuffer)
        if status != kCVReturnSuccess {
            fatalError("Cannot create pixel buffer for image")
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags.init(rawValue: 0))
        let data = CVPixelBufferGetBaseAddress(pixelBuffer!)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)
        let context = CGContext(data: data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: bitmapInfo.rawValue)
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer!
    }
}

