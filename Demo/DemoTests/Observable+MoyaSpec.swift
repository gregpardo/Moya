import Quick
import Moya
import RxSwift
import Nimble

// Necessary since UIImage(named:) doesn't work correctly in the test bundle
private extension UIImage {
    class func testPNGImage(named name: String) -> UIImage {
        class TestClass { }
        let bundle = NSBundle(forClass: TestClass().dynamicType)
        let path = bundle.pathForResource(name, ofType: "png")
        return UIImage(contentsOfFile: path!)!
    }
}

func observableSendingObject(object: AnyObject, statusCode: Int = 200) -> Observable<MoyaResponse> {
    return just(MoyaResponse(statusCode: statusCode, object: object, response: nil))
}

class ObservableMoyaSpec: QuickSpec {
    override func spec() {
        describe("status codes filtering") {
            it("filters out unrequested status codes") {
                let data = NSData()
                let observable = observableSendingObject(data, statusCode: 10)
                
                var errored = false
                _ = observable.filterStatusCodes(0...9).subscribe { (event) -> Void in
                    switch event {
                    case .Next(let object):
                        XCTFail("called on non-correct status code: \(object)")
                    case .Error:
                        errored = true
                    default:
                        break
                    }
                }
                
                expect(errored).to(beTruthy())
            }
            
            it("filters out non-successful status codes") {
                let data = NSData()
                let observable = observableSendingObject(data, statusCode: 404)
                
                var errored = false
                _ = observable.filterSuccessfulStatusCodes().subscribe { (event) -> Void in
                    switch event {
                    case .Next(let object):
                        XCTFail("called on non-success status code: \(object)")
                    case .Error:
                        errored = true
                    default:
                        break
                    }
                }
                
                expect(errored).to(beTruthy())
            }
            
            it("passes through correct status codes") {
                let data = NSData()
                let observable = observableSendingObject(data)
                
                var called = false
                _ = observable.filterSuccessfulStatusCodes().subscribeNext { (object) -> Void in
                    called = true
                }
                
                expect(called).to(beTruthy())
            }
            
            it("filters out non-successful status and redirect codes") {
                let data = NSData()
                let observable = observableSendingObject(data, statusCode: 404)
                
                var errored = false
                _ = observable.filterSuccessfulStatusAndRedirectCodes().subscribe { (event) -> Void in
                    switch event {
                    case .Next(let object):
                        XCTFail("called on non-success status code: \(object)")
                    case .Error:
                        errored = true
                    default:
                        break
                    }
                }
                
                expect(errored).to(beTruthy())
            }
            
            it("passes through correct status codes") {
                let data = NSData()
                let observable = observableSendingObject(data)
                
                var called = false
                _ = observable.filterSuccessfulStatusAndRedirectCodes().subscribeNext { (object) -> Void in
                    called = true
                }
                
                expect(called).to(beTruthy())
            }
            
            it("passes through correct redirect codes") {
                let data = NSData()
                let observable = observableSendingObject(data, statusCode: 304)
                
                var called = false
                _ = observable.filterSuccessfulStatusAndRedirectCodes().subscribeNext { (object) -> Void in
                    called = true
                }
                
                expect(called).to(beTruthy())
            }
        }
        
        describe("image maping") {
            it("maps data representing an image to an image") {
                let image = UIImage.testPNGImage(named: "testImage")
                let data = UIImageJPEGRepresentation(image, 0.75)
                let observable = observableSendingObject(data!)
                
                var size: CGSize?
                _ = observable.mapImage().subscribeNext { (image) -> Void in
                    size = image.size
                }
                
                expect(size).to(equal(image.size))
            }
            
            it("ignores invalid data") {
                let data = NSData()
                let observable = observableSendingObject(data)
                
                var receivedError: NSError?
                _ = observable.mapImage().subscribe { (event) -> Void in
                    switch event {
                    case .Next:
                        XCTFail("next called for invalid data")
                    case .Error(let error):
                        receivedError = error as NSError
                    default:
                        break
                    }
                }
                
                expect(receivedError?.code).to(equal(MoyaErrorCode.ImageMapping.rawValue))
            }
        }
        
        describe("JSON mapping") {
            it("maps data representing some JSON to that JSON") {
                let json = ["name": "John Crighton", "occupation": "Astronaut"]
                let data = try! NSJSONSerialization.dataWithJSONObject(json, options: .PrettyPrinted)
                let observable = observableSendingObject(data)
                
                var receivedJSON: [String: String]?
                _ = observable.mapJSON().subscribeNext { (json) -> Void in
                    if let json = json as? [String: String] {
                        receivedJSON = json
                    }
                }
                
                expect(receivedJSON?["name"]).to(equal(json["name"]))
                expect(receivedJSON?["occupation"]).to(equal(json["occupation"]))
            }
            
            it("returns a Cocoa error domain for invalid JSON") {
                let json = "{ \"name\": \"john }"
                let data = json.dataUsingEncoding(NSUTF8StringEncoding)
                let observable = observableSendingObject(data!)
                
                var receivedError: NSError?
                _ = observable.mapJSON().subscribe { (event) -> Void in
                    switch event {
                    case .Next:
                        XCTFail("next called for invalid data")
                    case .Error(let error):
                        receivedError = error as NSError
                    default:
                        break
                    }
                }
                
                expect(receivedError).toNot(beNil())
                expect(receivedError?.domain).to(equal("\(NSCocoaErrorDomain)"))
            }
        }
        
        describe("string mapping") {
            it("maps data representing a string to a string") {
                let string = "You have the rights to the remains of a silent attorney."
                let data = string.dataUsingEncoding(NSUTF8StringEncoding)
                let observable = observableSendingObject(data!)
                
                var receivedString: String?
                _ = observable.mapString().subscribeNext { (string) -> Void in
                    receivedString = string
                    return
                }
                
                expect(receivedString).to(equal(string))
            }
        }
    }
}
