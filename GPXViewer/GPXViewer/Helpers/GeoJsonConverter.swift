import MapKit

enum GeoJsonError: Error {
    case noGeometryDetected
    case notAPolyline
}

struct GeoJsonConverter {
  public func parseGeoJson(from data: Data) throws -> MKPolyline {
    let mapkitDecoder = MKGeoJSONDecoder()
    do {
      let geoJson = try mapkitDecoder.decode(data) as? [MKGeoJSONFeature]
      guard let geometry = geoJson?.first?.geometry.first else {
        throw GeoJsonError.noGeometryDetected
      }

      guard let polyline = geometry as? MKPolyline else {
        throw GeoJsonError.notAPolyline
      }
      return polyline
    }
  }
}
