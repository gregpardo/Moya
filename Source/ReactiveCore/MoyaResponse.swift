import Foundation

public class MoyaResponse: NSObject, CustomDebugStringConvertible {
    public let statusCode: Int
    public let object: AnyObject
    public let response: NSURLResponse?
    
    public init(statusCode: Int, object: AnyObject, response: NSURLResponse?) {
        self.statusCode = statusCode
        self.object = object
        self.response = response
    }
    
    override public var description: String {
        if let data = object as? NSData {
            return "Status Code: \(statusCode), Data Length: \(data.length)"
        } else {
            return "Status Code: \(statusCode)"
        }
    }
    
    override public var debugDescription: String {
        return description
    }
}

/// Required for making Endpoint conform to Equatable.
public func ==<T>(lhs: Endpoint<T>, rhs: Endpoint<T>) -> Bool {
    return lhs.urlRequest.isEqual(rhs.urlRequest)
}

/// Required for using Endpoint as a key type in a Dictionary.
extension Endpoint: Equatable, Hashable {
    public var hashValue: Int {
        return urlRequest.hash
    }
}
