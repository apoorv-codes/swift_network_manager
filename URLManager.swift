//
//  URLmanager.swift
//  Audition Booking
//
//  Created by Apoorv Verma on 12/06/23.
//

import Foundation

///A manager class which is responsible for managing the URLs and endpoints of the API. It includes a BASE_URL constant that represents the base URL of the API. The Endpoint enum lists all the available endpoints, and each case corresponds to a specific API endpoint.
///To retrieve the complete URL for a particular endpoint, you can call the getURLFor(endpoint:) function and pass the desired endpoint as an argument. It will concatenate the base URL with the endpoint's raw value and return the complete URL string.
///
///For example, to get the URL for the login endpoint, you can use:
///```
///let urlManager = URLManager()
///let loginURL = urlManager.getURLFor(endpoint: .login)
///print(loginURL) // Output: "https://example.com/api/login"
///```
///This approach allows you to easily manage and retrieve URLs for different endpoints in a centralized manner.

class URLManager {
    /// The base URL of the API.
    let BASE_URL = "https://example.com/api/"
    
    /// Represents the available API endpoints.
    ///
    /// Usage: `.endpointName` will return a string containing the endpoint.
    enum Endpoint: String {
        // Auth endpoints
        case login = "login"
        case signup = "signup"
        case forget = "forgot-password"
        case otpVerify = "otp-verify"
        case otpResend = "otp-resend"
        case resetPassword = "reset-password"
        
        // Profile endpoints
        case profile = "profile"
        case editProfile = "edit-profile"
    }
    
    /// Returns the complete URL for the specified endpoint.
    ///
    /// - Parameter endpoint: The desired endpoint.
    /// - Returns: The complete URL.
    func getURLFor(endpoint: Endpoint) -> URL? {
        guard let url = URL(string: BASE_URL + endpoint.rawValue) else {
            return nil
        }
        return url
    }
}
