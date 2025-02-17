import GravatarUI
import TestHelpers
import XCTest

enum GravatarImageSetMockResult {
    case fail
    case urlSessionError
    case success
}

actor TestImageFetcher: ImageDownloader {
    static let sessionErrorMessage: String = "Internet connection lost"
    private(set) var result: GravatarImageSetMockResult

    init(result: GravatarImageSetMockResult) {
        self.result = result
    }

    func fetchImage(with url: URL, forceRefresh: Bool, processingMethod: ImageProcessingMethod) async throws -> ImageDownloadResult {
        let task = Task<ImageDownloadResult, Error> {
            switch result {
            case .urlSessionError:
                throw ImageFetchingError.responseError(reason: .URLSessionError(error: TestURLSessionError(message: TestImageFetcher.sessionErrorMessage)))
            case .fail:
                let response = HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)!
                throw ImageFetchingError.responseError(reason: .invalidHTTPStatusCode(response: response))
            case .success:
                return ImageDownloadResult(image: ImageHelper.testImage, sourceURL: URL(string: url.absoluteString)!)
            }
        }
        return try await task.value
    }

    nonisolated func cancelTask(for url: URL) {}
}
