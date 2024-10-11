import Foundation
import UIKit

/// A service to perform uploading images to Gravatar.
///
/// This is the default type which implements ``ImageUploader``.
struct ImageUploadService: ImageUploader {
    private let client: HTTPClient

    init(urlSession: URLSessionProtocol? = nil) {
        self.client = URLSessionHTTPClient(urlSession: urlSession)
    }

    @discardableResult
    func uploadImage(
        _ image: UIImage,
        accessToken: String,
        avatarSelection: AvatarSelection = .preserveSelection,
        additionalHTTPHeaders: [HTTPHeaderField]?
    ) async throws -> (data: Data, response: HTTPURLResponse) {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw ImageUploadError.cannotConvertImageIntoData
        }

        return try await uploadImage(data: data, accessToken: accessToken, avatarSelection: avatarSelection, additionalHTTPHeaders: additionalHTTPHeaders)
    }

    private func uploadImage(
        data: Data,
        accessToken: String,
        avatarSelection: AvatarSelection,
        additionalHTTPHeaders: [HTTPHeaderField]?
    ) async throws -> (Data, HTTPURLResponse) {
        let boundary = "\(UUID().uuidString)"
        let request = URLRequest.imageUploadRequest(
            with: boundary,
            additionalHTTPHeaders: additionalHTTPHeaders,
            apiVersion: avatarSelection.supportedAPIVersion
        )
        .settingAuthorizationHeaderField(with: accessToken)
        // For the Multipart form/data, we need to send the email address, not the id of the emai address
        let body = imageUploadBody(with: data, boundary: boundary, avatarSelection: avatarSelection)
        do {
            return try await client.uploadData(with: request, data: body)
        } catch let error as HTTPClientError {
            throw ImageUploadError.responseError(reason: error.map())
        } catch {
            throw ImageUploadError.responseError(reason: .unexpected(error))
        }
    }
}

private func imageUploadBody(with imageData: Data, boundary: String, avatarSelection: AvatarSelection) -> Data {
    switch avatarSelection.supportedAPIVersion {
    case .v1:
        var account: Email? = switch avatarSelection {
        case .preserveSelection:
            nil
        case .selectUploadedImage(let email), .selectUploadedImageIfNoneSelected(let email):
            email
        }

        return imageUploadBodyV1(with: imageData, account: account, boundary: boundary)
    case .v3:
        return imageUploadBodyV3(with: imageData, boundary: boundary)
    }
}

private func imageUploadBodyV1(with imageData: Data, account: Email?, boundary: String) -> Data {
    enum UploadParameters {
        static let contentType = "application/octet-stream"
        static let filename = "profile.png"
        static let imageKey = "filedata"
        static let accountKey = "account"
    }

    var body = Data()

    // Image Payload
    body.append("--\(boundary)\r\n")
    body.append("Content-Disposition: form-data; name=\(UploadParameters.imageKey); ")
    body.append("filename=\(UploadParameters.filename)\r\n")
    body.append("Content-Type: \(UploadParameters.contentType);\r\n\r\n")
    body.append(imageData)
    body.append("\r\n")

    // Account Payload
    if let email = account?.string {
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\(UploadParameters.accountKey)\"\r\n\r\n")
        body.append("\(email)\r\n")
    }
    // EOF!
    body.append("--\(boundary)--\r\n")

    return body
}

private func imageUploadBodyV3(with imageData: Data, boundary: String) -> Data {
    enum UploadParameters {
        static let contentType = "application/octet-stream"
        static let filename = "profile"
        static let imageKey = "image"
    }

    var body = Data()

    // Image Payload
    body.append("--\(boundary)\r\n")
    body.append("Content-Disposition: form-data; name=\(UploadParameters.imageKey); filename=\(UploadParameters.filename)\r\n")
    body.append("Content-Type: \(UploadParameters.contentType);\r\n\r\n")
    body.append(imageData)
    body.append("\r\n")
    body.append("\r\n")
    // EOF!
    body.append("--\(boundary)--\r\n")

    return body
}

extension Data {
    fileprivate mutating func append(_ string: String) {
        if let data = string.data(using: String.Encoding.utf8) {
            append(data)
        }
    }
}

extension URLRequest {
    fileprivate static func imageUploadRequest(with boundary: String, additionalHTTPHeaders: [HTTPHeaderField]?, apiVersion: APIVersion) -> URLRequest {
        switch apiVersion {
        case .v1: imageUploadRequestV1(with: boundary, additionalHTTPHeaders: additionalHTTPHeaders)
        case .v3: imageUploadRequestV3(with: boundary, additionalHTTPHeaders: additionalHTTPHeaders)
        }
    }

    fileprivate static func imageUploadRequestV1(with boundary: String, additionalHTTPHeaders: [HTTPHeaderField]?) -> URLRequest {
        let url = URL(string: "https://api.gravatar.com/v1/upload-image")!
        var request = URLRequest(url: url)
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        additionalHTTPHeaders?.forEach { headerTuple in
            request.addValue(headerTuple.value, forHTTPHeaderField: headerTuple.name)
        }
        return request
    }

    fileprivate static func imageUploadRequestV3(with boundary: String, additionalHTTPHeaders: [HTTPHeaderField]?) -> URLRequest {
        let url = URL(string: "https://api.gravatar.com/v3/me/avatars")!
        var request = URLRequest(url: url)
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        additionalHTTPHeaders?.forEach { headerTuple in
            request.addValue(headerTuple.value, forHTTPHeaderField: headerTuple.name)
        }
        return request
    }
}

private enum APIVersion {
    case v1
    case v3
}

extension AvatarSelection {
    fileprivate var supportedAPIVersion: APIVersion {
        switch self {
        case .selectUploadedImageIfNoneSelected, .selectUploadedImage: .v1
        case .preserveSelection: .v3
        }
    }
}
