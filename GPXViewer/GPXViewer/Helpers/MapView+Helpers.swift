#if USEMAPBOX

import MapboxMaps

extension MapView {
  func parseGeoJsonForMapbox(from data: Data) {
    let decoder = JSONDecoder()
    do {
      let json = try decoder.decode(GeoJsonResponse.self, from: data)

      let dataSet = json.features.first?.geometry.coordinates.map({ coords -> [CLLocationDegrees] in
        [CLLocationDegrees(coords.first!), CLLocationDegrees(coords.last!)]
      }).map({ coords -> LocationCoordinate2D in
        LocationCoordinate2D(latitude: coords.first!, longitude: coords.last!)
      })

      guard let dataSet = dataSet else {
        print("no data set")
        return
      }
      var source = GeoJSONSource()

      let lineString = LineString(dataSet)
      source.data = .geometry(.lineString(lineString))

      // Add the source to the mapView
      // Specify a unique string as the source ID (SOURCE_ID)
      // and reference the location of source data
      let sourceIDString = UUID().uuidString
      let layerIDString = UUID().uuidString

      var lineLayer = LineLayer(id: layerIDString)

      lineLayer.source = sourceIDString

      // Add the line layer to the mapView
      try mapboxMap.style.addLayer(lineLayer)
      if (mapboxMap.style.styleManager.isStyleLoaded()) {
        print("loaded")
      } else {
        print("not loaded")
      }

      try mapboxMap.style.addSource(source, id: sourceIDString)
      // Make the line layer
      // Specify a unique string as the layer ID (LAYER_ID)
      // and reference the source ID (SOURCE_ID) added above.
    } catch {
      print("error with mapbox data \(error)")
    }
  }
}

struct GeoJsonResponse: Codable {
  struct Feature: Codable {
    struct Geometry: Codable {
      var type: String = "LineString"
      let coordinates: [[Double]]
    }
    var type: String = "Feature"
    let geometry: Geometry
  }
  var type: String = "FeatureCollection"
  let features: [Feature]
}
#endif
