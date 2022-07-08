import MapKit

struct GeoJsonConverter {
  public func parseGeoJson(from data: Data) throws -> MKPolyline {
    let mapkitDecoder = MKGeoJSONDecoder()
    do {
      let geoJson = try mapkitDecoder.decode(data) as? [MKGeoJSONFeature]
      guard let geometry = geoJson?.first?.geometry.first else {
        throw LoadingError.noGeometryDetected
      }

      guard let polyline = geometry as? MKPolyline else {
        throw LoadingError.notAPolyline
      }
      return polyline
    }
  }
}
