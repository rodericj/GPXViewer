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
        switch(trackStore.trackState) {
        case .loaded(let tracks):
            List(tracks) { track in
                ForEach(tracks, id: \.self) { track in
                    TrackRow(track: track)
                        .cornerRadius(10)
                }.onDelete(perform: trackStore.delete)

            }
        case .loading:
            Text("Loading")
        case .error(let error):
            Text("Error loading \(error.localizedDescription)")
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
        let tracks = [track1, track2]
        serviceDataSource.trackState = .loaded(tracks)
        return serviceDataSource
    }()
    static var previews: some View {
        GPXTrackList().environmentObject(serviceDataSource)
    }
}

