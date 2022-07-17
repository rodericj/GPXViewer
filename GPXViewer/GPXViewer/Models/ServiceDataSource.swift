import DataFetch
import SwiftUI

enum LoadingError: Error { // TODO rename this to match the growing scope of the Service
    case invalidURL
    case noGeometryDetected
    case notAPolyline
    case invalidEmail
    case invalidPassword
    case invalidURLConfiguration
    case unableToConvertTobase64String
}

enum TrackState {
    case loaded([Track])
    case loading
    case error(Error)
}

struct ServiceConfig {
    let host: String
    let port: Int?
    let scheme: String
}
enum Service {
    case local
    case ngrok

    var url: URL? {
        var c = URLComponents()
        c.host = config.host
        c.scheme = config.scheme
        if let port = config.port {
            c.port = port
        }
        return c.url
    }
    var config: ServiceConfig {
        switch self {
        case .local:
            return ServiceConfig(host: "localhost", port: 8080, scheme: "http")
        case .ngrok:
            return ServiceConfig(host: "2d4a86bb2199.ngrok.io", port: nil, scheme: "https")
        }
    }
}

class ServiceDataSource: ObservableObject {
    static private let tokenKey = "gpxTrackUserToken"

    let service: Service = .ngrok

    private let keychain = KeychainManager()
    struct TracksPayload: Decodable {
        let items: [Track]
    }
    @Published var trackState: TrackState
    @Published var trackData: [UUID : Data] = [:]
    @Published var showingLoginSheet = true

    private let fetcher = DataFetcher()
    init() {
        trackState = .loading
    }

    func delete(atOffsets: IndexSet) {
        switch trackState {
        case .loaded(let array):
            do {
                try atOffsets.forEach { index in
                    let track = array[index]
                    guard let serviceURL = service.url else {
                        throw LoadingError.invalidURL
                    }
                    let url = serviceURL.appendingPathComponent("tracks").appendingPathComponent(track.id.uuidString)
                    try fetcher.delete(from: url) { result in
                        switch result {
                        case .success(let response):
                            print("successfully deleted, maybe delete this one from the array \(response)")
                            
                        case .failure(let error):
                            print("failed to delete, i show some kind of error i guess \(error)")
                        }
                    }
                }
            } catch {
                print("error \(error)")
            }
        case .loading:
            break
        case .error(let error):
            print("an error while deleting", error)
            break
        }
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

    func logout() {
        keychain.clear(key: ServiceDataSource.tokenKey)
    }
    func login(email: String?, password: String?) throws {
        guard let email = email else {
            throw LoadingError.invalidEmail
        }
        guard let password = password else {
            throw LoadingError.invalidPassword
        }
        guard let url = service.url?.appendingPathComponent("login") else {
            throw LoadingError.invalidURLConfiguration
        }

        struct Response: Codable {
            let value: String
            let user: User
            struct User: Codable {
                let id: UUID
            }
        }

        guard let base64EncodedParameters = "\(email.lowercased()):\(password)".data(using: .utf8)?.base64EncodedString() else {
            throw LoadingError.unableToConvertTobase64String
        }
        let headers: [String: String] = ["Authorization": "Basic  \(base64EncodedParameters)"]
        try fetcher.post(from: url, body: "", headers: headers, responseType: Response.self) { result in
            switch result {

            case .success(let loginResponseData):
                print("we got some data from login", loginResponseData.user.id, loginResponseData.value)
                // store the value in the keychain
                self.fetcher.bearerToken = ServiceDataSource.tokenKey
                self.keychain.set(value: loginResponseData.value, for: ServiceDataSource.tokenKey)
                DispatchQueue.main.async {
                    self.showingLoginSheet = false
                }
            case .failure(let error):
                print("error logging in \(error)")
            }
        }
    }
}
