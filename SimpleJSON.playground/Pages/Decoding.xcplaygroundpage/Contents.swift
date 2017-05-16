/*: 
   # JSON Handling
   ## Decoding
   A simple solution to handling JSON mapping to Swift types
 */

import Foundation

/// The object used for example decoding
let testObject: [String: Any] = [
    "my_string": "this is a string",
    "my_number": 123.045,
    "my_integer": 99,
    "my_date": "2017-05-16T11:44:00",
    "my_url": "https://cookpad.com/us",
    "my_boolean": true,
    "my_status": 2,

    "my_array": [
        "one",
        "two",
        "three"
    ],

    "my_dictionary": [
        "one": "a",
        "two": "b",
        "three": "c"
    ],

    "my_mixed_array": [
        1,
        "one",
        true
    ],

    "my_model": [
        "id": 1,
        "type": "a model"
    ],

    "my_root_model": [
        "is_root": true,
        "model": [
            "id": 1,
            "type": "a nested model"
        ]
    ],

    "my_malformed_root_model": [
        "is_root": true,
        "model": [
            "id": 1,
            "type": nil
        ]
    ],

    "my_array_of_models": [
        ["id": 1, "type": "a model"],
        ["id": 2, "type": "a model"],
        ["id": 3, "type": nil],
        ["id": 4, "type": "a model"]
    ]
]

//: ### Standard JSON objects
//: Simple object instances (String, Number or Null) can just be cast to their type
let myString: String = try! JSON.decode("my_string", from: testObject)
let myNumber: Double = try! JSON.decode("my_number", from: testObject)
let myInteger: Int = try! JSON.decode("my_integer", from: testObject)
let myBoolean: Bool = try! JSON.decode("my_boolean", from: testObject)


//: ### Basic structures
//: Same applies to simple JSON structures
let myArrayOfStrings: [String] = try! JSON.decode("my_array", from: testObject)
let myDictionaryOfStringPairs: [String:String] = try! JSON.decode("my_dictionary", from: testObject)
let myArrayOfAnyItems: [Any] = try! JSON.decode("my_mixed_array", from: testObject)


//: ### Custom transforms
//: Extending `JSON` to add an additional `decode(_:from:)` function allows for custom transforms
let myDate: Date = try! JSON.decode("my_date", from: testObject)
let myUrl: URL = try! JSON.decode("my_url", from: testObject)


//: ### Model objects
//: Conforming to `JSONDecodable` provides a way to allow decoding of JSON dictionaries into custom Swift structures
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
//: If a `RawRepresentable.RawValue` type can be decoded then the raw representable is supported as well
enum Status: Int {
    case unknown = 0, idle, active
}

let myStatus: Status = try! JSON.decode("my_status", from: testObject)


//: ### Nested objects
//: `JSONDecodable` instances can be embedded within eachother to allow decoding of child models
struct RootModel: JSONDecodable {
    let isRoot: Bool
    let model: Model

    init(json: JSONObject) throws {
        isRoot = try JSON.decode("is_root", from: json)
        model = try JSON.decode("model", from: json)
    }
}

let myRootModel: RootModel = try! JSON.decode("my_root_model", from: testObject)
myRootModel.model.type

//: ### Optionals
//: Support for Optional can be achieved by using `try?` to prevent throwing of errors.
let myOptionalString: String? = try? JSON.decode("my_missing_value", from: testObject)


//: ### Missing parameter handling
//: Errors can inform if a paramter is missing
do {
    let _: String = try JSON.decode("my_string", from: [:])
} catch let decodeError as JSON.Error.Decoding {
    decodeError.code
    decodeError.parameter
} catch { }


//: ### Invalid parameter handling
//: Errors can inform if the parameter was an invalid type
do {
    let _: String = try JSON.decode("my_numer", from: testObject)
} catch let decodeError as JSON.Error.Decoding {
    decodeError.code
    decodeError.parameter
} catch { }


//: ### Nested error handling
//: The error's `parameter` property can identify nested errors and indexes within an array
do {
    let _: RootModel = try JSON.decode("my_malformed_root_model", from: testObject)
} catch let decodeError as JSON.Error.Decoding {
    decodeError.code
    decodeError.parameter
} catch { }


/*: 
 
 ### Decoding arrays
 There are two differnet options when it comes to decoding arrays:
 
 **Relaxed**  

 If an element in the array cannot be decoded then it is excluded from the result of arrays. This would be useful in cases where we might have an array of Recipes to display to the user but one of them has bad data. There is no point hiding the rest of the Recipes from our user just because of one bad Recipe.
 
 **Strict**  
 
 If an element in the array cannot be decoded then the error is thrown up the chain. This would be useful in cases where we might have an array of Ingredients for a Recipe and it's critical that we can display all the intended Ingredients otherwise this may be confusing to the user.

 */

// Relaxed
let myModels: [Model] = try! JSON.decodeArray("my_array_of_models", from: testObject, strict: false)
(testObject["my_array_of_models"] as! [Any]).count
myModels.count

// Strict
do {
    let _: [Model] = try JSON.decodeArray("my_array_of_models", from: testObject, strict: true)
} catch let decodeError as JSON.Error.Decoding {
    decodeError.code
    decodeError.parameter
} catch { }

//: [Encoding >](@next)

