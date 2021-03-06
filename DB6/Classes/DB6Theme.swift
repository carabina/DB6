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
            let obj = themeDictionary[key]

            if let stringValue = obj as? String, stringValue.hasPrefix("@"){
                return self[stringValue.replacingOccurrences(of: "@", with: "")]
            }
            return obj
        }
    }
    
    func object(key: String) -> Any? {
        let obj = themeDictionary[key]
        return obj
    }
    
    func bool(key: String) -> Bool {
        
        guard let value = self[key] as? Bool else{
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
        
        return value
    }
    
    func string(key: String) -> String? {
        if let value = self[key] as? String{
            return value
        }
        return nil
    }
    
    func integer(key: String) -> Int {
        guard let value = self[key] as? Int else{
            if let string = string(key: key), let value = Int(string){
                return value
            }
            return 0
        }
        return value
    }
    
    func float(key: String) -> Float {
        guard let value = self[key] as? Float else{
            if let string = string(key: key), let value = Float(string){
                return value
            }
            return 0
        }
        return value
    }
    
    func double(key: String) -> Double {
        guard let value = self[key] as? Double else{
            if let string = string(key: key), let value = Double(string){
                return value
            }
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
                let font = UIFont.systemFont(ofSize: fontSize)
                fontCache[key] = font
                return font
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
            let fontStyle = dictionary["style"] as? String
            
            let font: UIFont
            switch fontStyle {
            case .some("bold"):
                font = UIFont.boldSystemFont(ofSize: CGFloat(fontSize))
            case .some("italic"):
                font = UIFont.italicSystemFont(ofSize: CGFloat(fontSize))
            default:
                font = UIFont.systemFont(ofSize: CGFloat(fontSize))
            }
            
            return font
        }
        
        return nil
    }

}

extension DB6Theme{
    
    fileprivate func kern(button: UIButton, kerningValue:CGFloat) {
        
        let options: [UIControlState] = [.normal, .selected, .highlighted]
        for state in options{
            if let color = button.titleColor(for: state), let text = button.title(for: state), let font = button.titleLabel?.font{
                let attributedText =  NSAttributedString(string: text, attributes: [NSKernAttributeName:kerningValue, NSFontAttributeName:font, NSForegroundColorAttributeName:color])
                button.setAttributedTitle(attributedText, for: state)
            }
            
        }
    }

    fileprivate func kern(label: UILabel, kerningValue:CGFloat) {
        if let text = label.text{
            label.attributedText =  NSAttributedString(string: text, attributes: [NSKernAttributeName:kerningValue, NSFontAttributeName:font, NSForegroundColorAttributeName:label.textColor])
        }
    }

}

extension DB6Theme{
    
    fileprivate subscript(value: Any?) -> Any? {
        get {
            if let stringValue = value as? String, stringValue.hasPrefix("@"){
                return self[stringValue.replacingOccurrences(of: "@", with: "")]
            }
            return value
        }
    }

    func apply(view: Any, key: String){
        switch view {
        case let button as UIButton:
            self.update(button: button, key: key)
            
        case let label as UILabel:
            self.update(label: label, key: key)

        case let view as UIView:
            self.update(view: view, key: key)

        default:
            break
        }
    }
    
    func update(view: UIView, key: String){
        
        let styles = key.components(separatedBy: " ")
        for style in styles{
            if let value = self[style] as? [String: Any]{
                if let colorString = self[value["backgroundColor"]] as? String, let color = DB6Theme.colorWithHexString(hexString: colorString){
                    view.backgroundColor = color
                }
                if let string = self[value["borderWidth"]] as? String, let value = Float(string){
                    view.layer.borderWidth = CGFloat(value)
                }
                if let string = self[value["cornerRadius"]] as? String, let value = Float(string){
                    view.layer.cornerRadius = CGFloat(value)
                    view.clipsToBounds = true
                }
                if let string = self[value["borderColor"]] as? String, let color = DB6Theme.colorWithHexString(hexString: string){
                    view.layer.borderColor = color.cgColor
                }
            }
        }
    }
    
    func update(label view: UILabel, key: String){
        
        self.update(view: view, key: key)
        let styles = key.components(separatedBy: " ")
        for style in styles{
            if let value = self[style] as? [String: Any]{
                if let fontValue = value["font"] as? [String: Any]{
                    if let font = DB6Theme.font(dictionary: fontValue){
                        view.font = font
                    }
                }
                if let colorString = self[value["textColor"]] as? String, let color = DB6Theme.colorWithHexString(hexString: colorString){
                    view.textColor = color
                }
                if let kern = self[value["kern"]] as? Float{
                    self.kern(label: view, kerningValue: CGFloat(kern))
                }
            }
        }
    }

    func update(button view: UIButton, key: String){
        
        self.update(view: view, key: key)
        let styles = key.components(separatedBy: " ")
        for style in styles{
            if let value = self[style] as? [String: Any]{
                if let colorString = self[value["textColor"]] as? String, let color = DB6Theme.colorWithHexString(hexString: colorString){
                    view.setTitleColor(color, for: .normal)
                }
                if let fontValue = value["font"] as? [String: Any]{
                    if let font = DB6Theme.font(dictionary: fontValue){
                        view.titleLabel?.font = font
                    }
                }
                if let kern = self[value["kern"]] as? Float{
                    self.kern(button: view, kerningValue: CGFloat(kern))
                }
            }
        }
    }

}


