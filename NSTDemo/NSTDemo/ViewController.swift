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

// TODO: nicer functions for applying style transfer
// TODO: import image crop/resize to MLModel dimensions
// TODO: crop output to 600 * 600
// TODO: visual niceties
// TODO: save/share styled image?

enum StyleModel: String, CaseIterable {
    case wave = "The Great Wave"
    case night = "Starry Night"
    case scream = "The Scream"
    case starfleet = "Starfleet"
    case jupiter = "The Surface of Jupiter"
    
    static var constraints: (width: CGFloat, height: CGFloat) {
        return (800, 600)
    }
    
    var styleArray: MLMultiArray {
        guard let styleArray = try? MLMultiArray(shape: [1] as [NSNumber], dataType: MLMultiArrayDataType.double) else {
            fatalError("Could not initialise MLMultiArray for MLModel options.")
        }
        
        styleArray[0] = 1.0
        return styleArray
    }
    
    var name: String { return self.rawValue }
    static func `case`(for index: Int) -> StyleModel { return StyleModel.allCases[index] }
}

class ViewController: UIViewController, UINavigationControllerDelegate, UIPickerViewDelegate {
    
    // MARK: Outlets
    
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var modelSelector: UIPickerView!
    @IBOutlet weak var transferStyleButton: UIButton!
    
    // MARK: Actions
    
    @IBAction func selectButtonPressed(_ sender: Any) { summonImagePicker() }
    @IBAction func shareButtonPressed(_ sender: Any) {summonShareSheet() }
    @IBAction func transferStyleButtonPressed(_ sender: Any) { performStyleTransfer() }

    private var inputImage: UIImage?
    private var outputImage: UIImage?
    private var modelSelection: StyleModel {
        let selectedModelIndex = modelSelector.selectedRow(inComponent: 0)
        return StyleModel.case(for: selectedModelIndex)
    }
    
    // MARK: View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        modelSelector.delegate = self
        modelSelector.dataSource = self
        imageView.contentMode = .scaleAspectFill
    
        refresh()
    }
    
    private func refresh() {
        switch (inputImage == nil, outputImage == nil) {
            case (false, false): imageView.image = outputImage
                transferStyleButton.disable()
                shareButton.enable()
            
            case (false, true): imageView.image = inputImage
                transferStyleButton.enable()
                shareButton.disable()
            
            default: imageView.image = UIImage.placeholder
                transferStyleButton.disable()
                shareButton.disable()
        }
    }
    
    // MARK: Supplementary View Functions
    
    @objc private func summonImagePicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [kUTTypeImage as String]
        present(imagePicker, animated: true)
    }
    
    private func summonShareSheet() {
        guard let outputImage = outputImage else {
            summonAlertView()
            return
        }
        
        let shareSheet = UIActivityViewController(activityItems: [outputImage as Any], applicationActivities: nil)
        present(shareSheet, animated: true)
    }
    
    private func summonAlertView(message: String? = nil) {
        let alertController = UIAlertController(
            title: "Error",
            message: message ?? "Action could not be completed.",
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }
    
    // MARK: Functionality
    
    private func performStyleTransfer() {
        guard let styledImage = inputImage?.styled(with: modelSelection) else {
            summonAlertView()
            return
        }
        
        outputImage = styledImage
        refresh()
    }
}

extension ViewController: UIImagePickerControllerDelegate {
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let rawImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        inputImage = rawImage?.aspectCropped(to: modelSelection.constraints)
        outputImage = nil
        
        picker.dismiss(animated: true)
        refresh()
    }
}

extension ViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return StyleModel.allCases.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return StyleModel.case(for: row).name
    }
}
