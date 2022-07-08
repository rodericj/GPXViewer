//
//  GPXTrackList.swift
//  GPXViewer
//
//  Created by Roderic Campbell on 6/27/22.
//

import SwiftUI
import DataFetch

class ServiceDataSource: ObservableObject {
  struct TracksPayload: Decodable {
    let items: [Track]
  }
  @Published var tracks: [Track]
  
  private let fetcher = DataFetcher()
  init() {
    tracks = []
  }
  
  func fetch() {
    guard let url = URL(string: "http://localhost:8080/tracks") else {
      return
    }
    fetcher.fetch(from: url, type: TracksPayload.self) { tracks in
      switch tracks {
        
      case .success(let payload):
        DispatchQueue.main.async {
          self.tracks = payload.items
        }
      case .failure(let error):
        print("error \(error)")
      }
    }
  }
}

struct GPXTrackList: View {
  @ObservedObject var trackStore: ServiceDataSource
  
  var body: some View {
    List(trackStore.tracks) { track in
      TrackRow(track: track)
    }
  }
}

struct GPXTrackList_Previews: PreviewProvider {
  static var previews: some View {
    GPXTrackList(trackStore: ServiceDataSource())
  }
}

