//
//  StyleModel.swift
//  NSTDemo
//
//  Created by Mars Geldard on 4/3/19.
//  Copyright © 2019 Mars and Paris. All rights reserved.
//

import UIKit
import CoreML

enum StyleModel: String, CaseIterable {
    // List models (named whatever you like) and their names to display in the app
    // These must be in the order they were input into training (likely alphabetical in filename)
    case jupiter = "The Surface of Jupiter"
    case scream = "The Scream"
    case night = "Starry Night"
    case starfleet = "Starfleet"
    case wave = "The Great Wave"
    case geometric = "Geometric"
    
    var model: StyleTransferModel { return StyleTransferModel() } // Rename this to your own .mlmodel file name
    var constraints: CGSize { return CGSize(width: 800, height: 800) } // Change if your own model has different constraints
    static var styles: [StyleModel] { return self.allCases } // Make this a literal to enable only certain models
    
    init(index: Int) { self = StyleModel.styles[index] }
    var name: String { return self.rawValue }
    var styleIndex: Int { return StyleModel.styles.firstIndex(of: self)! }
    var styleArray: MLMultiArray { return MLMultiArray(size: StyleModel.styles.count, selecting: self.styleIndex) }
}
