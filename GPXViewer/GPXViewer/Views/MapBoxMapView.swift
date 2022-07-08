
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
  private var mapView: MapView?
  private var mapkitView: MKMapView?
  private let track: Track
  private var source = GeoJSONSource()

  private let trackStore: ServiceDataSource
  private let delegate = MapViewDelegate()

  init(track: Track, trackStore: ServiceDataSource) {
    self.track = track
    self.trackStore = trackStore
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }


  private func parseGeoJson(from data: Data) {
    let mapkitDecoder = MKGeoJSONDecoder()
    do {
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
      let inset = 50.0
      let insets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
      mapkitView.setVisibleMapRect(mapRect, edgePadding: insets, animated: false)
    } catch {
      print("caught an error while parsing the data \(error)")
    }
  }
  private func loadGeoJSONLayer() throws {
    try trackStore.fetchGeojson(for: track) { data in
      switch data {
      case .success(let data):
#if USEMAPBOX // to utilize this set -DUSEMAPBOX in Build Settings called "Other Swift Flags" Under Swift Compiler Custom Flags
        self.parseGeoJsonForMapbox(from: data)
#else
        self.parseGeoJson(from: data)
#endif
      case .failure(let error):
        print("display error \(error)")
      }
    }
  }

  func parseGeoJsonForMapbox(from data: Data) {
    let decoder = JSONDecoder()
    do {
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
    } catch {
      print("error with mapbox data \(error)")
    }
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

#if USEMAPBOX
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
    map.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    self.view.addSubview(map)

#else // use Mapkit
    mapkitView = MKMapView(frame: view.bounds)
    mapkitView?.isScrollEnabled = false
    mapkitView?.delegate = delegate
    mapkitView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    self.view.addSubview(mapkitView!)
#endif

    do {
      try loadGeoJSONLayer()
    } catch {
      print("error occurred loading geojson \(error)")
    }

  }
}

enum LoadingError: Error {
  case invalidURL
  case noGeometryDetected
  case notAPolyline
}

extension MKGeoJSONFeature: ObservableObject {}

struct MapBoxMapView: UIViewControllerRepresentable {

  typealias UIViewControllerType = MapViewController
  private let trackStore: ServiceDataSource
  private let track: Track
  private let controller: MapViewController

  init(track: Track, trackStore: ServiceDataSource) {
    self.track = track
    self.trackStore = trackStore
    controller = MapViewController(track: track, trackStore: trackStore)
  }

  
  func makeUIViewController(context: Context) -> MapViewController {
    print("making a UIView")
    return controller
  }
  
  func updateUIViewController(_ uiViewController: MapViewController, context: Context) {
    print("update ui view \(context)")
  }
}
