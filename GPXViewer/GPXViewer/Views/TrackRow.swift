//
//  TrackRow.swift
//  GPXViewer
//
//  Created by Roderic Campbell on 6/27/22.
//

import SwiftUI
import MapKit

struct TrackRow: View {
  var track: Track
  @EnvironmentObject var trackStore: ServiceDataSource
  var body: some View {
    VStack {
      Text(track.title)
        .padding()
        .frame(alignment: .leading)
      MapBoxMapView(track: track, trackStore: trackStore)
        .frame(width: nil, height: 300, alignment: .center)
    }
  }
}

struct TrackRow_Previews: PreviewProvider {
  static var previews: some View {
    TrackRow(track: Track())
  }
}

private extension Track {
  init() {
    title = "Test Track"
    minLatitude = 33.901176
    minLongitude = -118.496633
    maxLatitude = 33.980299000000002
    maxLongitude = -118.442296
    startDate = Date()
    endDate = Date()
    id = UUID(uuidString: "6D75554D-58D9-47B7-BA4C-447E566D7EB4")!
  }
}

extension Track {
  static var testTrack: Track {
    Track()
  }
}
