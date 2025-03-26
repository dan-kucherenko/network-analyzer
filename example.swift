
import Foundation

let config = URLSessionConfiguration.default

config.httpAdditionalHeaders = ["User-Agent": "MyApp", "Accept": "application/json"]
config.httpShouldSetCookies = true
config.httpCookieAcceptPolicy = .always
config.httpShouldUsePipelining = true

func configureSession() {
    let configuration = URLSessionConfiguration.default
//    configuration.allowsCellularAccess = false
    configuration.networkServiceType = .video
    configuration.waitsForConnectivity = true
}

func setupSession() {
    let config = URLSessionConfiguration.default
    config.httpMaximumConnectionsPerHost = 10
//    config.allowsExpensiveNetworkAccess = true
}


class MyClass {
    var urlCache: URLCache
    var requestCachePolicy: NSURLRequest.CachePolicy
    
    init() {
        self.urlCache = URLCache(memoryCapacity: 10, diskCapacity: 10, diskPath: nil)
        self.requestCachePolicy = .reloadIgnoringLocalCacheData
    }

    func configureRequest() {
        let request = URLRequest(url: URL(string: "https://www.example.com")!)
        request.cachePolicy = requestCachePolicy
    
        let cachedResponse = urlCache.cachedResponse(for: request)
        print(cachedResponse ?? "No cache found")
    }
}

class NetworkConfig {
    var allowsExpensiveNetworkAccess: Bool = false
    
    func configureNetworkAccess() {
        allowsExpensiveNetworkAccess = true
        
        if allowsExpensiveNetworkAccess {
            print("Expensive network access allowed")
        } else {
            print("Expensive network access denied")
        }
    }
}

let config = NetworkConfig()
config.configureNetworkAccess()
