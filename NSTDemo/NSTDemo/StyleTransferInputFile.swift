//
//  StyleTransferInputFile.swift
//  NSTDemo
//
//  Created by Paris BA on 4/3/19.
//  Copyright © 2019 Mars and Paris. All rights reserved.
//

import CoreML

internal class StyleTransferInputFile : MLFeatureProvider {
    
    internal var input: CVPixelBuffer
    
    internal var featureNames: Set<String> {
        get {
            return ["img_placeholder__0"]
        }
    }
    
    internal func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "img_placeholder__0") {
            return MLFeatureValue(pixelBuffer: input)
        }
        return nil
    }
    
    internal init(input: CVPixelBuffer) {
        self.input = input
    }
}
