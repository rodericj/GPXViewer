import DataFetch
import SwiftUI

enum ServiceError: Error {
    case invalidURL
    case missingName
    case invalidEmail
    case invalidPassword
    case invalidConfirmPassword
    case invalidURLConfiguration
    case passwordsMustMatch
    case unableToConvertTobase64String
}

enum TrackState {
    case loaded([Track])
    case loading
    case error(Error)

    func delete(track: Track) -> TrackState {
        let deletedTrack = track
        switch self {
        case .loaded(let tracks):
            return .loaded(tracks.filter({ track in
                deletedTrack != track
            }))
        default:
            return self
        }
    }
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
    struct LoginResponse: Codable {
        let value: String
        let user: User
        struct User: Codable {
            let id: UUID
        }
    }
    struct SignupResponseBody: Codable {
        let name: String
        let email: String
        let id: String
        let passwordHash: String
    }

    static private let tokenKey = "gpxTrackUserToken"

    let service: Service = .ngrok

    private let keychain = KeychainManager()
    struct TracksPayload: Decodable {
        let items: [Track]
    }
    @Published var trackState: TrackState
    @Published var trackData: [UUID : Data] = [:]
    @Published var showingLoginSheet: Bool
    @Published var hasAuthToken: Bool
    @Published var loginErrorString: String? = nil

    private let fetcher = DataFetcher()
    init() {
        trackState = .loading
        let token = keychain.value(for: ServiceDataSource.tokenKey)
        showingLoginSheet = token == nil
        hasAuthToken = token != nil
        fetcher.bearerToken = token
    }

    func delete(atOffsets: IndexSet) {
        switch trackState {
        case .loaded(let array):
            do {
                try atOffsets.forEach { index in
                    let track = array[index]
                    guard let serviceURL = service.url else {
                        throw ServiceError.invalidURL
                    }
                    let url = serviceURL.appendingPathComponent("tracks").appendingPathComponent(track.id.uuidString)
                    trackData[track.id] = nil
                    trackState = trackState.delete(track: track)
                    try fetcher.delete(from: url) { result in
                        switch result {
                        case .success(let response):
                            print("successfully deleted, maybe delete this one from the array \(response)")
                            
                        case .failure(let error):
                            print("failed to delete, i show some kind of error i guess \(error)")
                            self.fetch()
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
            throw ServiceError.invalidURL
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
        _ = keychain.clear(key: ServiceDataSource.tokenKey)
        hasAuthToken = false
        fetcher.bearerToken = nil
        fetcher.deleteCookie(named: "vapor-session")
    }

    func signUp(name: String?, email: String?, password: String?, confirmPassword: String?) throws {
        guard let name = name else {
            throw ServiceError.missingName
        }

        guard let email = email else {
            throw ServiceError.invalidEmail
        }
        guard let password = password else {
            throw ServiceError.invalidPassword
        }
        guard let confirmPassword = confirmPassword else {
            throw ServiceError.invalidConfirmPassword
        }
        guard password == confirmPassword else {
            throw ServiceError.passwordsMustMatch
        }

        guard let url = service.url?.appendingPathComponent("users") else {
            throw ServiceError.invalidURLConfiguration
        }

        struct SignupBody: Codable {
            let name: String
            let email: String
            let password: String
            let confirmPassword: String
        }

        let body = SignupBody(
            name: name,
            email: email,
            password: password,
            confirmPassword: confirmPassword
        )
        try fetcher.post(from: url, body: body, responseType: SignupResponseBody.self) { result in
            switch result {

            case .success(let response):
                print("successfully created a user")
                self.handle(response: response)
                // TODO show the login view now
            case .failure(let error):
                print("we got an error signing up \(error)")
                if case FetchError.badRequest(let string) = error {
                    DispatchQueue.main.async {
                        self.loginErrorString = string
                    }
                }
            }
        }
    }

    private func handle(response: LoginResponse) {
        self.fetcher.bearerToken = response.value
        self.hasAuthToken = true
        _ = self.keychain.set(value: response.value, for: ServiceDataSource.tokenKey)
        DispatchQueue.main.async {
            self.showingLoginSheet = false
        }
    }

    private func handle(response: SignupResponseBody) {
        print("do we need to check the cookies or something? ")
    }

    func login(email: String?, password: String?) throws {
        guard let email = email else {
            throw ServiceError.invalidEmail
        }
        guard let password = password else {
            throw ServiceError.invalidPassword
        }
        guard let url = service.url?.appendingPathComponent("login") else {
            throw ServiceError.invalidURLConfiguration
        }

        guard let base64EncodedParameters = "\(email.lowercased()):\(password)".data(using: .utf8)?.base64EncodedString() else {
            throw ServiceError.unableToConvertTobase64String
        }
        let headers: [String: String] = ["Authorization": "Basic  \(base64EncodedParameters)"]
        try fetcher.post(from: url, body: "", headers: headers, responseType: LoginResponse.self) { result in
            switch result {

            case .success(let loginResponseData):
                print("we got some data from login", loginResponseData.user.id, loginResponseData.value)
                // store the value in the keychain
                self.handle(response: loginResponseData)
            case .failure(let error):
                print("error logging in \(error)")
            }
        }
    }
}
