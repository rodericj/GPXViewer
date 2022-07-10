import SwiftUI
import MapKit

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
