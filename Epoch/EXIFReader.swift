import Foundation
import ImageIO

struct EXIFData {
    let dateTime: Date?
    let latitude: Double?
    let longitude: Double?
}

func readEXIFData(from url: URL) -> EXIFData {
    guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
          let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] else {
        return EXIFData(dateTime: nil, latitude: nil, longitude: nil)
    }

    var dateTime: Date? = nil
    var latitude: Double? = nil
    var longitude: Double? = nil

    if let exifDict = metadata[kCGImagePropertyExifDictionary] as? [CFString: Any],
       let dateTimeString = exifDict[kCGImagePropertyExifDateTimeOriginal] as? String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        dateTime = formatter.date(from: dateTimeString)
    }

    if let gpsDict = metadata[kCGImagePropertyGPSDictionary] as? [CFString: Any] {
        if let lat = gpsDict[kCGImagePropertyGPSLatitude] as? Double,
           let latRef = gpsDict[kCGImagePropertyGPSLatitudeRef] as? String {
            latitude = (latRef == "S") ? -lat : lat
        }
        if let lon = gpsDict[kCGImagePropertyGPSLongitude] as? Double,
           let lonRef = gpsDict[kCGImagePropertyGPSLongitudeRef] as? String {
            longitude = (lonRef == "W") ? -lon : lon
        }
    }

    return EXIFData(dateTime: dateTime, latitude: latitude, longitude: longitude)
}
