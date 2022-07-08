//
//  GPXTrackList.swift
//  GPXViewer
//
//  Created by Roderic Campbell on 6/27/22.
//

import SwiftUI

struct GPXTrackList: View {
  @EnvironmentObject var trackStore: ServiceDataSource
  
  var body: some View {
    List(trackStore.tracks) { track in
      TrackRow(track: track)
        .cornerRadius(10)
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
struct GPXTrackList_Previews: PreviewProvider {
  static let serviceDataSource: ServiceDataSource = {
    let serviceDataSource = ServiceDataSource()
    let track1 = Track(name: "test Track 1")
    let track2 = Track(name: "test Track 2")
    serviceDataSource.tracks.append(track1)
    serviceDataSource.tracks.append(track2)
    return serviceDataSource
  }()
  static var previews: some View {
    GPXTrackList().environmentObject(serviceDataSource)
  }
}

