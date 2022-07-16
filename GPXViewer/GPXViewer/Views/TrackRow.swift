//
//  TrackRow.swift
//  GPXViewer
//
//  Created by Roderic Campbell on 6/27/22.
//

import SwiftUI
import MapKit

extension Track {
  var dateDescription: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: startDate)
  }
}

struct TrackRow: View {
    var track: Track
    @EnvironmentObject var trackStore: ServiceDataSource
    var body: some View {
        VStack {
            HStack {
                Text(track.title)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            HStack {
                Text(track.dateDescription).font(.body)
                Spacer()
            }
            MapBoxMapView(
                track: track,
                trackStore: trackStore
            )
            .frame(width: nil, height: 300, alignment: .center)
        }
    }
}

private extension Track {
    init(name: String) {
        self.title = name
        self.maxLatitude = 0
        self.minLatitude = 0
        self.maxLongitude = 0
        self.minLongitude = 0
        self.id = UUID()
        self.startDate = Date()
        self.endDate = Date()
    }
}

struct TrackRow_Previews: PreviewProvider {
    static let serviceDataSource: ServiceDataSource = {
        let serviceDataSource = ServiceDataSource()
        let track1 = Track(name: "test Track 1")
        let track2 = Track(name: "test Track 2")
        let tracks = [track1, track2]
        serviceDataSource.trackState = .loaded(tracks)
        return serviceDataSource
    }()

    static var previews: some View {
        TrackRow(track: Track())
            .environmentObject(serviceDataSource)
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

