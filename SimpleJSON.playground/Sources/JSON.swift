import Foundation

/// A typealias of a JSON dictionary object
public typealias JSONObject = [String: Any]

/// Just a namspace for some static functions
public struct JSON {
    private init() { }
}

// MARK: - Decoding
public protocol JSONDecodable {

    /// Allows for initialization of the reciever with the provided JSONObject representation.
    ///
    /// - Parameter json: The JSON object intended to be represented by this object
    /// - Throws: An error that might have occoured when mapping the JSON to the object
    init(json: JSONObject) throws
}

public extension JSON {

    /// Attempts to read a parameter from the provided JSONObject as the inferred type using generics.
    /// Failure to decode the parameter could occour if either the key does not exist (JSON.Error.Code.missing)
    ///  or the decoded value was not of the inferred type (T) (JSON.Error.Code.invalid).
    ///
    /// - Parameters:
    ///   - key: The key from the JSON object that should be decoded
    ///   - object: The JSON object that the value is attempting to be decoded from
    /// - Returns: The decoded value with the inferred return type
    /// - Throws: A JSON.Error object describing the failure that occoured when attempting to decode the paramter
    public static func decode<T>(_ key: String, from object: JSONObject) throws -> T {
        guard let value = object[key] else { throw Error.Decoding(code: .missing, parameter: key) }

        if let decoded = value as? T {
            return decoded
        } else {
            throw Error.Decoding(code: .invalid, parameter: key)
        }
    }

    /// Attempts to read a parameter from the provided JSONObject as the inferred RawRepresentable type
    ///  using Generics by decoding the JSONObject as the RawRepresentable.RawValue type and then initializing
    ///  with the decoded value as the `rawValue`.
    ///
    /// - Parameters:
    ///   - key: The key from the JSON object that should be decoded
    ///   - object: The JSON object that the value is attempting to be decoded from
    /// - Returns: The decoded value with the inferred return type
    /// - Throws: A JSON.Error object describing the failure that occoured when attempting to decode the paramter
    public static func decode<T: RawRepresentable>(_ key: String, from object: JSONObject) throws -> T {
        let rawValue: T.RawValue = try decode(key, from: object)

        if let value = T(rawValue: rawValue) {
            return value
        } else {
            throw Error.Decoding(code: .invalid, parameter: key)
        }
    }

    /// Attempts to read the parameter from the provided JSONObject as a child JSONObject and then initialise it
    ///  into the inferred JSONDecodable type via the protocol initialiser.
    ///
    /// - Parameters:
    ///   - key: The key from the JSON object that should be decoded
    ///   - object: The JSON object that the value is attempting to be decoded from
    /// - Returns: The decoded value with the inferred return type
    /// - Throws: A JSON.Error object describing the failure that occoured when attempting to decode the paramter
    ///            or the error that the inferred JSONDecodable threw when trying to decode the object.
    public static func decode<T: JSONDecodable>(_ key: String, from object: JSONObject) throws -> T {
        let data: JSONObject = try decode(key, from: object)

        do {
            return try T(json: data)
        } catch {
            if let error = error as? JSON.Error.Decoding {
                throw Error.Decoding(code: error.code, parameter: key + "." + error.parameter)
            } else {
                throw error
            }
        }
    }

    /// Attempts to read the parameter from the provided JSON object as an array of JSONDecodable objects.
    ///
    /// - Parameters:
    ///   - key: The key from the JSON object that should be decoded
    ///   - object: The JSON object that the value is attempting to be decoded from
    ///   - strict: If errors should be suppresed or not. A strict operation will throw errors decoding array 
    ///              elements where a non strict operation will flat map the results and suppress any failures.
    /// - Returns: An array of the decoded json objects
    /// - Throws: A JSON.Error object describing the failure that occoured when attempting to decode the paramter
    ///            or the error that the inferred JSONDecodable threw when trying to decode the object.
    public static func decodeArray<T: JSONDecodable>(_ key: String, from object: JSONObject, strict: Bool) throws -> [T] {
        let array: [JSONObject] = try decode(key, from: object)

        // flat map if we aren't being strict
        guard strict else {
            return array.flatMap { try? T(json: $0) }
        }

        // if we want strict parsing, enumerate the old fashioned way so we can capture the index on failure
        var decoded = [T]()
        for (idx, item) in array.enumerated() {
            do {
                decoded.append(try T(json: item))
            } catch {
                if let error = error as? JSON.Error.Decoding {
                    throw Error.Decoding(code: error.code, parameter: key + "[\(idx)]." + error.parameter)
                } else {
                    throw error
                }
            }
        }
        return decoded
    }

    /// Attempts to read a parameter from the provided JSONObject as a Date by decoding to a String
    ///  and then attempting to format an ISO8601 string into a Date.
    ///
    /// - Parameters:
    ///   - key: The key from the JSON object that should be decoded
    ///   - object: The JSON object that the value is attempting to be decoded from
    /// - Returns: A Date object representing the value for the key in the provided object.
    /// - Throws: A JSON.Error object describing the failure that occoured when attempting to decode the paramter
    public static func decode(_ key: String, from object: JSONObject) throws -> Date {
        let decoded: String = try decode(key, from: object)
        if let date = DateFormatter.iso8601UTCDateFormatter.date(from: decoded) {
            return date
        } else {
            throw Error.Decoding(code: .invalid, parameter: key)
        }
    }

    /// Attempts to read a parameter from the provided JSONObject as a URL by decoding to a String
    ///  and then attempting to initalise a URL instance with the decoded string.
    ///
    /// - Parameters:
    ///   - key: The key from the JSON object that should be decoded
    ///   - object: The JSON object that the value is attempting to be decoded from
    /// - Returns: A URL object representing the value for the key in the provided object.
    /// - Throws: A JSON.Error object describing the failure that occoured when attempting to decode the paramter
    public static func decode(_ key: String, from object: JSONObject) throws -> URL {
        let decoded: String = try decode(key, from: object)
        if let url = URL(string: decoded) {
            return url
        } else {
            throw Error.Decoding(code: .invalid, parameter: key)
        }
    }
}

// MARK: - Encoding
public protocol JSONEncodable {

    /// Returns an instance that descibes the reciever as a standard JSON object (String, Number, Null, 
    ///  Array<Any>, Dictionary<String: Any>)
    var encodableValue: Any? { get }
}

public extension JSON {

    /// Safely encodes an input value into something that will pass the `JSONSerialization.isValidJSONObject(:)`
    ///  check.
    ///
    /// Strings, Numbers and Optionals will be converted to their NSObject equivelant (NSNString, NSNumber or 
    ///  NSNull) where data types such as Array or Dictionary will be validated and have their inner values also
    ///  passed through the same `encode(:)` function. Non-Standard data types that conform to `JSONEncodable` 
    ///  can also be passed into this function where their `encodableValue` is taken and then also passed through
    ///  `encode(:)` to resolve into a valid json data type.
    ///
    /// If the input value could not be encoded into a valid JSON data type then the return value of this function
    ///  will be an instance of `NSNull`.
    ///
    /// - Parameter item: The item to be encoded into a valid JSON data type
    /// - Returns: The encoded representation of `item`.
    public static func encode(_ item: Any?) -> Any {

        // Handle "standard" object types that are already valid JSON
        if let item = item as? NSNumber { return item }
        if let item = item as? NSString { return item }
        if let item = item as? NSNull { return item }

        // If it conforms to JSONEncodable then encode it's encodable value
        if let item = item as? JSONEncodable {
            return encode(item.encodableValue)
        }

        // If we have a JSON dictionary then encode each value and return
        if let item = item as? JSONObject {
            var encoded = JSONObject()
            for (key, value) in item {
                encoded[key] = encode(value)
            }
            return encoded
        }

        // Finally if it's an array then attempt to encode the contents
        if let item = item as? [Any] {
            return item.map { encode($0) }
        }

        // Anything that cannot be represented as JSON should be returned as null
        return NSNull()
    }
}

extension URL: JSONEncodable {

    /// Encoded value represents the recievers absolute string value
    public var encodableValue: Any? {
        return absoluteString
    }
}

extension Date: JSONEncodable {

    /// Encoded value represents the reciever as an ISO8601 formatted string
    public var encodableValue: Any? {
        return DateFormatter.iso8601UTCDateFormatter.string(from: self)
    }
}

// MARK: - Error
public extension JSON {
    public struct Error {
        public struct Decoding: Swift.Error {

            /// A code reprenseting differnet types of decoding errors
            ///
            /// - missing: The parameter was not found on the JSONObject beign decoded
            /// - invalid: The parameter was invalid on the JSONObject beign decoded
            public enum Code {
                case missing, invalid
            }

            /// The code representing the type of error
            public let code: Code

            /// The failing parameter
            public let parameter: String
        }
    }
}
