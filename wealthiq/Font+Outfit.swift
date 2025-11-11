//
//  Font+Outfit.swift
//  wealthiq
//
//  Created by Brandon Bevans on 11/11/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum OutfitFontWeight: String {
    case regular = "Regular"
    case medium = "Medium"
    case semiBold = "SemiBold"
    
#if canImport(UIKit)
    var systemWeight: UIFont.Weight {
        switch self {
        case .regular:
            return .regular
        case .medium:
            return .medium
        case .semiBold:
            return .semibold
        }
    }
#endif
    
    var fontWeight: Font.Weight {
        switch self {
        case .regular:
            return .regular
        case .medium:
            return .medium
        case .semiBold:
            return .semibold
        }
    }
}

extension Font {
    static func outfit(_ size: CGFloat, weight: OutfitFontWeight = .regular) -> Font {
#if canImport(UIKit)
        let fontName = "Outfit-\(weight.rawValue)"
        if UIFont(name: fontName, size: size) != nil {
            return Font.custom(fontName, size: size)
        } else {
            return .system(size: size, weight: weight.fontWeight)
        }
#else
        return .system(size: size, weight: weight.fontWeight)
#endif
    }
}


