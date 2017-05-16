/*:
   [< Decoding](@previous)

   # JSON Handling
   ## Encoding
   A simple solution to handling object mapping to JSON types
 */


import Foundation

//: ### Basic Encoding
//: In most cases the data type can be mapped to a valid JSON representation out the box
JSON.encode("a basic string")
JSON.encode(123.045)
JSON.encode(nil)
JSON.encode(NSNull())
JSON.encode(["one", "two", "three"])
JSON.encode(["one": "a", "two": "b", "three": "c"])


//: ### Custom Encoding
//: Making a non-standard object conform to `JSONEncodable` allows for encoding to standard JSON types in extensions.
JSON.encode(URL(string: "https://cookpad.com/us")) // String
JSON.encode(Date())


//: ### Model objects
//: Model objects can also conform to `JSONEncodable` to provide dictionary representations of themselves. These
//:  representations don't have to encode their child values as the `encode(:)` function handles that already.
struct Model: JSONEncodable {
    let id: Int
    let type: String
    let date: Date

    var encodableValue: Any? {
        return [
            "id": id,
            "type": type,
            "date": date
        ]
    }
}

let myModel = Model(id: 1, type: "a model", date: Date())
let myEncodedModel = JSON.encode(myModel.encodableValue)
JSONSerialization.isValidJSONObject(myEncodedModel)


//: ### Nested model objects
//: Nested models work in the exact same way. Unsupported data types can also be passed still but will be converted to `NSNull` when encoded
struct RootModel: JSONEncodable {
    let isRoot: Bool
    let model: Model
    let frame: CGRect

    var encodableValue: Any? {
        return [
            "is_root": isRoot,
            "model": model,
            "frame": frame // becomes NSNull when encoded
        ]
    }
}

let myRootModel = RootModel(isRoot: true, model: myModel, frame: .zero)
let myEncodedRootModel = JSON.encode(myRootModel.encodableValue)
JSONSerialization.isValidJSONObject(myEncodedRootModel)


//: ### Arrays
//: Arrays can also be easily encoded

let myModels = [
    Model(id: 1, type: "a model", date: Date()),
    Model(id: 2, type: "a model", date: Date()),
    Model(id: 3, type: "a model", date: Date()),
    Model(id: 4, type: "a model", date: Date())
]
let myEncodedModels = JSON.encode(myModels)
JSONSerialization.isValidJSONObject(myEncodedModels)


//: ### RawRepresentable
//: Unfortunatly I don't think there is a nice generic way to achieve similar to how `JSON.decode(_:from:)` works so for now `RawRepresentable` items still need to conform to `JSONEncodable`.
enum Status: Int, JSONEncodable {
    case unknown = 0, idle, active
    var encodableValue: Any? { return rawValue }
}

JSON.encode(Status.active)


