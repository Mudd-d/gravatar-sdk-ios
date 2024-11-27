import Combine
import Foundation
@testable import GravatarUI
import TestHelpers
import Testing

@MainActor
final class AvatarPickerViewModelTests {
    var cancellables = Set<AnyCancellable>()
    var model: AvatarPickerViewModel

    init() {
        model = Self.createModel()
    }

    static func createModel(
        session: URLSessionAvatarPickerMock = .init(),
        imageDownloader: ImageDownloader = TestImageFetcher(result: .success)
    ) -> AvatarPickerViewModel {
        .init(
            email: .init("some@email.com"),
            authToken: "token",
            profileService: ProfileService(urlSession: session),
            avatarService: AvatarService(urlSession: session),
            imageDownloader: imageDownloader
        )
    }

    @Test
    func testFirstAvatarsAreLoaded() async throws {
        await confirmation { confirmation in
            model.grid.$avatars.dropFirst().sink { avatarModels in
                #expect(avatarModels.count == 5)
                confirmation.confirm()
            }.store(in: &cancellables)

            await model.refresh()
        }
    }

    @Test
    func testProfileIsLoaded() async throws {
        await confirmation { confirmation in
            model.$profileModel.dropFirst().sink { profileModel in
                #expect(profileModel?.displayName == "John Appleseed")
                confirmation.confirm()
            }.store(in: &cancellables)

            await model.refresh()
        }
    }

    @Test
    func testSelectAvatar() async throws {
        let toSelectID = "9862792c565394..."
        await model.refresh()
        await confirmation { confirmation in
            // First selectedAvatar change after setting the initial status.
            // Second selectedAvatar change is local set before the request.
            // Third selectedAvatar change is after the request, and the one we are interested in.
            model.grid.$selectedAvatar.dropFirst(2).sink { selected in
                #expect(selected?.isSelected == true)
                #expect(selected?.id == toSelectID)
                confirmation.confirm()
            }.store(in: &cancellables)
            let selected = await model.selectAvatar(with: toSelectID)
            #expect(selected?.id == toSelectID)
        }
    }

    @Test
    func testFetchOriginalSizeAvatarSuccess() async throws {
        await model.refresh()
        let avatar = try #require(model.grid.avatars.first, "No avatar found")

        await confirmation(expectedCount: 2) { confirmation in
            model.toastManager.$toasts.sink { toasts in
                #expect(toasts.count == 0, "No toast should be shown in success case")
                confirmation.confirm()
            }.store(in: &cancellables)

            var observedStates: [AvatarImageModel.State] = []
            model.grid.$avatars.sink { models in
                observedStates.append(models[0].state)
                if observedStates.count == 3 {
                    #expect(observedStates[0] == .loaded)
                    #expect(observedStates[1] == .loading)
                    #expect(observedStates[2] == .loaded)
                    confirmation.confirm()
                }
            }.store(in: &cancellables)
            let result = await model.fetchOriginalSizeAvatar(for: avatar)
            #expect(result != nil)
        }
    }

    @Test
    func testFetchOriginalSizeFailsWithURLSessionError() async throws {
        let model = Self.createModel(imageDownloader: TestImageFetcher(result: .urlSessionError))
        await model.refresh()
        let avatar = try #require(model.grid.avatars.first, "No avatar found")

        await confirmation(expectedCount: 2) { confirmation in
            model.toastManager.$toasts.sink { toasts in
                #expect(toasts.count <= 1)
                if toasts.count == 1 {
                    #expect(toasts.first?.message == TestImageFetcher.sessionErrorMessage)
                    #expect(toasts.first?.type == .error)
                    confirmation.confirm()
                }
            }.store(in: &cancellables)

            var observedStates: [AvatarImageModel.State] = []
            model.grid.$avatars.sink { models in
                observedStates.append(models[0].state)
                if observedStates.count == 3 {
                    #expect(observedStates[0] == .loaded)
                    #expect(observedStates[1] == .loading)
                    #expect(observedStates[2] == .loaded)
                    confirmation.confirm()
                }
            }.store(in: &cancellables)
            let result = await model.fetchOriginalSizeAvatar(for: avatar)
            #expect(result == nil)
        }
    }

    @Test
    func testFetchOriginalSizeFailsWithGenericError() async throws {
        let model = Self.createModel(imageDownloader: TestImageFetcher(result: .fail))
        await model.refresh()
        let avatar = try #require(model.grid.avatars.first, "No avatar found")

        await confirmation(expectedCount: 2) { confirmation in
            model.toastManager.$toasts.sink { toasts in
                #expect(toasts.count <= 1)
                if toasts.count == 1 {
                    #expect(toasts.first?.message == AvatarPickerViewModel.Localized.avatarShareFail)
                    #expect(toasts.first?.type == .error)
                    confirmation.confirm()
                }
            }.store(in: &cancellables)

            var observedStates: [AvatarImageModel.State] = []
            model.grid.$avatars.sink { models in
                observedStates.append(models[0].state)
                if observedStates.count == 3 {
                    #expect(observedStates[0] == .loaded)
                    #expect(observedStates[1] == .loading)
                    #expect(observedStates[2] == .loaded)
                    confirmation.confirm()
                }
            }.store(in: &cancellables)
            let result = await model.fetchOriginalSizeAvatar(for: avatar)
            #expect(result == nil)
        }
    }

    @Test
    func testUploadAvatar() async throws {
        model.grid.setAvatars([])

        await confirmation { confirmation in
            model.grid.$avatars.dropFirst(2).sink { avatars in
                #expect(avatars.count == 1)
                let avatar = avatars.first!
                #expect(avatar.state == .loaded)
                switch avatar.source {
                case .remote: #expect(Bool(true))
                default: #expect(Bool(false))
                }
                confirmation.confirm()
            }.store(in: &cancellables)

            await model.upload(ImageHelper.exampleAvatarImage, shouldSquareImage: false)

            #expect(model.grid.avatars.count == 1)
        }
    }

    @Test
    func testUploadErrorTooLarge() async throws {
        model = Self.createModel(session: .init(returnErrorCode: HTTPStatus.payloadTooLarge.rawValue))
        model.grid.setAvatars([])

        await confirmation { confirmation in
            model.grid.$avatars.dropFirst(2).sink { avatars in
                #expect(avatars.count == 1, "Expect to be one avatar on the grid")
                let avatar = avatars.first!

                // Expect the avatar status to be Error (non retry-able)
                switch avatar.state {
                case .error(let supportsRetry, _):
                    #expect(!supportsRetry, "Image too large should not support retry")
                default:
                    #expect(Bool(false))
                }

                // Expect the image source to be local
                switch avatar.source {
                case .local: #expect(Bool(true))
                default: #expect(Bool(false))
                }

                #expect(avatar.localImage != nil, "Expect the local image to exist")
                confirmation.confirm()
            }.store(in: &cancellables)

            await model.upload(ImageHelper.exampleAvatarImage, shouldSquareImage: false)

            #expect(model.grid.avatars.count == 1)
        }
    }
}

final class URLSessionAvatarPickerMock: URLSessionProtocol {
    let returnErrorCode: Int?

    enum RequestType: String {
        case profiles
        case avatars
    }

    init(returnErrorCode: Int? = nil) {
        self.returnErrorCode = returnErrorCode
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if request.httpMethod == "POST" {
            if request.url?.absoluteString.contains(RequestType.avatars.rawValue) == true {
                return (Bundle.postAvatarSelectedJsonData, HTTPURLResponse.successResponse()) // Avatars data
            }
        }
        if request.url?.absoluteString.contains(RequestType.profiles.rawValue) == true {
            return (Bundle.fullProfileJsonData, HTTPURLResponse.successResponse()) // Profile data
        } else if request.url?.absoluteString.contains(RequestType.avatars.rawValue) == true {
            return (Bundle.getAvatarsJsonData, HTTPURLResponse.successResponse()) // Avatars data
        }
        fatalError("Request not mocked: \(request.url?.absoluteString ?? "unknown request")")
    }

    func upload(for request: URLRequest, from bodyData: Data) async throws -> (Data, URLResponse) {
        if let returnErrorCode {
            return ("".data(using: .utf8)!, HTTPURLResponse.errorResponse(code: returnErrorCode))
        }
        return (Bundle.postAvatarUploadJsonData, HTTPURLResponse.successResponse())
    }
}
