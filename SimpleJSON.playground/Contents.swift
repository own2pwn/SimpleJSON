/*: 
 *  # JSON Handling
 *  A simple solution to handling JSON
 */

import Foundation

let testObject: [String: Any] = [
    "my_string": "this is a string",
    "my_number": 123.045,
    "my_integer": 99,
    "my_array": ["one", "two", "three"],
    "my_dictionary": ["one": "a", "two": "b", "three": "c"],
    "my_mixed_array": [1, "one", true],
    "my_date": "2017-05-16T11:44:00",
    "my_url": "https://cookpad.com/us",
    "my_model": ["id": 1, "type": "a model"],
    "my_root_model": ["is_root": true, "model": ["id": 1, "type": "a nested model"]],
    "my_malformed_root_model": ["is_root": true, "model": ["id": 1, "type": nil]]
]

//: ## Decoding
//: ### Standard JSON objects
let myString: String = try! JSON.decode("my_string", from: testObject)
let myNumber: Double = try! JSON.decode("my_number", from: testObject)
let myInteger: Int = try! JSON.decode("my_integer", from: testObject)


//: ### Basic structures
let myArrayOfStrings: [String] = try! JSON.decode("my_array", from: testObject)
let myDictionaryOfStringPairs: [String:String] = try! JSON.decode("my_dictionary", from: testObject)
let myArrayOfAnyItems: [Any] = try! JSON.decode("my_mixed_array", from: testObject)


//: ### Custom transforms
let myDate: Date = try! JSON.decode("my_date", from: testObject)
let myUrl: URL = try! JSON.decode("my_url", from: testObject)


//: ### Model objects
struct Model: JSONDecodable {
    let id: Int
    let type: String

    init(json: JSONObject) throws {
        id = try JSON.decode("id", from: json)
        type = try JSON.decode("type", from: json)
    }
}
let myModel: Model = try! JSON.decode("my_model", from: testObject)


//: ### RawRepresentable
enum Status: Int {
    case unknown = 0, idle, active
}
let myStatus: Status = try! JSON.decode("my_status", from: ["my_status": 2])


//: ### Nested objects
struct RootModel: JSONDecodable {
    let isRoot: Bool
    let model: Model

    init(json: JSONObject) throws {
        isRoot = try JSON.decode("is_root", from: json)
        model = try JSON.decode("model", from: json)
    }
}
let myRootModel: RootModel = try! JSON.decode("my_root_model", from: testObject)


//: ### Optionals
let myOptionalString: String? = try? JSON.decode("my_missing_value", from: testObject)


//: ### Missing parameter handling
do {
    let _: String = try JSON.decode("my_string", from: [:])
} catch let decodeError as JSON.Error.Decoding {
    decodeError.code
    decodeError.parameter
} catch { }


//: ### Invalid parameter handling
do {
    let _: String = try JSON.decode("my_string", from: ["my_string":1])
} catch let decodeError as JSON.Error.Decoding {
    decodeError.code
    decodeError.parameter
} catch { }


//: ### Nested error handling
do {
    let _: RootModel = try JSON.decode("my_malformed_root_model", from: testObject)
} catch let decodeError as JSON.Error.Decoding {
    decodeError.code
    decodeError.parameter
} catch { }


// Basic Encoding
JSON.encode("a basic string")
JSON.encode(123.045)
JSON.encode(nil)
JSON.encode(NSNull())
JSON.encode(["one", "two", "three"])
JSON.encode(["one": "a", "two": "b", "three": "c"])


// Custom encoders
JSON.encode(URL(string: "https://cookpad.com/us")) // String
JSON.encode(Date())


// Model objects
extension Model: JSONEncodable {
    var encodableValue: Any? {
        return [
            "id": id,
            "type": type,
            "custom_type": Date()
        ]
    }
}
let myEncodedModel = JSON.encode(myModel.encodableValue)
JSONSerialization.isValidJSONObject(myEncodedModel)


// Nested model objects
extension RootModel: JSONEncodable {
    var encodableValue: Any? {
        return [
            "is_root": isRoot,
            "model": model,
            "unsupported_type": CGRect.zero // you'd never really do this but this shows bad types will be converted to NSNull
        ]
    }
}
let myEncodedRootModel = JSON.encode(myRootModel.encodableValue)
JSONSerialization.isValidJSONObject(myEncodedRootModel)

