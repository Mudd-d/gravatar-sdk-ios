import Foundation

/// An avatar that the user has already uploaded to their Gravatar account.
///
package struct Avatar: Codable, Hashable, Sendable {
    package enum Rating: String, Codable, CaseIterable, Sendable {
        case g = "G"
        case pg = "PG"
        case r = "R"
        case x = "X"
    }

    /// Unique identifier for the image.
    package private(set) var imageId: String
    /// Image URL
    package private(set) var imageUrl: String
    /// Rating associated with the image.
    package private(set) var rating: Rating
    /// Alternative text description of the image.
    package private(set) var altText: String
    /// Whether the image is currently selected as the provided selected email's avatar.
    package private(set) var selected: Bool?
    /// Date and time when the image was last updated.
    package private(set) var updatedDate: Date

    package init(imageId: String, imageUrl: String, rating: Rating, altText: String, selected: Bool? = nil, updatedDate: Date) {
        self.imageId = imageId
        self.imageUrl = imageUrl
        self.rating = rating
        self.altText = altText
        self.selected = selected
        self.updatedDate = updatedDate
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case imageId = "image_id"
        case imageUrl = "image_url"
        case rating
        case altText = "alt_text"
        case selected
        case updatedDate = "updated_date"
    }

    // Encodable protocol methods

    package func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(imageId, forKey: .imageId)
        try container.encode(imageUrl, forKey: .imageUrl)
        try container.encode(rating, forKey: .rating)
        try container.encode(altText, forKey: .altText)
        try container.encodeIfPresent(selected, forKey: .selected)
        try container.encode(updatedDate, forKey: .updatedDate)
    }
}
