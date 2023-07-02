# API Manager
The `APIManager` class provides a convenient interface for making API requests, handling responses, and performing common API operations.
The class manages the request HTTP headers, URL query parameters, HTTP body parameters, and HTTP body data. It supports various HTTP methods including GET, POST, PUT, PATCH, and DELETE. Additionally, it includes functionality for handling image uploads, fetching images from URLs, and retrieving data from specified URLs.
Usage:
- Create an instance of `APIManager`.
- Set the request HTTP headers, URL query parameters, and HTTP body parameters as needed.
- Make an API request using the `makeRequest` method, providing the target URL, HTTP method, and completion handler for processing the results.
- Optionally, use the `fetchImage` method to fetch an image from a URL, or the `addImage` method to add an image to the HTTP body parameters.
- To retrieve data from a URL, use the `getData` method.

## Example:
```
let apiManager = APIManager()

apiManager.requestHttpHeaders.setContentType(contentType: .applicationJSON)

apiManager.httpBodyParameters.add(value: "John Doe", forKey: "name")

apiManager.makeRequest(toURL: url, withHttpMethod: .post) { result in
  //Handle the API response
}
```

# URL Manager
A manager class which is responsible for managing the URLs and endpoints of the API. It includes a `BASE_URL` constant that represents the base URL of the API. The Endpoint enum lists all the available endpoints, and each case corresponds to a specific API endpoint.
To retrieve the complete URL for a particular endpoint, you can call the `getURLFor(endpoint:)` function and pass the desired endpoint as an argument. It will concatenate the base URL with the endpoint's raw value and return the complete URL string.

## Setup: 
To set the endpoints for your application Just open the URL manager and add the URLEndpoint in the `Endpoint` Enum following way:
```
 enum Endpoint: String {
        // Auth endpoints
        case login = "login"
    }
```


## For example, to get the URL for the login endpoint, you can use:

```
let urlManager = URLManager()
let loginURL = urlManager.getURLFor(endpoint: .login)
print(loginURL) 
```
---
or you can get required URL directly by: 
```
URLManager().getURLFor(endpoint: .endpoint)
```
Output: https://example.com/api/login

This approach allows you to easily manage and retrieve URLs for different endpoints in a centralized manner.


# Example Usage:
## Steps:
1. Setup the Headers for the API
```
api.requestHttpHeaders.setContentType(contentType: .applicationJSON)
api.requestHttpHeaders.add(value: value, forKey: "key")
```

2. Setup the Body for the Request
```
api.httpBodyParameters.add(value: value, forKey: "key")
```

3. generating URL in a if-let statement to properly handel the Null-errors if they occour
```
if let url = URLManager().getURLFor(endpoint: .endpoint) {
    // implement the code [PUT CODE IN setp 4 here]
} else {
    debugPrint("Error Generating URL")
}
```
4. Call the API Using the make request 
```
api.makeRequest(toURL: url, withHttpMethod: .post) { result in
    // Perform the api response logic here
}        
```

### Tips:
* Always use Guard, if let, do - catch statements in order to prevent any error from crashing the app
* To access the response you can use the result object 
    - `data`: The data received in the response.
    - `response`: The response received from the API. [StatusCode, URLResponse, ResponseHeaders]
    - `error`: The error encountered during the request, if any.

* In the `makeRequest()` function Following pattern can be used (its Just a suggestion you can use your own as well):
    - `200` : Continue with the flow
    - `404` : Handel 404 seperately
    - `419` : Handel JWT error seperately
    - `400` - 499: Display Unable to Reach to the server
    - `500` - 599: There was an error logging in

    ```
    if result.response?.httpStatusCode == 200 {
        ...
        //response success action
        let data = reslut.data
        ...
    }else if result.response?.httpStatusCode == 404 {
        ...
        //Handeling 404 Error
        ...
    } else if 400...499 ~= result.response?.httpStatusCode ?? 0 {
        ...
        //Handeling 400 - 499 Errors
        ...
    } else if 500...599 ~= result.response?.httpStatusCode ?? 0 {
        ...
        // Handeling Server errors
        ...
    }
    ```