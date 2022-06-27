import CoreLocation
import Foundation
import SwiftUI

enum TrackError: Error {
  case invalidID
  case endDate
  case startDate
}
private extension DateFormatter {
  static let iso8601Full: DateFormatter = {
     let formatter = DateFormatter()
     formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
     formatter.calendar = Calendar(identifier: .iso8601)
     formatter.timeZone = TimeZone(secondsFromGMT: 0)
     formatter.locale = Locale(identifier: "en_US_POSIX")
     return formatter
   }()
}
struct Track: Hashable, Codable, Identifiable {

  var id: UUID

  //    var points: [Point]
  var title: String
  var maxLatitude: Double
  var maxLongitude: Double
  var minLatitude: Double
  var minLongitude: Double
  var startDate: Date
  var endDate: Date

  init(from decoder: Decoder) throws {

    let container = try decoder.container(keyedBy: CodingKeys.self)
    guard let contentID = UUID(uuidString: try container.decode(String.self, forKey: .id)) else {
      throw TrackError.invalidID
    }
    id = contentID

    let startDateString = try container.decode(String.self, forKey: .startDate)
    let endDateString = try container.decode(String.self, forKey: .endDate)

    let formatter = DateFormatter.iso8601Full
    guard let start = formatter.date(from: startDateString) else {
      throw TrackError.startDate
    }
    guard let end = formatter.date(from: endDateString) else {
      throw TrackError.endDate
    }

    startDate = start
    endDate = end
    
    title = try container.decode(String.self, forKey: .title)
    maxLatitude = try container.decode(Double.self, forKey: .maxLatitude)
    maxLongitude = try container.decode(Double.self, forKey: .maxLongitude)
    minLatitude = try container.decode(Double.self, forKey: .minLatitude)
    minLongitude = try container.decode(Double.self, forKey: .minLongitude)
  }

  // Ok actually we want other coordinates
  //  private var coordinates: Coordinates
  //  var locationCoordinate: CLLocationCoordinate2D {
  //      CLLocationCoordinate2D(
  //          latitude: coordinates.latitude,
  //          longitude: coordinates.longitude)
  //  }
  //  struct Coordinates: Hashable, Codable {
  //    var latitude: Double
  //    var longitude: Double
  //  }
}
