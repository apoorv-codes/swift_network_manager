//
//  APIManager.swift
//
//  Created by Apoorv Verma on 13/06/23.
//

import Foundation
import UIKit

/// The `APIManager` class provides a convenient interface for making API requests, handling responses, and performing common API operations.
///
/// The class manages the request HTTP headers, URL query parameters, HTTP body parameters, and HTTP body data. It supports various HTTP methods including GET, POST, PUT, PATCH, and DELETE. Additionally, it includes functionality for handling image uploads, fetching images from URLs, and retrieving data from specified URLs.
///
/// Usage:
/// - Create an instance of `APIManager`.
/// - Set the request HTTP headers, URL query parameters, and HTTP body parameters as needed.
/// - Make an API request using the `makeRequest` method, providing the target URL, HTTP method, and completion handler for processing the results.
/// - Optionally, use the `fetchImage` method to fetch an image from a URL, or the `addImageToHttpBody` method to add an image to the HTTP body parameters.
/// - To retrieve data from a URL, use the `getData` method.
///
/// Example:
/// ```
/// let apiManager = APIManager()
/// apiManager.requestHttpHeaders.add(value: "application/json", forKey: "Content-Type")
/// apiManager.httpBodyParameters.add(value: "John Doe", forKey: "name")
/// apiManager.makeRequest(toURL: url, withHttpMethod: .post) { result in
///   //Handle the API response
/// }
/// ```


class APIManager {
    /// Store HTTP request headers as key-value pairs
    var requestHttpHeaders = APIEntity()
    
    /// Store URL query parameters as key-value pairs
    var urlQueryParameters = APIEntity()
    
    /// Store HTTP body parameters as key-value pairs
    var httpBodyParameters = APIEntity()
    
    /// Store the HTTP body data
    var httpBody: Data?
    
//    MARK: Private Functions
    
    /// Adds URL query parameters to the given URL.
    ///
    /// - Parameter url: The original URL.
    /// - Returns: The updated URL with added query parameters, if any.
    private func addURLQueryParameters(toURL url: URL) -> URL {
        
        // Check if there are any URL query parameters to add
        if urlQueryParameters.totalItems() > 0 {
            // Create URL components and append query items
            guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
            
            var queryItems = [URLQueryItem]()
            for (key, value) in urlQueryParameters.allValues() {
                let item = URLQueryItem(name: key, value: value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed))
                
                queryItems.append(item)
            }
            
            urlComponents.queryItems = queryItems
            
            guard let updatedURL = urlComponents.url else { return url }
            return updatedURL
        }
        return url
    }
    
    /// Retrieves the HTTP body data based on the specified content type and parameters.
    ///
    /// - Returns: The HTTP body data.
    private func getHttpBody() -> Data? {
        guard let contentType = requestHttpHeaders.value(forKey: "Content-Type") else { return nil }
        
        if contentType.contains("application/json") {
            // Serialize the HTTP body parameters to JSON data
            return try? JSONSerialization.data(withJSONObject: httpBodyParameters.allValues(), options: [.prettyPrinted, .sortedKeys])
        } else if contentType.contains("application/x-www-form-urlencoded") {
            // Create the HTTP body string for URL-encoded form data
            let bodyString = httpBodyParameters.allValues().map { "\($0)=\(String(describing: $1.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)))" }.joined(separator: "&")
            
            return bodyString.data(using: .utf8)
        } else if contentType.contains("multipart/form-data") {
            // Create the HTTP body for multipart form data
            let boundary = generateBoundary()
            requestHttpHeaders.add(value: "multipart/form-data; boundary=\(boundary)", forKey: "Content-Type")
            
            return createMultipartFormData(boundary: boundary)
        } else {
            // Return the raw HTTP body data
            return httpBody
        }
    }
    
    /// Generates a boundary string for creating multipart form data.
    ///
    /// - Returns: The generated boundary string.
    private func generateBoundary() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    /// Creates multipart form data based on the specified boundary.
    ///
    /// - Parameter boundary: The boundary string for the multipart form data.
    /// - Returns: The created multipart form data.
    private func createMultipartFormData(boundary: String) -> Data? {
        let lineBreak = "\r\n"
        let httpBody = NSMutableData()
        
        for (key, value) in httpBodyParameters.allValues() {
            httpBody.append("--\(boundary + lineBreak)".data(using: .utf8)!)
            httpBody.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)".data(using: .utf8)!)
            httpBody.append("\(value + lineBreak)".data(using: .utf8)!)
        }
        
        if let image = httpBodyParameters.value(forKey: "image"),
           let imageData = image.data(using: .utf8),
           let imageBoundaryData = "--\(boundary + lineBreak)".data(using: .utf8),
           let imageDispositionData = "Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\(lineBreak)".data(using: .utf8),
           let imageContentTypeData = "Content-Type: image/jpeg\(lineBreak + lineBreak)".data(using: .utf8) {
            
            httpBody.append(imageBoundaryData)
            httpBody.append(imageDispositionData)
            httpBody.append(imageContentTypeData)
            httpBody.append(imageData)
            httpBody.append(lineBreak.data(using: .utf8)!)
        }
        
        httpBody.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)
        
        return httpBody as Data
    }
    
    /// Prepares the URLRequest object with the given URL, HTTP body data, and HTTP method.
    ///
    /// - Parameters:
    ///   - url: The target URL.
    ///   - httpBody: The HTTP body data.
    ///   - httpMethod: The HTTP method.
    /// - Returns: The prepared URLRequest object.
    private func prepareRequest(withURL url: URL?, httpBody: Data?, httpMethod: HttpMethod) -> URLRequest? {
        guard let url = url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        
        // Set the HTTP headers for the request
        for (header, value) in requestHttpHeaders.allValues() {
            request.setValue(value, forHTTPHeaderField: header)
        }
        
        request.httpBody = httpBody
        return request
    }
    
    // MARK: Public functions
    
    /// Makes an API request to the specified URL with the given HTTP method.
    ///
    /// - Parameters:
    ///   - url: The target URL.
    ///   - httpMethod: The HTTP method.
    ///   - completion: The completion handler to be called with the API results.
    func makeRequest(toURL url: URL, withHttpMethod httpMethod: HttpMethod, completion: @escaping (_ result: Results) -> Void) {
        // Perform the request asynchronously on a global queue
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let targetURL = self?.addURLQueryParameters(toURL: url)
            let httpBody = (httpMethod == .get) ? nil : self?.getHttpBody()
            guard let request = self?.prepareRequest(withURL: targetURL, httpBody: httpBody, httpMethod: httpMethod) else {
                // If failed to create the request, return the error in the completion handler
                completion(Results(withError: Error(status: "400", message: "Unable to create the URLRequest object")))
                return
            }
            
            // Create a URLSession and perform the data task
            let sessionConfiguration = URLSessionConfiguration.default
            let session = URLSession(configuration: sessionConfiguration)
            let task = session.dataTask(with: request) { (data, response, error) in

                completion(Results(withData: data,
                                   response: Response(fromURLResponse: response),
                                   error: error as? Error))
            }
            task.resume()
        }
    }
    
    /// Fetches an image from the specified URL.
    ///
    /// - Parameters:
    ///   - url: The URL of the image.
    ///   - completion: The completion handler to be called with the image data.
    func fetchImage(from url: URL, completionHandler: @escaping (UIImage?) -> Void) {
        let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completionHandler(nil)
                return
            }
            
            let image = UIImage(data: data)
            completionHandler(image)
        }
        
        dataTask.resume()
    }
    
    /// Adds an image to the HTTP body parameters.
    ///
    /// - Parameters:
    ///   - image: The image to be added.
    ///   - parameterName: The name of the parameter associated with the image.
    ///   - filename: The filename of the image.
    func addImageToHttpBody(image: UIImage, forKey key: String) {
        let imageData = image.jpegData(compressionQuality: 0.8)
        httpBodyParameters.add(value: imageData?.base64EncodedString() ?? "", forKey: key)
    }
    
    /// Retrieves data from the specified URL.
    ///
    /// - Parameters:
    ///   - url: The target URL.
    ///   - completion: The completion handler to be called with the retrieved data.
    public func getData(fromUrl url: URL, completion: @escaping (_ data: Data?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let sessionConfiguration = URLSessionConfiguration.default
            let session = URLSession(configuration: sessionConfiguration)
            let task = session.dataTask(with: url) { (data, response, error) in
                guard let data = data else { completion(nil); return }
                completion(data)
            }
            task.resume()
        }
    }
}

//MARK: API Manager structure
extension APIManager {
    /// Represents the HTTP methods used for API requests.
    ///
    /// Supported methods:
    /// - `get`: GET method.
    /// - `post`: POST method.
    /// - `put`: PUT method.
    /// - `patch`: PATCH method.
    /// - `delete`: DELETE method.
    enum HttpMethod: String {
        case get
        case post
        case put
        case patch
        case delete
    }
    
    ///Represents the HTTP content type used in the API
    ///
    ///Supported methods:
    /// - `applicationJSON`: for having content in JSON format
    /// - `urlEncoded`: for having content encoded in url itself
    /// - `multipartFormData` for having content inf FormData format
    enum HttpContentType: String {
        case applicationJSON = "application/json"
        case urlEncoded = "application/x-www-form-urlencoded"
        case multipartFormData = "multipart/form-data"
    }
    
    /// Represents an entity that stores key-value pairs for API-related values.
    struct APIEntity {
        private var values: [String: String] = [:]
        
        /// Adds a value for the specified key.
        ///
        /// - Parameters:
        ///   - value: The value to add.
        ///   - key: The key associated with the value.
        mutating func add(value: String, forKey key: String) {
            values[key] = value
        }
        
        /// Sets Content Type of the request
        ///
        /// - Parameters:
        ///   - value: The value to add.
        mutating func setContentType(contentType: HttpContentType) {
            values["Content-Type"] = "\(contentType.rawValue)"
        }
        
        /// Retrieves the value for the specified key.
        ///
        /// - Parameter key: The key associated with the value.
        /// - Returns: The value for the specified key, or `nil` if the key does not exist.
        func value(forKey key: String) -> String? {
            return values[key]
        }
        
        /// Retrieves all the key-value pairs.
        ///
        /// - Returns: A dictionary containing all the key-value pairs.
        func allValues() -> [String: String] {
            return values
        }
        
        /// Retrieves the total number of items (key-value pairs) in the entity.
        ///
        /// - Returns: The total number of items.
        func totalItems() -> Int {
            return values.count
        }
    }
    
    /// Represents the response received from an API request.
    struct Response {
        /// The URL response object.
        var response: URLResponse?
        /// The HTTP status code of the response.
        var httpStatusCode: Int = 0
        /// The headers received in the response.
        var headers = APIEntity()
        
        /// Initializes a `Response` object with the given URL response.
        ///
        /// - Parameter response: The URL response object.
        init(fromURLResponse response: URLResponse?) {
            guard let response = response else { return }
            self.response = response
            httpStatusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            
            if let headerFields = (response as? HTTPURLResponse)?.allHeaderFields {
                for (key, value) in headerFields {
                    headers.add(value: "\(value)", forKey: "\(key)")
                }
            }
        }
    }
    
    /// Represents the results of an API request.
    struct Results {
        /// The data received in the response.
        var data: Data?
        /// The response received from the API.
        var response: Response?
        /// The error encountered during the request, if any.
        var error: Error?
        
        /// Initializes a `Results` object with the given data, response, and error.
        ///
        /// - Parameters:
        ///   - data: The data received in the response.
        ///   - response: The response received from the API.
        ///   - error: The error encountered during the request, if any.
        init(withData data: Data?, response: Response?, error: Error?) {
            self.data = data
            self.response = response
            self.error = error
        }
        
        /// Initializes a `Results` object with the given error.
        ///
        /// - Parameter error: The error encountered during the request.
        init(withError error: Error) {
            self.error = error
        }
    }
}
