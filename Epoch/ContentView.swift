import SwiftUI

enum WallpaperMode: String, CaseIterable, Identifiable {
    case timeBased = "Time-based"
    case sunBased = "Sun-based (EXIF)"
    
    var id: String { self.rawValue }
}

struct ImageWithTime: Identifiable {
    let id = UUID()
    let url: URL
    var time: Date
    var exifData: EXIFData? = nil
    var hasAccess: Bool = false
}

struct ContentView: View {
    @State private var selectedImages: [ImageWithTime] = []
    @State private var isShowingFilePicker = false
    @State private var selectedMode: WallpaperMode = .timeBased

    var allImagesHaveEXIF: Bool {
        selectedImages.allSatisfy { image in
            if let exif = image.exifData {
                return exif.dateTime != nil && exif.latitude != nil && exif.longitude != nil
            }
            return false
        }
    }

    var imagesMissingEXIF: [ImageWithTime] {
        selectedImages.filter { image in
            guard let exif = image.exifData else { return true }
            return exif.dateTime == nil || exif.latitude == nil || exif.longitude == nil
        }
    }

    /// sorted reactive bindings for the UI
    var sortedImageBindings: [Binding<ImageWithTime>] {
        $selectedImages.sorted { $0.wrappedValue.time < $1.wrappedValue.time }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Epoch — Dynamic Wallpaper Creator")
                .font(.title)
                .padding()

            Button("Select Images") {
                isShowingFilePicker = true
            }
            .padding()

            if !selectedImages.isEmpty {
                Text("Select Mode")
                    .font(.headline)

                Picker("Mode", selection: $selectedMode) {
                    ForEach(WallpaperMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
            }

            if selectedMode == .sunBased && !selectedImages.isEmpty {
                HStack {
                    Image(systemName: allImagesHaveEXIF ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(allImagesHaveEXIF ? .green : .yellow)
                    Text(allImagesHaveEXIF
                         ? "All images have EXIF date & GPS data"
                         : "Some images are missing EXIF date or GPS")
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)

                if !allImagesHaveEXIF {
                    Text("Missing EXIF in:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ForEach(imagesMissingEXIF) { image in
                        Text(image.url.lastPathComponent)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }

            if selectedMode == .timeBased && !selectedImages.isEmpty {
                Text("Enter the time for each image:")
                    .font(.headline)

                List {
                    ForEach(sortedImageBindings) { $imageWithTime in
                        HStack {
                            if let nsImage = NSImage(contentsOf: imageWithTime.url) {
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .clipped()
                            }

                            Text(imageWithTime.url.lastPathComponent)
                                .frame(width: 200, alignment: .leading)

                            DatePicker(
                                "",
                                selection: $imageWithTime.time,
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()

                            Spacer()

                            Button(action: {
                                removeImage(imageWithTime.id)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        .padding(.vertical, 4)
                    }
                }
                .frame(height: 300)
            }

            if selectedMode == .sunBased && !selectedImages.isEmpty {
                Text("EXIF Data and Solar Elevation for each image:")
                    .font(.headline)

                List {
                    ForEach(selectedImages) { image in
                        VStack(alignment: .leading) {
                            Text(image.url.lastPathComponent)
                                .font(.headline)

                            if let exif = image.exifData,
                               let lat = exif.latitude,
                               let lon = exif.longitude,
                               let date = exif.dateTime {
                                let elevation = SolarCalculator.solarElevation(for: date, latitude: lat, longitude: lon)
                                Text(date.formatted())
                                Text(String(format: "GPS: %.4f, %.4f", lat, lon))
                                Text(String(format: "Solar Elevation: %.2f°", elevation))
                            } else {
                                Text("No EXIF or GPS data")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .frame(height: 300)
            }

            Spacer()

            if !selectedImages.isEmpty {
                Button("Export Dynamic Wallpaper") {
                    exportDynamicWallpaper()
                }
                .disabled(selectedMode == .sunBased && !allImagesHaveEXIF)
                .padding()
            }
        }
        .padding()
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                selectedImages = []
                for url in urls {
                    var hasAccess = false
                    if url.startAccessingSecurityScopedResource() {
                        hasAccess = true
                        print("✅ Gained access to \(url.path)")
                    } else {
                        print("❌ Failed to access \(url.path)")
                    }
                    let exif = readEXIFData(from: url)
                    selectedImages.append(ImageWithTime(url: url, time: Date(), exifData: exif, hasAccess: hasAccess))
                }
            case .failure(let error):
                print("Error selecting files: \(error.localizedDescription)")
            }
        }
    }

    func removeImage(_ id: UUID) {
        if let index = selectedImages.firstIndex(where: { $0.id == id }) {
            let image = selectedImages[index]
            if image.hasAccess {
                image.url.stopAccessingSecurityScopedResource()
                print("🔷 Stopped access to \(image.url.path)")
            }
            selectedImages.remove(at: index)
        }
    }

    func exportDynamicWallpaper() {
        DispatchQueue.main.async {
            #if os(macOS)
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.heic]
            savePanel.nameFieldStringValue = "Epoch-DynamicWallpaper.heic"
            savePanel.directoryURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first

            savePanel.begin { response in
                defer {
                    for image in selectedImages where image.hasAccess {
                        image.url.stopAccessingSecurityScopedResource()
                        print("🔷 Stopped access to \(image.url.path)")
                    }
                }

                if response == .OK, let url = savePanel.url {
                    do {
                        let sortedImages = selectedImages.sorted { $0.time < $1.time }
                        try exportDynamicWallpaperFile(to: url,
                                                       images: sortedImages,
                                                       mode: selectedMode)
                        print("✅ Successfully exported to \(url.path)")
                    } catch {
                        print("❌ Failed to export: \(error.localizedDescription)")
                    }
                } else {
                    print("ℹ️ Export cancelled by user.")
                }
            }
            #else
            print("❌ This feature is only available on macOS.")
            #endif
        }
    }
}
