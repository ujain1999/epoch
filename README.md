# 🌅 Epoch

**Epoch** is a macOS app for creating dynamic wallpapers that change with the time of day or based on the sun’s position (using EXIF metadata).  
Built with SwiftUI and native macOS APIs, Epoch empowers you to craft `.heic` dynamic wallpapers from your own images, with a clean and intuitive interface.

To learn more about how dynamic wallpapers work on MacOS, go to the [FAQ](https://dynamicwallpaper.club/faq) section of [dynamicwallpaper.club](https://dynamicwallpaper.club/).

![Epoch App Icon](./Epoch/AppIcon1024.png)

---

## ✨ Features

- 📷 Import your own images to create a dynamic wallpaper
- 🌓 Two modes:
  - **Time-based** — set specific times for each image
  - **Sun-based** — use EXIF date and GPS metadata to map to solar elevation
- 🌅 Exports a `.heic` file compatible with macOS Dynamic Desktop

---

## 🧰 Installation
### 🖥️ Pre-built
You can download a pre-built app from the [Releases](https://github.com/your-username/epoch/releases).

**macOS Gatekeeper Warning**

Because **Epoch** is an open–source app and is not signed or notarized, macOS will display a warning when you try to open it.
This is expected and does **not** mean the app is unsafe.
You can bypass this restriction in one of the following ways:

1. Use Right–Click → Open
2. Remove macOS quarantine flag 
```bash
xattr -dr com.apple.quarantine /Applications/Epoch.app
```

### 🛠️ Build from source
Clone the repo:

```bash
git clone https://github.com/your-username/epoch.git
cd epoch
```

Then open the project in Xcode:
```bash
open Epoch.xcodeproj
```

---

## 📖 Usage

1️⃣ Open the app  
2️⃣ Click **Select Images** and choose your wallpaper images  
3️⃣ Choose a mode:  
- **Time-based**: Set the time for each image  
- **Sun-based**: App reads EXIF date & GPS metadata for solar position  

4️⃣ Click **Export Dynamic Wallpaper** and save your `.heic` file  
5️⃣ Set it as your macOS desktop wallpaper via System Settings

---

## 👥 Contributing

Contributions are welcome!  
Feel free to:

- Open an issue for bugs or feature requests
- Submit a pull request
- Improve documentation
