import Foundation
import Gravatar
import XCTest

/// GravatarService Unit Tests
///
class GravatarServiceTests: XCTestCase {
    class GravatarServiceRemoteMock: GravatarServiceRemote {
        var capturedAccountToken: String = ""
        var capturedAccountEmail: String = ""

        override func uploadImage(_ image: UIImage, accountEmail: String, accountToken: String, completion: ((NSError?) -> ())?) {
            capturedAccountEmail = accountEmail
            capturedAccountToken = accountToken

            if let completion = completion {
                completion(nil)
            }
        }

    }

    class GravatarServiceTester: GravatarService {
        var gravatarServiceRemoteMock: GravatarServiceRemoteMock?

        override func gravatarServiceRemote() -> GravatarServiceRemote {
            gravatarServiceRemoteMock = GravatarServiceRemoteMock()
            return gravatarServiceRemoteMock!
        }
    }

    func testServiceSanitizesEmailAddressCapitals() {
        let token = "1234"
        let emailAddress = "emAil@wordpress.com"

        let gravatarService = GravatarServiceTester()
        gravatarService.uploadImage(UIImage(), accountEmail: emailAddress, accountToken: token)

        XCTAssertEqual("email@wordpress.com", gravatarService.gravatarServiceRemoteMock!.capturedAccountEmail)
    }

    func testServiceSanitizesEmailAddressTrimsSpaces() {
        let token = "1234"
        let emailAddress = " email@wordpress.com "

        let gravatarService = GravatarServiceTester()
        gravatarService.uploadImage(UIImage(), accountEmail: emailAddress, accountToken: token)

        XCTAssertEqual("email@wordpress.com", gravatarService.gravatarServiceRemoteMock!.capturedAccountEmail)
    }
}
