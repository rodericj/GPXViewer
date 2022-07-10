#if USEMAPBOX
import MapboxMaps
#else
import MapKit
#endif

class MapViewController: UIViewController {
#if USEMAPBOX
  private var mapView: MapView?
#else
  private var mapkitView: MKMapView?
#endif
  private let track: Track

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

  let converter = GeoJsonConverter()

    private func loadGeoJSONLayer() throws {
        try trackStore.fetchGeojson(for: track) { data in
            DispatchQueue.main.async {
                switch data {
                case .success(let data):
#if USEMAPBOX // to utilize this set -DUSEMAPBOX in Build Settings called "Other Swift Flags" Under Swift Compiler Custom Flags
                    self.mapView?.parseGeoJsonForMapbox(from: data)
#else
                    do {
                        let polyline = try self.converter.parseGeoJson(from: data)
                        self.mapkitView?.add(polyline: polyline)
                    } catch {
                        print("unable to convert geojson to polyline")
                    }
#endif
                case .failure(let error):
                    print("display error \(error)")
                }
            }
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
