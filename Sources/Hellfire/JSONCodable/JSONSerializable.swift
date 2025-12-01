//
//  JSONSerializable.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

//MARK: - JSONSerializable protocol Definition

/// A protocol that extends `Codable` with convenient JSON serialization and deserialization methods.
///
/// `JSONSerializable` provides a streamlined interface for encoding and decoding types to and from JSON.
/// Types conforming to this protocol gain automatic implementations for converting to JSON data, strings,
/// and dictionary representations with comprehensive error handling.
///
///
/// Conform your types to `JSONSerializable` to gain automatic JSON conversion capabilities:
///
/// ```swift
/// struct User: JSONSerializable {
///     let id: Int
///     let name: String
///     let email: String
/// }
///
/// // Encoding
/// let user = User(id: 1, name: "John", email: "john@example.com")
/// let jsonData = try user.toJSONData()
/// let jsonString = try user.toJSONString()
///
/// // Decoding
/// let decodedUser = try User.initialize(jsonData: jsonData)
/// ```
public protocol JSONSerializable: Codable {
    
    /// Serializes the instance into JSON-encoded data.
    ///
    /// This method encodes the instance into a UTF-8 encoded JSON data representation,
    /// suitable for network requests or persistent storage.
    ///
    /// - Returns: The JSON-encoded data representation of the instance.
    /// - Throws: `JSONSerializableError.encodingError` if encoding fails.
    func toJSONData() throws -> Data
    
    /// Serializes the instance into a JSON string.
    ///
    /// This method converts the instance into a human-readable JSON string representation,
    /// useful for debugging or text-based storage.
    ///
    /// - Returns: A UTF-8 encoded JSON string representation of the instance.
    /// - Throws: `JSONSerializableError.encodingError` if encoding fails.
    func toJSONString() throws -> String
    
    /// Serializes the instance into a dictionary representation.
    ///
    /// This method converts the instance into a `Dictionary<String, Any>`, which can be useful
    /// for interoperability with JavaScript or other dynamic systems that expect dictionary types.
    ///
    /// - Note: This method cannot be used with `Array<JSONSerializable>` types and will throw an error if attempted.
    /// - Returns: A dictionary representation of the instance.
    /// - Throws: `JSONSerializableError.encodingError` if the instance is an array, or `JSONSerializableError.decodingError` if conversion fails.
    func toJSONObject() throws -> Dictionary<String, Any>
    
    /// Creates a new instance from JSON-encoded data.
    ///
    /// This static method decodes JSON data into an instance of the conforming type.
    /// If `jsonData` is `nil`, it attempts to decode from an empty JSON object (`{}`),
    /// which succeeds only if all properties have default values or are optional.
    ///
    /// - Parameters:
    ///   - jsonData: The UTF-8 encoded JSON data to decode. If `nil`, attempts to decode from an empty JSON object.
    ///   - codingUserInfo: A dictionary of user-defined keys and values to provide context for decoding.
    /// - Returns: A new instance of the conforming type.
    /// - Throws: `JSONSerializableError.decodingError` if decoding fails due to missing keys, type mismatches, corrupted data, or other errors.
    static func initialize(jsonData: Data?, codingUserInfo: [CodingUserInfoKey : any Sendable]) throws -> Self
}

//MARK: - JSONSerializable protocol Implementation

/// Implements the functions of JSONSerializable protocol.
public extension JSONSerializable {
    
    func toJSONData() throws -> Data {
        do {
            let encodeObject: Data = try Self.jsonEncoder.encode(self)
            return encodeObject
        } catch EncodingError.invalidValue(let invalidValue, let context) {
            let message = "An error occurred encoding object of type \(Self.typeName).  Error message: \(context.debugDescription)  Invalid Value: \(invalidValue)   Decoding path: \(context.codingPath)."
            throw JSONSerializableError.encodingError.invalidValue(message: message)
        } catch {
            let message = "An error occurred encoding object of type \(Self.typeName).  Error message: \(error.localizedDescription)."
            throw JSONSerializableError.encodingError.exception(message: message)
        }
    }
    
    func toJSONString() throws -> String {
        let jsonData = try self.toJSONData()
        let jsonString = String(data: jsonData, encoding: .utf8)
        return jsonString!
    }
    
    func toJSONObject() throws -> Dictionary<String, Any> {
        guard self is Array<JSONSerializable> == false else {
            throw JSONSerializableError.encodingError.exception(message: "Error, cannot convert Array<JSONSerializable> to Dictionary.")
        }
        
        let modelData = try self.toJSONData()
        var decodedObject: Dictionary<String, Any>
        do {
            decodedObject = try JSONSerialization.jsonObject(with: modelData, options: .allowFragments) as! [String: Any]
        } catch DecodingError.keyNotFound(let codingKey, let context) {
            let message = "Key not found error decoding instance of `\(Self.typeName)`.\nExpected value for key '\(codingKey.stringValue)'.\nDecoding path: \(Self.debugCodingPath(context.codingPath))\nError message: \(context.debugDescription)\n."
            throw JSONSerializableError.decodingError.keyNotFound(message: message)
        } catch DecodingError.typeMismatch(let expectedKeyType, let context) {
            let message = "Type mismatch error decoding instance of '\(Self.typeName)'.\nExpected Type: \(expectedKeyType)\nDecoding path: \(Self.debugCodingPath(context.codingPath)).\nError message: \(context.debugDescription)"
            throw JSONSerializableError.decodingError.typeMismatch(message: message)
        } catch DecodingError.valueNotFound(let missingKeyType, let context) {
            let message = "Value not found error decoding instance of '\(Self.typeName)'.\nMissing value for type: \(missingKeyType)\nDecoding path: \(Self.debugCodingPath(context.codingPath)).\nError message: \(context.debugDescription)"
            throw JSONSerializableError.decodingError.valueNotFound(message: message)
        } catch DecodingError.dataCorrupted(let context) {
            let message = "Data corrupted when decoding instance of '\(Self.typeName)'.\nDecoding path: \(Self.debugCodingPath(context.codingPath))\nError message: \(context.debugDescription)."
            throw JSONSerializableError.decodingError.dataCorrupted(message: message)
        } catch {
            let message = "Exception decoding type '\(Self.typeName)'.\nError message: \(error)"
            throw JSONSerializableError.decodingError.exception(message: message)
        }
        return decodedObject
    }
}

//MARK: - JSONSerializable Object Initializers

extension JSONSerializable where Self: JSONSerializable {
    
    public static func initialize(jsonData: Data?, codingUserInfo: [CodingUserInfoKey : any Sendable] = [:]) throws -> Self {
        
        let decoder = Self.jsonDecoder
        for key in codingUserInfo.keys {
            decoder.userInfo[key] = codingUserInfo[key]
        }
        
        /*
         Nil coalesce to empty representation and let JSONDecoder determine if the definition supports it.
         If the model definition does not support empty object, JSONSerializable will throw a decoder
         exception and this will then be handled by the caller as a failed decode operation with all the
         necessary information to triage.
         */
        let modelData = jsonData ?? "{}".data(using: .utf8)!
        
        do {
            return try decoder.decode(Self.self, from: modelData)
        } catch DecodingError.keyNotFound(let codingKey, let context) {
            let message = "Key not found error decoding instance of `\(Self.typeName)`.\nExpected value for key '\(codingKey.stringValue)'. \nDecoding path: \(Self.debugCodingPath(context.codingPath)) \nError message: \(context.debugDescription)"
            throw JSONSerializableError.decodingError.keyNotFound(message: message)
        } catch DecodingError.typeMismatch(let expectedKeyType, let context) {
            let message = "Type mismatch error decoding instance of '\(Self.typeName)'.\nExpected Type: \(expectedKeyType)\nDecoding path: \(Self.typeName).\(Self.debugCodingPath(context.codingPath)).\nError message: \(context.debugDescription)"
            throw JSONSerializableError.decodingError.typeMismatch(message: message)
        } catch DecodingError.valueNotFound(let missingKeyType, let context) {
            let message = "Value not found error decoding instance of '\(Self.typeName)'.\nMissing value for type: \(missingKeyType)\nDecoding path: \(Self.debugCodingPath(context.codingPath)).\nError message: \(context.debugDescription)"
            throw JSONSerializableError.decodingError.valueNotFound(message: message)
        } catch DecodingError.dataCorrupted(let context) {
            let message = "Data corrupted when decoding instance of '\(Self.typeName)' - check for malformed JSON.\nError message: \(context.debugDescription)"
            throw JSONSerializableError.decodingError.dataCorrupted(message: message)
        } catch {
            let message = "Exception decoding type '\(Self.typeName)'.\nError message: \(error)"
            throw JSONSerializableError.decodingError.exception(message: message)
        }
    }
    

    /// Initialize a new instance from a dictionary representation.
    ///
    /// This initializer creates an instance of the conforming type from a dictionary. If the `dictionary` parameter is `nil`,
    /// it attempts to create an instance from an empty JSON object representation (`{}`). This behavior succeeds only if
    /// the model definition supports initialization from an empty object (i.e., all properties have default values or are optional).
    ///
    /// - Parameter dictionary: The dictionary representation of the type to be decoded. If `nil`, attempts to decode from an empty JSON object.
    /// - Throws: `JSONSerializableError.decodingError` if the dictionary cannot be serialized to JSON data or if decoding fails.
    public init(dictionary: [String: Any]?) throws {
        if let dictionary {
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            self = try Self.initialize(jsonData: data)
        } else {
            self = try Self.initialize(jsonData: nil)
        }
    }
}

//MARK: - JSONSerializable Array Implementation

extension Array: JSONSerializable where Element: JSONSerializable {
    
    /// Creates a new array instance from JSON-encoded data.
    ///
    /// This static method decodes JSON data into an array of elements conforming to `JSONSerializable`.
    /// If `jsonData` is `nil`, it attempts to decode from an empty JSON array (`[]`), which always
    /// succeeds and returns an empty array.
    ///
    /// - Parameters:
    ///   - jsonData: The UTF-8 encoded JSON data to decode. If `nil`, attempts to decode from an empty JSON array.
    ///   - codingUserInfo: A dictionary of user-defined keys and values to provide context for decoding.
    /// - Returns: A new array of elements decoded from the JSON data.
    /// - Throws: `JSONSerializableError.decodingError` if decoding fails due to missing keys, type mismatches, corrupted data, or other errors.
    public static func initialize(jsonData: Data?, codingUserInfo: [CodingUserInfoKey : any Sendable] = [:]) throws -> [Element] {

        let decoder = Element.jsonDecoder
        for key in codingUserInfo.keys {
            decoder.userInfo[key] = codingUserInfo[key]
        }
        
        /*
         Nil coalesce to empty representation and let JSONDecoder determine if the definition supports it.
         If the model definition does not support empty object, JSONSerializable will throw a decoder
         exception and this will then be handled by the caller as a failed decode operation with all the
         necessary information to triage.
         */
        let modelData = jsonData ?? "[]".data(using: .utf8)!

        do {
            return try decoder.decode([Element].self, from: modelData)
        } catch DecodingError.keyNotFound(let codingKey, let context) {
            let message = "Key not found error decoding instance of `\(Self.typeName)`.\nExpected value for key '\(codingKey.stringValue)'.\nDecoding path: \(Self.debugCodingPath(context.codingPath))\nError message: \(context.debugDescription)"
            throw JSONSerializableError.decodingError.keyNotFound(message: message)
        } catch DecodingError.typeMismatch(let expectedKeyType, let context) {
            let message = "Type mismatch error decoding instance of '\(Self.typeName)'.\nExpected Type: \(expectedKeyType)\nDecoding path: \(Self.debugCodingPath(context.codingPath)).\nError message: \(context.debugDescription)"
            throw JSONSerializableError.decodingError.typeMismatch(message: message)
        } catch DecodingError.valueNotFound(let missingKeyType, let context) {
            let message = "Value not found error decoding instance of '\(Self.typeName)'.\nMissing value for type: \(missingKeyType)\nDecoding path: \(Self.debugCodingPath(context.codingPath)).\nError message: \(context.debugDescription)"
            throw JSONSerializableError.decodingError.valueNotFound(message: message)
        } catch DecodingError.dataCorrupted(let context) {
            let message = "Data corrupted when decoding instance of '\(Self.typeName)'.\nDecoding path: \(Self.debugCodingPath(context.codingPath))\nError message: \(context.debugDescription)"
            throw JSONSerializableError.decodingError.dataCorrupted(message: message)
        } catch {
            let message = "Exception decoding type '\(Self.typeName)'.\nError message: \(error)"
            throw JSONSerializableError.decodingError.exception(message: message)
        }
    }
    
    public func toJSONData() throws -> Data {
        do {
            let jsonEncoder = Element.jsonEncoder
            let encodeObject: Data = try jsonEncoder.encode(self)
            return encodeObject
        } catch EncodingError.invalidValue(let invalidValue, let context) {
            let message = "An error occurred encoding object of type \(Element.typeName).  Error message: \(context.debugDescription)  Invalid Value: \(invalidValue)   Decoding path: \(context.codingPath)."
            throw JSONSerializableError.encodingError.invalidValue(message: message)
        } catch {
            let message = "An error occurred encoding object of type \(Element.typeName).  Error message: \(error)"
            throw JSONSerializableError.encodingError.exception(message: message)
        }
    }
}

extension JSONSerializable {
    
    //MARK: - Private Static API
    
    fileprivate static func debugCodingPath(_ codingPath: [CodingKey]) -> String {
        
        let debugString = codingPath.compactMap({
            if $0.intValue != nil {
                return "[\($0.intValue!)]"
            } else {
                return $0.stringValue
            }
        }).reduce("", {
            if $0 == "" {
                return $1
            } else if $1.first == "[" && $1.last == "]" {
                return $0 + $1
            } else {
                return $0 + "." + $1
            }
        })
        
        return debugString
    }

    
    fileprivate static var jsonEncoder: JSONEncoder {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .formatted(ISO8601DateFormatter.dateFormatter)
        return jsonEncoder
    }
    
    fileprivate static var jsonDecoder: JSONDecoder {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .formatted(ISO8601DateFormatter.dateFormatter)
        return jsonDecoder
    }
    
    fileprivate static var typeName: String {
        return String(describing: Self.self)
    }
}

/// Codable using format: "yyyy-MM-dd'T'HH:mm:ssZ"
fileprivate struct ISO8601DateFormatter {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }()
}

public enum JSONSerializableError: Error {
    
    public enum encodingError: Error {
        case invalidValue(message: String)
        case exception(message: String)
    }
    
    public enum decodingError: Error {
        case keyNotFound(message: String)
        case typeMismatch(message: String)
        case valueNotFound(message: String)
        case dataCorrupted(message: String)
        case exception(message: String)
    }
}

extension JSONSerializableError.decodingError: CustomStringConvertible {
    public var description: String {
        switch self {
            case .keyNotFound(let message):
                return message
            case .valueNotFound(let message):
                return message
            case .dataCorrupted(let message):
                return message
            case .typeMismatch(let message):
                return message
            case .exception(let message):
                return message
        }
    }
    
    public var localizedDescription: String {
        return self.description
    }
}

extension JSONSerializableError.encodingError: CustomStringConvertible {
    public var description: String {
        switch self {
            case .invalidValue(let message):
                return message
            case .exception(let message):
                return message
        }
    }
    
    public var localizedDescription: String {
        return self.description
    }
}
