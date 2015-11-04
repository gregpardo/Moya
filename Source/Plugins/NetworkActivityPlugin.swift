import Foundation

/// Network activity change notification type.
public enum NetworkActivityChangeType {
    case Began, Ended
}

/// Provides each request with optional NSURLCredentials.
public class NetworkActivityPlugin<Target: MoyaTarget>: Plugin<Target> {
    
    public typealias NetworkActivityClosure = (change: NetworkActivityChangeType) -> ()
    let networkActivityClosure: NetworkActivityClosure
    
    public init(networkActivityClosure: NetworkActivityClosure) {
        self.networkActivityClosure = networkActivityClosure
    }

    // MARK: Plugin

    /// Called by the provider as soon as the request is about to start
    public override func willSendRequest(request: MoyaRequest, provider: MoyaProvider<Target>, target: Target) -> MoyaProvider<Target>.Request {
        networkActivityClosure(change: .Began)
        return MoyaProvider<Target>.Request(request, provider: provider, target: target)
    }

    /// Called by the provider as soon as a response arrives
    public override func didReceiveResponse(object: AnyObject?, statusCode: Int?, response: NSURLResponse?, error: ErrorType?, provider: MoyaProvider<Target>, target: Target) -> MoyaProvider<Target>.Response {
        networkActivityClosure(change: .Ended)
        return MoyaProvider<Target>.Response(object, statusCode: statusCode, response: response, error: error, provider: provider, target: target)
    }
}