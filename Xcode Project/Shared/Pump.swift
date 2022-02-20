import Foundation
import Combine

class Pump: ObservableObject {
    @Published var clientConfigurationID = ""
    @Published var working: Bool = false
    @Published var requesting: Bool = false
    private static let coolDownTime: TimeInterval = 20
    @Published var coolDownTimeRemaining: TimeInterval = 0
    private var cancellables: [CancellableKey: AnyCancellable] = [:]
    @Published var countSuccesses = 0
    @Published var countFailures = 0
    
    enum CancellableKey {
        case request
        case coolDownTimer
    }
    
    func start() {
        guard UUID(uuidString: clientConfigurationID) != nil else { return }
        
        iCloudKeyValueStorage.set(key: .clientConfigurationID, value: self.clientConfigurationID)
        
        self.cancellables[.coolDownTimer]?.cancel()
        
        self.working = true
        self.requesting = true
        
        self.cancellables[.request] = self.pumpData()
            .sink { completion in
                DispatchQueue.main.async { self.requesting = false }
                
                switch completion {
                case .failure(_): DispatchQueue.main.async { self.countFailures += 1 }
                default: break
                }
                
                DispatchQueue.main.async { self.coolDownTimeRemaining = Self.coolDownTime }
                self.cancellables[.coolDownTimer] = Timer.publish(every: 1, on: .main, in: .default).autoconnect().sink { _ in
                    if self.coolDownTimeRemaining <= 0 {
                        self.coolDownTimeRemaining = 0
                        self.start()
                    } else {
                        self.coolDownTimeRemaining -= 1
                    }
                        
                }
            } receiveValue: { data, response in
                if (response as? HTTPURLResponse)?.statusCode == 200 {
                    DispatchQueue.main.async { self.countSuccesses += 1 }
                } else {
                    DispatchQueue.main.async { self.countFailures += 1 }
                }
            }
    }
    
    func stop() {
        self.working = false
        self.requesting = false
        self.cancellables.keys.forEach { key in
            self.cancellables[key]?.cancel()
        }
    }
    
    private func pumpData() -> URLSession.DataTaskPublisher {
        let installID = Self.randomAlphanumericString(length: 22)
        var request = URLRequest(url: Self.registerURL)
        request.httpMethod = "POST"
        request.httpBody = """
            {"key": "\(Self.randomAlphanumericString(length: 43))=", "install_id": "\(installID)", "fcm_token": "\(installID):APA91b\(Self.randomAlphanumericString(length: 134))", "referrer": "\(self.clientConfigurationID)", "warp_enabled": false, "tos": "\(Self.timeString)", "type": "Android", "locale": "es_ES"}
            """.data(using: .utf8)
        request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue("okhttp/3.12.1", forHTTPHeaderField: "User-Agent")
        HTTPCookieStorage.shared.removeCookies(since: .distantPast)
        return URLSession.shared.dataTaskPublisher(for: request)
    }
    
    private static func randomAlphanumericString(length: Int) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
    
    private static func randomNumericString(length: Int) -> String {
        let characters = "0123456789"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
    
    private static var timeString: String {
        var dateComponents = Calendar.autoupdatingCurrent.dateComponents(in: .autoupdatingCurrent, from: .now)
        dateComponents.timeZone = .init(secondsFromGMT: 0)!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS"
        return "\(dateFormatter.string(from: dateComponents.date!))+00:00"
    }
    
    private static let registerURL = URL(string: "https://api.cloudflareclient.com/v0a\(Pump.randomNumericString(length: 3))/reg")!
}
