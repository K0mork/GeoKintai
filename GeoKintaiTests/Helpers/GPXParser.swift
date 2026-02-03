import Foundation
import CoreLocation

/// GPXファイルを解析してCLLocationの配列に変換するヘルパー
final class GPXParser: NSObject, XMLParserDelegate {
    private var locations: [CLLocation] = []
    private var currentElement = ""
    private var currentLat: Double?
    private var currentLon: Double?
    private var currentTime: Date?
    private var currentText = ""

    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// GPXファイルからCLLocation配列を生成
    static func parse(contentsOf url: URL) -> [CLLocation] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        return parse(data: data)
    }

    /// GPXデータからCLLocation配列を生成
    static func parse(data: Data) -> [CLLocation] {
        let parser = GPXParser()
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = parser
        xmlParser.parse()
        return parser.locations
    }

    /// GPX文字列からCLLocation配列を生成
    static func parse(string: String) -> [CLLocation] {
        guard let data = string.data(using: .utf8) else { return [] }
        return parse(data: data)
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        currentText = ""

        if elementName == "wpt" || elementName == "trkpt" {
            if let latStr = attributeDict["lat"], let lat = Double(latStr) {
                currentLat = lat
            }
            if let lonStr = attributeDict["lon"], let lon = Double(lonStr) {
                currentLon = lon
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "time" {
            let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            currentTime = GPXParser.dateFormatter.date(from: trimmed)
        }

        if elementName == "wpt" || elementName == "trkpt" {
            if let lat = currentLat, let lon = currentLon {
                let timestamp = currentTime ?? Date()
                let location = CLLocation(
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    altitude: 0,
                    horizontalAccuracy: 5,
                    verticalAccuracy: 5,
                    timestamp: timestamp
                )
                locations.append(location)
            }
            currentLat = nil
            currentLon = nil
            currentTime = nil
        }
    }
}
