//  DB6Theme.swift
//
//  Created by Eugene Yagrushkin on 2017-05-05.
//  Copyright © 2017 EYELabs. All rights reserved.
//

import Foundation
import UIKit

public class DB6Theme{
    
    static var `default`: DB6Theme?
    
    var name: String
    var parentTheme: DB6Theme? = nil
    
    fileprivate let themeDictionary: [String: Any]
    fileprivate var colorCache = [String: UIColor]()
    fileprivate var fontCache = [String: UIFont]()

    fileprivate enum defaults{
        static let color = UIColor.black
        static let font = UIFont.systemFont(ofSize: 12)
    }
    
    init(fromDictionary themeDictionary: [String: Any]) {
        name = "Default"
        self.themeDictionary = themeDictionary
    }
    
}

// helpers
fileprivate extension DB6Theme{
    
    static func colorWithHexString(hexString: String?) -> UIColor? {
        if let hexString = hexString, let hex = Int(hexString.replacingOccurrences(of: "#", with: ""), radix: 16){
            return UIColor(red: CGFloat((hex >> 16) & 0xff) / 255.0, green: CGFloat((hex >> 8) & 0xff) / 255.0, blue: CGFloat(hex & 0xff) / 255.0, alpha: 1.0)
        }
        return nil
    }
    
}

// primitives
extension DB6Theme{
    
    subscript(key: String) -> Any? {
        get {
            
            //TODO: if the first one is @, find a key with 
            var obj = themeDictionary[key]
            if obj == nil {
                obj = parentTheme?[key]
            }
            return obj
        }
    }
    
    func object(key: String) -> Any? {
        var obj = themeDictionary[key]
        if obj == nil {
            obj = parentTheme?.object(key: key)
        }
        return obj
    }
    
    func bool(key: String) -> Bool {
        guard let string = string(key: key) else{
            return false
        }
        switch string.lowercased() {
        case "true", "yes", "1":
            return true
        default:
            return false
        }
    }
    
    func string(key: String) -> String? {
        if let value = self[key] as? String{
            return value
        }
        return nil
    }
    
    func integer(key: String) -> Int {
        guard let string = string(key: key) else{
            return 0
        }
        guard let value = Int(string) else {
            return 0
        }
        return value
    }
    
    func float(key: String) -> Float {
        guard let string = string(key: key) else{
            return 0
        }
        guard let value = Float(string) else {
            return 0
        }
        return value
    }
    
    func double(key: String) -> Double {
        guard let string = string(key: key) else{
            return 0
        }
        guard let value = Double(string) else {
            return 0
        }
        return value
    }
    
}

// framework primitives
extension DB6Theme{

    func image(key: String) -> UIImage? {
        guard let imageName = string(key: key) else {
            return nil
        }
        return UIImage(named: imageName)
    }
    
    func color(key: String) -> UIColor {
        if let cachedColor = colorCache[key]{
            return cachedColor
        }

        let colorString = string(key: key)?.replacingOccurrences(of: "#", with: "")
        let color: UIColor
        if let _color = DB6Theme.colorWithHexString(hexString: colorString){
            color = _color
            colorCache[key] = color
        }else{
            color = defaults.color
        }

        return color
    }
    
    func font(key: String) -> UIFont {
        
        if let cachedFont = fontCache[key]{
            return cachedFont
        }
        
        if let fontDictionary = self[key] as? [String: Any]{
            
            guard let fontSize = fontDictionary["size"] as? CGFloat else{
                return defaults.font
            }
            
            if let fontName = fontDictionary["name"] as? String{
                if let font = UIFont(name: fontName, size: fontSize){
                    fontCache[key] = font
                    return font
                }
            }else{
                return UIFont.systemFont(ofSize: fontSize)
            }

        }
        return defaults.font
    }

    fileprivate static func font(dictionary: [String: Any]) -> UIFont? {
        
        guard let fontString = dictionary["size"] as? String, let fontSize = Float(fontString) else{
            return nil
        }
        
        if let fontName = dictionary["name"] as? String{
            if let font = UIFont(name: fontName, size: CGFloat(fontSize)){
                return font
            }
        }else{
            return UIFont.systemFont(ofSize: CGFloat(fontSize))
        }
        
        return nil
    }

}

extension DB6Theme{
    
    func update(label: UILabel, key: String){
        if let labelValue = self[key] as? [String: Any]{
            if let fontValue = labelValue["font"] as? [String: Any]{
                if let font = DB6Theme.font(dictionary: fontValue){
                    label.font = font
                }
            }
            if let colorString = labelValue["backgroundColor"] as? String, let color = DB6Theme.colorWithHexString(hexString: colorString){
                label.backgroundColor = color
            }
            if let colorString = labelValue["textColor"] as? String, let color = DB6Theme.colorWithHexString(hexString: colorString){
                label.textColor = color
            }
        }
    }
    
}


