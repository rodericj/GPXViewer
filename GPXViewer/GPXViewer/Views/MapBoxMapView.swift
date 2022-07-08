
import SwiftUI
import MapboxMaps
import MapKit


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

class MapViewDelegate: NSObject, MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    if let polyline = overlay as? MKPolyline {
      let renderer = MKPolylineRenderer(polyline: polyline)
      renderer.strokeColor = .red
      return renderer
    }
    return MKOverlayRenderer()
  }
}

class MapViewController: UIViewController {
  internal var mapView: MapView?
  internal var mapkitView: MKMapView?

  private let delegate = MapViewDelegate()

  init(track: Track) {
    self.track = track
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var track: Track
  var source = GeoJSONSource()

  func loadGeoJSONLayer() throws {

    guard let url = URL(string: "https://38e2dda5cbac.ngrok.io/tracks/\(track.id)/geojson") else {
      throw LoadingError.invalidURL
    }
    let data = try Data(contentsOf: url)

    let mapkitDecoder = MKGeoJSONDecoder()
    let geoJson = try mapkitDecoder.decode(data) as? [MKGeoJSONFeature]
    guard let geometry = geoJson?.first?.geometry.first else {
      throw LoadingError.noGeometryDetected
    }

    guard let polyline = geometry as? MKPolyline else {
      throw LoadingError.notAPolyline
    }
    guard let mapkitView = mapkitView else {
      return
    }
    mapkitView.addOverlay(polyline)
    guard let initial = mapkitView.overlays.first?.boundingMapRect else { return }
    let mapRect = mapkitView.overlays
            .dropFirst()
            .reduce(initial) { $0.union($1.boundingMapRect) }
    let inset = 20.0
    let insets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
    mapkitView.setVisibleMapRect(mapRect, edgePadding: insets, animated: false)

  }

  func loadGeoJSONLayerForMapBox() throws {

    guard let url = URL(string: "https://38e2dda5cbac.ngrok.io/tracks/\(track.id)/geojson") else {
      throw LoadingError.invalidURL
    }
    let data = try Data(contentsOf: url)
    let decoder = JSONDecoder()
    let json = try decoder.decode(GeoJsonResponse.self, from: data)

    guard let mapView = mapView else {
      return
    }

    let dataSet = json.features.first?.geometry.coordinates.map({ coords -> [CLLocationDegrees] in
      [CLLocationDegrees(coords.first!), CLLocationDegrees(coords.last!)]
    }).map({ coords -> LocationCoordinate2D in
      LocationCoordinate2D(latitude: coords.first!, longitude: coords.last!)
    })

    guard let dataSet = dataSet else {
      print("no data set")
      return
    }

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
    try mapView.mapboxMap.style.addLayer(lineLayer)
    if (mapView.mapboxMap.style.styleManager.isStyleLoaded()) {
      print("loaded")
    } else {
      print("not loaded")
    }

    try mapView.mapboxMap.style.addSource(source, id: sourceIDString)
    // Make the line layer
    // Specify a unique string as the layer ID (LAYER_ID)
    // and reference the source ID (SOURCE_ID) added above.
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    #if UseMapBox
    let myResourceOptions = ResourceOptions(accessToken: "pk.eyJ1Ijoicm9kZXJpYyIsImEiOiJja2t2ajNtMXMxZjdjMm9wNmYyZHR1ZWN3In0.mM6CghYW2Uil53LD5uQrGw")
    let centerLat = (track.maxLatitude + track.minLatitude) / 2
    let centerLong = (track.maxLongitude + track.minLongitude) / 2
    let cameraOptions = CameraOptions(
      center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLong),
      zoom: 9
    )

    let myMapInitOptions = MapInitOptions(resourceOptions: myResourceOptions, cameraOptions: cameraOptions,styleURI: StyleURI(rawValue: "mapbox://styles/roderic/cky3i85cgtk4q14udnw9kc69u"))

    let map = MapView(frame: view.bounds, mapInitOptions: myMapInitOptions)
    mapView = map

    do {
      try loadGeoJSONLayerForMapBox()
    } catch {
      print("error occurred loading geojson \(error)")
    }
    map.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    self.view.addSubview(map)

    #else // use Mapkit


    mapkitView = MKMapView(frame: view.bounds)
    mapkitView?.delegate = delegate
    mapkitView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    do {
      try loadGeoJSONLayer()
    } catch {
      print("error occurred loading geojson \(error)")
    }
    self.view.addSubview(mapkitView!)
    #endif
  }
}

enum LoadingError: Error {
  case invalidURL
  case noGeometryDetected
  case notAPolyline
}

struct MapBoxMapView: UIViewControllerRepresentable {
  
  typealias UIViewControllerType = MapViewController

  init(track: Track) {
    self.track = track
    controller = MapViewController(track: track)
    controller.track = track
  }

  let controller: MapViewController

  private let track: Track
  
  func makeUIViewController(context: Context) -> MapViewController {
    print("making a UIView")
    return controller
  }
  
  func updateUIViewController(_ uiViewController: MapViewController, context: Context) {
    print("update ui view \(context)")
  }
}
