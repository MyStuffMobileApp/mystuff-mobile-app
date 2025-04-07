
import Foundation
import UIKit

class OpenAIService {
    private let apiKey: String
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func analyzeImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        print("Starting image analysis")
        
        // Resize and convert image to base64
        guard let resizedImage = resizeImage(image, targetSize: CGSize(width: 512, height: 512)) else {
            print("Failed to resize image")
            completion(.failure(AnalysisError.imageProcessingFailed))
            return
        }
        
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
            print("Failed to convert image to JPEG data")
            completion(.failure(AnalysisError.imageProcessingFailed))
            return
        }
        
        // Get direct base64 string without percent encoding - OpenAI expects raw base64
        let base64String = imageData.base64EncodedString()
        print("Image converted to base64 string of length: \(base64String.count)")
        
        // Create request body
        let requestBody: [String: Any] = [
            "model": "gpt-4o",  // Updated to use gpt-4o which supports vision
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": "What objects (not humans or pets) can you identify in this image? Please list them as comma-separated values."
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64String)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 300
        ]
        
        // Create request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        // Make request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("No data received from API")
                completion(.failure(AnalysisError.noDataReceived))
                return
            }
            
            // Print response for debugging
            if let httpResponse = response as? HTTPURLResponse {
                print("API Response Status Code: \(httpResponse.statusCode)")
                
                // Handle API errors based on status code
                if httpResponse.statusCode != 200 {
                    // Try to parse error message from response
                    if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorObj = errorJson["error"] as? [String: Any],
                       let errorMsg = errorObj["message"] as? String {
                        print("API Error: \(errorMsg)")
                        completion(.failure(AnalysisError.apiError(message: errorMsg)))
                        return
                    } else {
                        // If we can't parse the error, return a generic error with the status code
                        completion(.failure(AnalysisError.httpError(statusCode: httpResponse.statusCode)))
                        return
                    }
                }
            }
            
            do {
                // Print raw JSON for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("API Response: \(jsonString.prefix(200))...") // Print first 200 chars
                }
                
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        completion(.success(content))
                    } else if let error = json["error"] as? [String: Any],
                              let message = error["message"] as? String {
                        print("API returned error: \(message)")
                        completion(.failure(AnalysisError.apiError(message: message)))
                    } else {
                        print("Invalid response structure")
                        completion(.failure(AnalysisError.invalidResponse))
                    }
                } else {
                    print("Could not parse JSON response")
                    completion(.failure(AnalysisError.invalidResponse))
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    enum AnalysisError: Error, LocalizedError {
        case imageProcessingFailed
        case noDataReceived
        case invalidResponse
        case apiError(message: String)
        case httpError(statusCode: Int)
        
        var errorDescription: String? {
            switch self {
            case .imageProcessingFailed:
                return "Failed to process the image for analysis"
            case .noDataReceived:
                return "No data received from the API"
            case .invalidResponse:
                return "The API response was invalid or in an unexpected format"
            case .apiError(let message):
                return "API Error: \(message)"
            case .httpError(let statusCode):
                return "HTTP Error: Status code \(statusCode)"
            }
        }
    }
}
