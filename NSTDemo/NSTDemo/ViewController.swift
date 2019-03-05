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

// TODO: button disabled unless both input image and style model selections are valid
// TODO: style model selection
// TODO: nicer functions for applying style transfer
// TODO: verify accent colours
// TODO: visual niceties
// TODO: app icon
// TODO: launch screen
// TODO: save/share styled image?

enum StyleModel {
    case wave
    
    var model: MLModel {
        switch self {
            case .wave: return Wave().model
        }
    }
    
    var dimensionConstraints: (height: CGFloat, width: CGFloat)? {
        switch self {
            case .wave: return (720.0, 883.0)
        }
    }
}

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    
    private var selectedImage: UIImage! { return self.imageView.image }
    
    // model and image to use (will not be nil when accessed)
    private var model: StyleModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.contentMode = .scaleAspectFill
        
        // add a gesture recognizer to uiimageview that will trigger image picker
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageViewPressed))
        gestureRecognizer .numberOfTapsRequired = 1
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(gestureRecognizer )
    }
    
    @IBAction func transferStyleButtonPressed(_ sender: Any) {
        
        // create asynchronous but high-priority queue to style image without hanging app
        DispatchQueue.global(qos: .userInteractive).async {
            let newImage = self.styledImage(self.selectedImage)
            
            DispatchQueue.main.async {
                self.imageView.image = newImage
            }
        }
    }
    
    @objc private func imageViewPressed() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        imagePicker.delegate = self
        imagePicker.mediaTypes = [kUTTypeImage as String]
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    private func styledImage(_ image: UIImage) -> UIImage? {
        var inputImage = image
        
        // verify that model does not have input constraints or, if it does, that we can adhere to them before continuing
        if let inputConstraints = model.dimensionConstraints {
            guard let croppedImage = image.cropped(height: inputConstraints.height, width: inputConstraints.width) else {
                // TODO: present error?
                // TODO: recover
                return nil
            }
            
            inputImage = croppedImage
        }
        
        // verify that image pixel buffer conversion is successful before continuing
        guard let inputPixelBuffer = inputImage.pixelBuffer() else {
            // TODO: present error
            // TODO: recover
            return nil
        }
        
//
//        let outFeatures = try! model.prediction(from: input)
//
//        let output = outFeatures.featureValue(for: "add_37__0")!.imageBufferValue!
//
//        CVPixelBufferLockBaseAddress(output, .readOnly)
//
//        let width = CVPixelBufferGetWidth(output)
//
//        let height = CVPixelBufferGetHeight(output)
//
//        let data = CVPixelBufferGetBaseAddress(output)!
//
//        let outContext = CGContext(data: data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(output), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageByteOrderInfo.order32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)!
//
//        let outImage = outContext.makeImage()!
//
//        CVPixelBufferUnlockBaseAddress(output, .readOnly)
        
        return image
    }
    
    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info [UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = image
        } else {
            // TODO: present error?
            // TODO: recover
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
}

