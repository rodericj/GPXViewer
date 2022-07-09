import DataFetch
import SwiftUI

enum LoadingError: Error {
  case invalidURL
  case noGeometryDetected
  case notAPolyline
}

enum TrackState {
    case loaded([Track])
    case loading
    case error(Error)
}
class ServiceDataSource: ObservableObject {
  struct TracksPayload: Decodable {
    let items: [Track]
  }
  @Published var trackState: TrackState
  @Published var trackData: [UUID : Data] = [:]

  private let fetcher = DataFetcher()
  init() {
      trackState = .loading
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
            self.trackState = .loaded(payload.items)
        }
      case .failure(let error):
          self.trackState = .error(error)
        print("error \(error)")
      }
    }
  }
}
