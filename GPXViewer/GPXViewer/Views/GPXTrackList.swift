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
  @Published var trackData: [UUID : Data] = [:]

  private let fetcher = DataFetcher()
  init() {
    tracks = []
  }

  func fetchGeojson(for track: Track, completion: @escaping (Result<Data, Error>) -> ()) throws {
    guard let url = URL(string: "http://localhost:8080/tracks/\(track.id)/geojson") else {
      throw LoadingError.invalidURL
    }

    if let cachedData = trackData[track.id] {
      completion(.success(cachedData))
      return
    }
    
    fetcher.fetch(from: url) { result in
      switch result {
      case .success(let data):
        print("successfully got data \(data.count)")
        DispatchQueue.main.async {
          self.trackData[track.id] = data
        }
      case .failure(let error):
        print("failed with error \(error)")
      }
      completion(result)
    }
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
  @EnvironmentObject var trackStore: ServiceDataSource
  
  var body: some View {
    List(trackStore.tracks) { track in
      TrackRow(track: track)
        .cornerRadius(10)
    }
  }
}

extension Track {
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

