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

struct ServiceConfig {
    let host: String// = "localhost"
    let port: Int// = 8080
    let scheme: String// = "http"
}
enum Service {
    case local
    case ngrok

    var url: URL? {
        var c = URLComponents()
        c.host = config.host
        c.scheme = config.scheme
        c.port = config.port
        return c.url
    }
    var config: ServiceConfig {
        switch self {
        case .local:
            return ServiceConfig(host: "localhost", port: 8080, scheme: "http")
        case .ngrok:
            return ServiceConfig(host: "38e2dda5cbac.ngrok.io", port: 80, scheme: "https")
        }
    }
}

class ServiceDataSource: ObservableObject {
    let service: Service = .local

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
        guard let url = service.url?.appendingPathComponent("tracks/\(track.id)/geojson") else {
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
        guard let url = service.url else {
            return
        }

        print(url.appendingPathComponent("tracks"))
        fetcher.fetch(from: url.appendingPathComponent("tracks"), type: TracksPayload.self) { tracks in
            DispatchQueue.main.async {
                switch tracks {

                case .success(let payload):
                    self.trackState = .loaded(payload.items)

                case .failure(let error):
                    self.trackState = .error(error)
                    print("error \(error)")
                }
            }
        }
    }
}
