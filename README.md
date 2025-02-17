# Gravatar
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FAutomattic%2FGravatar-SDK-iOS%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/Automattic/Gravatar-SDK-iOS) 
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FAutomattic%2FGravatar-SDK-iOS%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/Automattic/Gravatar-SDK-iOS)
[![License: MPL 2.0](https://img.shields.io/badge/License-MPL_2.0-brightgreen.svg)](https://opensource.org/licenses/MPL-2.0)


Gravatar SDK is a Swift library that allows you to integrate [Gravatar](https://gravatar.com/) features into your own iOS applications.

If you're also looking to integrate Gravatar in your Android app, check out our [Gravatar SDK for Android](https://github.com/Automattic/Gravatar-SDK-android)!

## Features

- Display a profile view or an avatar through ready-to-use UI components.
- Avatar URL calculator based on email and several [query options](https://docs.gravatar.com/general/images/).
- Avatar downloading based on email or url.
  - `UIImageView` extension to directly set the downloaded image.
  - SwiftUI Avatar component(`AvatarView`)
  - Built-in image cache (with the ability to inject your own cache).
- Avatar uploading to a [Gravatar](https://gravatar.com/) account.
- Gravatar profile fetching based on email.
- QuickEditor: This customizable sheet allows you to manage your avatar and Gravatar profile. You can select an existing avatar or upload a new one, and it provides a summary of your Gravatar profile.

## Installation

### Create an API key

Follow the steps in the [REST API documentation](https://docs.gravatar.com/api/profiles/rest-api/) to create a Gravatar API key. You can use some features without an API Key, but you’ll receive limited information, and stricter rate limits may apply, so we highly encourage you to create one in the [developer portal](https://gravatar.com/developers/).

For installation instructions and examples, see out [getting started](Sources/Gravatar/Gravatar.docc/1.%20GettingStarted.md) guide.

## Documentation

You can find some detailed articles, tutorials and API docs via these links:

- [Gravatar docs](https://automattic.github.io/Gravatar-SDK-iOS/gravatar/documentation/gravatar/)
- [GravatarUI docs](https://automattic.github.io/Gravatar-SDK-iOS/gravatarui/documentation/gravatarui/)

## Author

Gravatar

## Coding Style

Check out our [Coding Style guide](CODINGSTYLE.md).

## Contributing

Read our [Contributing Guide](CONTRIBUTING.md) to learn about reporting issues, contributing code, and more ways to contribute.

## License

Gravatar-SDK-iOS is an open source project covered by the [Mozilla Public License Version 2.0](LICENSE.md).
