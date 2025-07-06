import Foundation
import AppKit
import ImageIO
import UniformTypeIdentifiers
import AVFoundation

func exportDynamicWallpaperFile(to outputURL: URL,
                                 images: [ImageWithTime],
                                 mode: WallpaperMode) throws {
    guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL,
                                                             AVFileType.heic as CFString,
                                                             images.count,
                                                             nil) else {
        throw NSError(domain: "Epoch", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create HEIC destination"])
    }

    for imageWithTime in images {
        print("📷 Loading image: \(imageWithTime.url.path)")
        guard let nsImage = NSImage(contentsOf: imageWithTime.url) else {
            print("⚠️ Skipping: Failed to load NSImage from \(imageWithTime.url.path)")
            continue
        }
        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("⚠️ Skipping: Failed to convert NSImage to CGImage for \(imageWithTime.url.path)")
            continue
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
    }

    if !CGImageDestinationFinalize(destination) {
        throw NSError(domain: "Epoch", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to finalize HEIC file"])
    }

    let plistData = createDesktopPlist(images: images, mode: mode)
    try embedPlist(plistData, to: outputURL)
}

private func createDesktopPlist(images: [ImageWithTime], mode: WallpaperMode) -> Data {
    var array: [[String: Any]] = []

    for (index, image) in images.enumerated() {
        switch mode {
        case .timeBased:
            let components = Calendar.current.dateComponents([.hour, .minute], from: image.time)
            let hour = components.hour ?? 0
            let minute = components.minute ?? 0
            array.append([
                "image": index,
                "time": String(format: "%02d:%02d", hour, minute)
            ])
        case .sunBased:
            if let exif = image.exifData,
               let lat = exif.latitude,
               let lon = exif.longitude,
               let date = exif.dateTime {
                let elevation = SolarCalculator.solarElevation(for: date, latitude: lat, longitude: lon)
                array.append([
                    "image": index,
                    "solar-elevation": elevation
                ])
            }
        }
    }

    let plist: [String: Any] = [
        mode == .timeBased ? "time" : "solar": array
    ]

    return try! PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
}

private func embedPlist(_ plistData: Data, to fileURL: URL) throws {
    let task = Process()
    task.launchPath = "/usr/bin/xattr"
    task.arguments = ["-w", "com.apple.desktop.plist", plistData.base64EncodedString(), fileURL.path]
    task.launch()
    task.waitUntilExit()
}
