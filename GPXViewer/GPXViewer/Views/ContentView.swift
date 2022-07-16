//
//  ContentView.swift
//  GPXViewer
//
//  Created by Roderic Campbell on 6/27/22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        GPXTrackList()
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

struct ContentView_Previews: PreviewProvider {
    static let serviceDataSource: ServiceDataSource = {
        let serviceDataSource = ServiceDataSource()
        let track1 = Track(name: "test Track 1")
        let track2 = Track(name: "test Track 2")
        let tracks = [track1, track2]
        serviceDataSource.trackState = .loaded(tracks)
        return serviceDataSource
    }()

    static var previews: some View {
      ContentView().environmentObject(serviceDataSource)
    }
}
