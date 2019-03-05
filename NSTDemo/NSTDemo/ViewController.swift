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

class ViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var transferStyleButton: UIButton!
    private var modelSelection: StyleModel!
    private var imageSelection: UIImage!
    
    @IBAction func selectButtonPressed(_ sender: Any) {
        summonImagePicker()
    }
    
    @IBAction func shareButtonPressed(_ sender: Any) {
        summonShareSheet()
    }
    
    @IBAction func transferStyleButtonPressed(_ sender: Any) {
        performStyleTransfer()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.contentMode = .scaleAspectFill
        
        // TODO: remove
        modelSelection = .wave
        
        // add a gesture recognizer to uiimageview that will trigger image picker
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(summonImagePicker))
        gestureRecognizer.numberOfTapsRequired = 1
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(gestureRecognizer )
    }
    
    @objc private func summonImagePicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        imagePicker.mediaTypes = [kUTTypeImage as String]
        
        present(imagePicker, animated: true)
    }
    
    private func summonShareSheet() {
        let shareSheet = UIActivityViewController(activityItems: [imageSelection as Any], applicationActivities: nil)
        present(shareSheet, animated: true)
    }
    
    private func performStyleTransfer() {
        activityIndicator.startAnimating()
        
        // create asynchronous but high-priority queue to style image without hanging app
        DispatchQueue.global(qos: .userInteractive).async {
            let newImage = self.styledImage(self.imageSelection)
            
            DispatchQueue.main.async {
                self.imageView.image = newImage
                self.activityIndicator.stopAnimating()
                self.shareButton.isEnabled = true
            }
        }
    }
    
    private func styledImage(_ image: UIImage) -> UIImage? {
        var inputImage = image
        
        // verify that model does not have input constraints or, if it does, that we can adhere to them before continuing
        if let inputConstraints = modelSelection.dimensionConstraints {
            guard let croppedImage = image.cropped(height: inputConstraints.height, width: inputConstraints.width) else {
                // TODO: present error?
                // TODO: recover
                return nil
            }
            
            print("Image cropped to \(inputConstraints.height) * \(inputConstraints.width) now sized: \(croppedImage.size.height) * \(croppedImage.size.width)\n\n")
            
            inputImage = croppedImage
        }
        
        // verify that image pixel buffer conversion is successful before continuing
        guard let inputPixelBuffer = inputImage.pixelBuffer() else {
            // TODO: present error
            // TODO: recover
            return nil
        }
        

        // TODO: fix
        print("Cropped image size: \(inputImage.size.height) * \(inputImage.size.width)\n\n")
        let input = StyleTransferInputFile(input: inputPixelBuffer)
        let outFeatures = try! modelSelection.model.prediction(from: input)
        let output = outFeatures.featureValue(for: "add_37__0")!.imageBufferValue!

        CVPixelBufferLockBaseAddress(output, .readOnly)
        let width = CVPixelBufferGetWidth(output)
        let height = CVPixelBufferGetHeight(output)
        let data = CVPixelBufferGetBaseAddress(output)!
        let outContext = CGContext(data: data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(output), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageByteOrderInfo.order32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)!
        let outputImage = outContext.makeImage()!
        CVPixelBufferUnlockBaseAddress(output, .readOnly)
        
        return UIImage(cgImage: outputImage)
    }
}

extension ViewController: UIImagePickerControllerDelegate {
    
    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        self.shareButton.isEnabled = false
        if let image = info [UIImagePickerController.InfoKey.originalImage] as? UIImage {
            if let inputConstraints = modelSelection.dimensionConstraints {
                guard let croppedImage = image.cropped(height: inputConstraints.height, width: inputConstraints.width) else {
                    // TODO: present error?
                    // TODO: recover
                    return
                }
                
                imageSelection = croppedImage
                imageView.image = imageSelection ?? UIImage.placeholder
            }
            
            // TODO: fix
            // imageSelection = image
        } else {
            // TODO: present error?
            // TODO: recover
        }
        
        picker.dismiss(animated: true)
    }
}
