import Gravatar
import XCTest

final class UserProfileTests: XCTestCase {
    private let url = URL(string: "http://a-url.com")!

    private enum Profile: String {
        case fullProfileWithBoolsAsStrings = "FullProfileWithBoolsAsStrings"
        case fullProfileWithNativeBools = "FullProfileWithNativeBools"
        case emptyProfile = "EmptyProfile"
    }

    func testComprehensiveUserProfileWithBoolsAsStrings() async throws {
        let json = try json(for: .fullProfileWithBoolsAsStrings)

        let urlSession = URLSessionMock(returnData: json, response: HTTPURLResponse())
        let client = HTTPClientMock(session: urlSession)
        let profileService = ProfileService(client: client)

        let profile = try await profileService.fetchProfile(with: URLRequest(url: url))
        XCTAssertNotNil(profile)
        expectEqual(output: profile.hash, assertion: TestProfile.FullProfile.hash)
        expectEqual(output: profile.requestHash, assertion: TestProfile.FullProfile.requestHash)
        expectEqual(output: profile.profileUrl, assertion: TestProfile.FullProfile.profileUrl)
        expectEqual(output: profile.preferredUsername, assertion: TestProfile.FullProfile.preferredUsername)
        expectEqual(output: profile.thumbnailUrl, assertion: TestProfile.FullProfile.thumbnailUrl)
        XCTAssertNotNil(profile.lastProfileEditDate)
        expectEqual(output: profile.lastProfileEditDate, assertion: TestProfile.FullProfile.lastProfileEditDate)
        expectEqual(output: profile.displayName, assertion: TestProfile.FullProfile.displayName)
        expectEqual(output: profile.pronouns, assertion: TestProfile.FullProfile.pronouns)
        expectEqual(output: profile.aboutMe, assertion: TestProfile.FullProfile.aboutMe)
        expectEqual(output: profile.photos, assertion: TestProfile.FullProfile.photos)
        expectEqual(output: profile.emails, assertion: TestProfile.FullProfile.emailsStringBool, asBool: false)
        expectEqual(output: profile.accounts, assertion: TestProfile.FullProfile.accountsStringBool, asBool: false)
        expectEqual(output: profile.urls, assertion: TestProfile.FullProfile.linkUrls)
    }

    func testComprehensiveUserProfileWithNativeBools() async throws {
        let json = try json(for: .fullProfileWithNativeBools)

        let urlSession = URLSessionMock(returnData: json, response: HTTPURLResponse())
        let client = HTTPClientMock(session: urlSession)
        let profileService = ProfileService(client: client)

        let profile = try await profileService.fetchProfile(with: URLRequest(url: url))
        XCTAssertNotNil(profile)
        expectEqual(output: profile.hash, assertion: TestProfile.FullProfile.hash)
        expectEqual(output: profile.requestHash, assertion: TestProfile.FullProfile.requestHash)
        expectEqual(output: profile.profileUrl, assertion: TestProfile.FullProfile.profileUrl)
        expectEqual(output: profile.preferredUsername, assertion: TestProfile.FullProfile.preferredUsername)
        expectEqual(output: profile.thumbnailUrl, assertion: TestProfile.FullProfile.thumbnailUrl)
        XCTAssertNotNil(profile.lastProfileEditDate)
        expectEqual(output: profile.lastProfileEditDate, assertion: TestProfile.FullProfile.lastProfileEditDate)
        expectEqual(output: profile.displayName, assertion: TestProfile.FullProfile.displayName)
        expectEqual(output: profile.pronouns, assertion: TestProfile.FullProfile.pronouns)
        expectEqual(output: profile.aboutMe, assertion: TestProfile.FullProfile.aboutMe)
        expectEqual(output: profile.photos, assertion: TestProfile.FullProfile.photos)
        expectEqual(output: profile.emails, assertion: TestProfile.FullProfile.emailsNativeBool, asBool: true)
        expectEqual(output: profile.accounts, assertion: TestProfile.FullProfile.accountsNativeBool, asBool: true)
        expectEqual(output: profile.urls, assertion: TestProfile.FullProfile.linkUrls)
    }

    func testEmptyProfile() async throws {
        let json = try json(for: .emptyProfile)

        let urlSession = URLSessionMock(returnData: json, response: HTTPURLResponse())
        let client = HTTPClientMock(session: urlSession)
        let profileService = ProfileService(client: client)

        let profile = try await profileService.fetchProfile(with: URLRequest(url: url))
        XCTAssertNotNil(profile)

        expectEqual(output: profile.hash, assertion: TestProfile.EmptyProfile.hash)
        expectEqual(output: profile.requestHash, assertion: TestProfile.EmptyProfile.requestHash)
        expectEqual(output: profile.profileUrl, assertion: TestProfile.EmptyProfile.profileUrl)
        expectEqual(output: profile.preferredUsername, assertion: TestProfile.EmptyProfile.preferredUsername)
        expectEqual(output: profile.thumbnailUrl, assertion: TestProfile.EmptyProfile.thumbnailUrl)
        XCTAssertNotNil(profile.lastProfileEditDate)
        expectEqual(output: profile.lastProfileEditDate, assertion: TestProfile.EmptyProfile.lastProfileEditDate)
        expectEqual(output: profile.displayName, assertion: TestProfile.EmptyProfile.displayName)
        expectEqual(output: profile.photos, assertion: TestProfile.EmptyProfile.photos)
        expectEqual(output: profile.urls, assertion: TestProfile.EmptyProfile.linkUrls)
    }
}

// MARK: - Helpers

extension UserProfileTests {
    private enum UserProfileTestError: Error {
        case profileNotFound
    }

    private func json(for profile: Profile) throws -> Data {
        guard let url = Bundle.gravatarTestsBundle.url(forResource: profile.rawValue, withExtension: "json") else {
            throw UserProfileTestError.profileNotFound
        }

        return try Data(contentsOf: url)
    }

    private func expectEqual<T: Equatable>(
        output: T,
        assertion: T,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(output, assertion, file: file, line: line)
    }

    private func expectEqual(
        output: [UserProfile.Photo],
        assertion: [TestProfile.ProfilePhoto],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(output.count, assertion.count, file: file, line: line)
        for (index, photo) in output.enumerated() {
            XCTAssertEqual(photo.value, assertion[index]["value"], file: file, line: line)
            XCTAssertEqual(photo.type, assertion[index]["type"], file: file, line: line)
        }
    }

    private func expectEqual(
        output: [UserProfile.Email]?,
        assertion: [TestProfile.ProfileEmail],
        asBool: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let output else {
            XCTFail("UserProfile.Email should not be nil", file: file, line: line)
            return
        }

        XCTAssertEqual(output.count, assertion.count)
        for (index, photo) in output.enumerated() {
            XCTAssertEqual(photo.value, assertion[index]["value"] as? String, file: file, line: line)
            if asBool {
                XCTAssertEqual(photo.isPrimary, assertion[index]["primary"] as? Bool, file: file, line: line)
            } else {
                XCTAssertEqual(String(photo.isPrimary), assertion[index]["primary"] as? String, file: file, line: line)
            }
        }
    }

    private func expectEqual(
        output: [UserProfile.Account]?,
        assertion: [TestProfile.ProfileAccount],
        asBool: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let output else {
            XCTFail("UserProfile.Account should not be nil")
            return
        }

        XCTAssertEqual(output.count, assertion.count)
        for (index, account) in output.enumerated() {
            XCTAssertEqual(account.domain, assertion[index]["domain"] as? String, file: file, line: line)
            XCTAssertEqual(account.display, assertion[index]["display"] as? String, file: file, line: line)
            XCTAssertEqual(account.url, assertion[index]["url"] as? String, file: file, line: line)
            XCTAssertEqual(account.iconUrl, assertion[index]["iconUrl"] as? String, file: file, line: line)
            XCTAssertEqual(account.username, assertion[index]["username"] as? String, file: file, line: line)
            XCTAssertEqual(account.name, assertion[index]["name"] as? String, file: file, line: line)
            XCTAssertEqual(account.shortname, assertion[index]["shortname"] as? String, file: file, line: line)

            if asBool {
                XCTAssertEqual(account.isVerified, assertion[index]["verified"] as? Bool, file: file, line: line)
            } else {
                XCTAssertEqual(
                    String(account.isVerified),
                    assertion[index]["verified"] as? String,
                    "Account '\(account.name)' should be '\(account.isVerified)",
                    file: file,
                    line: line
                )
            }
        }
    }

    private func expectEqual(
        output: [UserProfile.LinkURL]?,
        assertion: [TestProfile.ProfileLinkURL],
        asBool: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let output else {
            XCTFail("UserProfile.Account should not be nil")
            return
        }

        XCTAssertEqual(output.count, assertion.count)
        for (index, url) in output.enumerated() {
            XCTAssertEqual(url.value, assertion[index]["value"], file: file, line: line)
            XCTAssertEqual(url.title, assertion[index]["title"], file: file, line: line)
        }
    }
}

// MARK: - HTTPClient

private struct HTTPClientMock: HTTPClient {
    private let session: URLSessionMock

    init(session: URLSessionMock) {
        self.session = session
    }

    func fetchData(with request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        (session.returnData, session.response)
    }

    func uploadData(with request: URLRequest, data: Data) async throws -> HTTPURLResponse {
        session.response
    }
}

// MARK: - TestProfile

private enum TestProfile {
    typealias ProfileName = [String: String]
    typealias ProfileLinkURL = [String: String]
    typealias ProfilePhoto = [String: String]
    typealias ProfileEmail = [String: any Codable]
    typealias ProfileAccount = [String: any Codable]

    enum FullProfile {
        static let hash: String = "fake_hash"
        static let requestHash: String = "fake_requestHash"
        static let preferredUsername: String = "fake_preferredUsername"
        static let displayName: String = "fake_displayName"
        static let profileUrl: String = "https://fake_profileUrl.com"
        static let thumbnailUrl: String = "https://1.gravatar.com/avatar/ca38d22ece4e8f592db7cd75764e5a52"
        static let pronouns: String = "they/them/their"
        static let aboutMe: String = "fake biography"
        static let lastProfileEdit: String = "2023-12-01 20:25:10"
        static var lastProfileEditDate: Date? {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return formatter.date(from: lastProfileEdit)
        }

        static let photos: [ProfilePhoto] = [
            [
                "value": "https://1.gravatar.com/avatar/ca38d22ece4e8f592db7cd75764e5a52",
                "type": "thumbnail",
            ],
            [
                "value": "https://1.gravatar.com/userimage/12108442/e453d707d347ff4e0b475f15d2df99ef",
            ],
        ]

        static let emailsStringBool: [ProfileEmail] = [
            [
                "primary": "true",
                "value": "email@example.com",
            ],
        ]

        static let emailsNativeBool: [ProfileEmail] = [
            [
                "primary": true,
                "value": "email@example.com",
            ],
        ]

        static let accountsStringBool: [ProfileAccount] = [
            [
                "domain": "fake_domain.com",
                "display": "fake_domain.com",
                "url": "https://fake_domain.com",
                "iconUrl": "https://fake_domain.com/icon.jpg",
                "username": "fake_username",
                "verified": "true",
                "name": "WordPress",
                "shortname": "wordpress",
            ],
            [
                "domain": "twitter.com",
                "display": "@fakeuser",
                "url": "https://twitter.com/noone",
                "iconUrl": "https://secure.gravatar.com/icons/twitter-alt.svg",
                "username": "fakeuser",
                "verified": "true",
                "name": "Twitter",
                "shortname": "twitter",
            ],
            [
                "domain": "mastodon.social",
                "display": "@fakeuser@https://mastodon.social",
                "url": "https://mastodon.social/@fakeuser",
                "iconUrl": "https://secure.gravatar.com/icons/mastodonsocial.svg",
                "username": "fakeuser",
                "verified": "true",
                "name": "Mastodon",
                "shortname": "mastodonsocial",
            ],
        ]

        static let accountsNativeBool: [ProfileAccount] = [
            [
                "domain": "fake_domain.com",
                "display": "fake_domain.com",
                "url": "https://fake_domain.com",
                "iconUrl": "https://fake_domain.com/icon.jpg",
                "username": "fake_username",
                "verified": true,
                "name": "WordPress",
                "shortname": "wordpress",
            ],
            [
                "domain": "twitter.com",
                "display": "@fakeuser",
                "url": "https://twitter.com/noone",
                "iconUrl": "https://secure.gravatar.com/icons/twitter-alt.svg",
                "username": "fakeuser",
                "verified": true,
                "name": "Twitter",
                "shortname": "twitter",
            ],
            [
                "domain": "mastodon.social",
                "display": "@fakeuser@https://mastodon.social",
                "url": "https://mastodon.social/@fakeuser",
                "iconUrl": "https://secure.gravatar.com/icons/mastodonsocial.svg",
                "username": "fakeuser",
                "verified": true,
                "name": "Mastodon",
                "shortname": "mastodonsocial",
            ],
        ]

        static let linkUrls: [ProfileLinkURL] = [
            [
                "value": "https://fake_url.com",
                "title": "fake_title",
            ],
        ]
    }

    enum EmptyProfile {
        static let hash: String = "fake_hash"
        static let requestHash: String = "fake_requestHash"
        static let preferredUsername: String = "fake_preferredUsername"
        static let displayName: String = "fake_displayName"
        static let profileUrl: String = "https://fake_profileUrl.com"
        static let thumbnailUrl: String = "https://1.gravatar.com/avatar/ca38d22ece4e8f592db7cd75764e5a52"
        static let lastProfileEdit: String = "2023-12-01 20:25:10"
        static var lastProfileEditDate: Date? {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return formatter.date(from: lastProfileEdit)
        }

        static let photos: [ProfilePhoto] = [
            [
                "value": "https://1.gravatar.com/avatar/ca38d22ece4e8f592db7cd75764e5a52",
                "type": "thumbnail",
            ],
        ]

        static let linkUrls: [ProfileLinkURL] = []
    }
}
