import MapKit

extension MKMapView {
  func add(polyline: MKPolyline) {
    addOverlay(polyline)
    guard let initial = overlays.first?.boundingMapRect else { return }
    let mapRect = overlays
      .dropFirst()
      .reduce(initial) { $0.union($1.boundingMapRect) }
    let inset = 50.0
    let insets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
    setVisibleMapRect(mapRect, edgePadding: insets, animated: false)
  }
}
