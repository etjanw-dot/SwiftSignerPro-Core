//
//  WallpaperManager.swift
//  Ksign
//
//  Manager for custom wallpaper operations with PosterBoard/Nugget integration.
//

#if os(iOS)
    import Foundation
    import ZIPFoundation
    import UIKit

    // MARK: - Apply Error
    enum WallpaperApplyError: Error, LocalizedError {
        case wrongAppHash
        case collectionsNeedsReset
        case unexpected(info: String)

        var errorDescription: String? {
            switch self {
            case .wrongAppHash:
                return .localized("The app hash is incorrect. Please re-detect using Nugget.")
            case .collectionsNeedsReset:
                return .localized("Collections need to be reset. Use the Reset Collections button.")
            case .unexpected(let info):
                return info
            }
        }
    }

    class WallpaperManager: ObservableObject {
        static let ShortcutURL = "https://www.icloud.com/shortcuts/a28d2c02ca11453cb5b8f91c12cfa692"
        static let WallpapersURL = "https://cowabun.ga/wallpapers"

        static let MaxTendies = 10

        static let shared = WallpaperManager()

        @Published var selectedTendies: [URL] = []
        @Published var posterBoardHash: String = ""
        @Published var isApplying: Bool = false
        @Published var applyProgress: String = ""

        private let hashKey = "Ksign.wallpaper.pbHash"

        init() {
            loadHash()
        }

        // MARK: - Hash Management

        func loadHash() {
            posterBoardHash = UserDefaults.standard.string(forKey: hashKey) ?? ""
        }

        func saveHash(_ hash: String) {
            posterBoardHash = hash
            UserDefaults.standard.set(hash, forKey: hashKey)
        }

        // MARK: - URL Helpers

        func getTendiesStoreURL() -> URL {
            let tendiesStoreURL = WallpaperSymHandler.getDocumentsDirectory()
                .appendingPathComponent("KFC Bucket", conformingTo: .directory)
            // create it if it doesn't exist
            if !FileManager.default.fileExists(atPath: tendiesStoreURL.path) {
                try? FileManager.default.createDirectory(
                    at: tendiesStoreURL, withIntermediateDirectories: true)
            }
            return tendiesStoreURL
        }

        // MARK: - System Functions

        func setSystemLanguage(to new_lang: String) -> Bool {
            var langManager: NSObject = NSObject()
            if #available(iOS 18.0, *) {
                guard let obj = objc_getClass("IPSettingsUtilities") as? NSObject else {
                    return false
                }
                langManager = obj
            } else {
                guard let obj = objc_getClass("PSLanguageSelector") as? NSObject else {
                    return false
                }
                langManager = obj
            }

            if let success = langManager.perform(Selector(("setLanguage:")), with: new_lang) {
                return success != nil
            }

            return false
        }

        func openPosterBoard() -> Bool {
            guard let obj = objc_getClass("LSApplicationWorkspace") as? NSObject else {
                return false
            }
            let workspace =
                obj.perform(Selector(("defaultWorkspace")))?.takeUnretainedValue() as? NSObject

            if let success = workspace?.perform(
                Selector(("openApplicationWithBundleID:")), with: "com.apple.PosterBoard")
            {
                return success != nil
            }

            return false
        }

        // MARK: - Tendie Operations

        private func unzipFile(at url: URL) throws -> URL {
            let fileName = url.deletingPathExtension().lastPathComponent
            let fileData = try Data(contentsOf: url)
            let fileManager = FileManager()

            // Write the file to the Documents Directory
            let path = WallpaperSymHandler.getDocumentsDirectory().appendingPathComponent(
                "UnzipItems", conformingTo: .directory
            ).appendingPathComponent(UUID().uuidString)
            if !FileManager.default.fileExists(atPath: path.path) {
                try? FileManager.default.createDirectory(
                    at: path, withIntermediateDirectories: true)
            }
            let url = path.appending(path: fileName)

            // Remove All files in this directory
            let existingFiles = try FileManager.default.contentsOfDirectory(
                at: path, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for fileUrl in existingFiles {
                try FileManager.default.removeItem(at: fileUrl)
            }

            // Save our Zip file
            try fileData.write(to: url, options: [.atomic])

            // Unzip the Zipped Up File
            var destinationURL = path
            if FileManager.default.fileExists(atPath: url.path) {
                destinationURL.append(path: "directory")
                try fileManager.unzipItem(at: url, to: destinationURL)
            }

            return destinationURL
        }

        func runShortcut(named name: String) {
            guard
                let urlEncodedName = name.addingPercentEncoding(
                    withAllowedCharacters: .urlQueryAllowed),
                let url = URL(string: "shortcuts://run-shortcut?name=\(name)")
            else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }

        func getDescriptorsFromTendie(_ url: URL) throws -> [String: [URL]]? {
            for dir in try FileManager.default.contentsOfDirectory(
                at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            {
                let fileName = dir.lastPathComponent
                if fileName.lowercased() == "container" {
                    // container support, find the extensions
                    let extDir = dir.appending(
                        path:
                            "Library/Application Support/PRBPosterExtensionDataStore/61/Extensions")
                    var retList: [String: [URL]] = [:]
                    for ext in try FileManager.default.contentsOfDirectory(
                        at: extDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                    {
                        let descrDir = ext.appendingPathComponent("descriptors")
                        retList[ext.lastPathComponent] = [descrDir]
                    }
                    return retList
                } else if fileName.lowercased() == "descriptor"
                    || fileName.lowercased() == "descriptors"
                    || fileName.lowercased() == "ordered-descriptor"
                    || fileName.lowercased() == "ordered-descriptors"
                {
                    return ["com.apple.WallpaperKit.CollectionsPoster": [dir]]
                } else if fileName.lowercased() == "video-descriptor"
                    || fileName.lowercased() == "video-descriptors"
                {
                    return ["com.apple.PhotosUIPrivate.PhotosPosterProvider": [dir]]
                }
            }
            return nil
        }

        func randomizeWallpaperId(url: URL) throws {
            let randomizedID = Int.random(in: 9999...99999)
            var files = [URL]()
            if let enumerator = FileManager.default.enumerator(
                at: url, includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants])
            {
                for case let fileURL as URL in enumerator {
                    do {
                        let fileAttributes = try fileURL.resourceValues(forKeys: [.isRegularFileKey]
                        )
                        if fileAttributes.isRegularFile! {
                            files.append(fileURL)
                        }
                    } catch {
                        print(error, fileURL)
                    }
                }
            }

            func setPlistValue(file: String, key: String, value: Any, recursive: Bool = true) {
                guard let plistData = FileManager.default.contents(atPath: file),
                    var plist = try? PropertyListSerialization.propertyList(
                        from: plistData, options: [], format: nil) as? [String: Any]
                else {
                    return
                }

                plist[key] = value

                guard
                    let updatedData = try? PropertyListSerialization.data(
                        fromPropertyList: plist, format: .xml, options: 0)
                else {
                    return
                }

                do {
                    try updatedData.write(to: URL(fileURLWithPath: file))
                } catch {
                    print("Failed to write updated plist: \(error)")
                }
            }

            for file in files {
                switch file.lastPathComponent {
                case "com.apple.posterkit.provider.descriptor.identifier":
                    try String(randomizedID).data(using: .utf8)?.write(to: file)

                case "com.apple.posterkit.provider.contents.userInfo":
                    setPlistValue(
                        file: file.path, key: "wallpaperRepresentingIdentifier", value: randomizedID
                    )

                case "Wallpaper.plist":
                    setPlistValue(
                        file: file.path, key: "identifier", value: randomizedID, recursive: false)

                default:
                    continue
                }
            }
        }

        // MARK: - Apply Tendies

        func applyTendies() async throws {
            guard !posterBoardHash.isEmpty else {
                throw WallpaperApplyError.wrongAppHash
            }

            await MainActor.run {
                isApplying = true
                applyProgress = .localized("Extracting tendies...")
            }

            defer {
                WallpaperSymHandler.cleanup()
                Task { @MainActor in
                    isApplying = false
                }
            }

            // organize the descriptors into their respective extensions
            var extList: [String: [URL]] = [:]

            for url in selectedTendies {
                let unzippedDir = try unzipFile(at: url)
                guard let descriptors = try getDescriptorsFromTendie(unzippedDir) else { continue }
                extList.merge(descriptors) { (first, second) in first + second }
            }

            for (ext, descriptorsList) in extList {
                let _ = try WallpaperSymHandler.createDescriptorsSymlink(
                    appHash: posterBoardHash, ext: ext)
                for descriptors in descriptorsList {
                    for descr in try FileManager.default.contentsOfDirectory(
                        at: descriptors, includingPropertiesForKeys: nil, options: .skipsHiddenFiles
                    ) {
                        if descr.lastPathComponent != "__MACOSX" {
                            try randomizeWallpaperId(url: descr)
                            let newURL = WallpaperSymHandler.getDocumentsDirectory()
                                .appendingPathComponent(UUID().uuidString, conformingTo: .directory)
                            try FileManager.default.moveItem(at: descr, to: newURL)

                            try FileManager.default.trashItem(at: newURL, resultingItemURL: nil)
                        }
                    }
                }
                WallpaperSymHandler.cleanup()
            }

            // clean up all possible files
            for url in selectedTendies {
                try? FileManager.default.removeItem(
                    at: WallpaperSymHandler.getDocumentsDirectory().appendingPathComponent(
                        "UnzipItems", conformingTo: .directory))
                try? FileManager.default.removeItem(
                    at: WallpaperSymHandler.getDocumentsDirectory().appendingPathComponent(
                        url.lastPathComponent))
                try? FileManager.default.removeItem(
                    at: WallpaperSymHandler.getDocumentsDirectory().appendingPathComponent(
                        url.deletingPathExtension().lastPathComponent))
            }

            await MainActor.run {
                selectedTendies.removeAll()
            }
        }

        static func clearCache() throws {
            WallpaperSymHandler.cleanup()
            let docDir = WallpaperSymHandler.getDocumentsDirectory()
            for file in try FileManager.default.contentsOfDirectory(
                at: docDir, includingPropertiesForKeys: nil)
            {
                if file.lastPathComponent == "KFC Bucket" || file.lastPathComponent == "UnzipItems"
                {
                    try FileManager.default.removeItem(at: file)
                }
            }
        }

        // MARK: - Remove Selected Tendie

        func removeTendie(at offsets: IndexSet) {
            selectedTendies.remove(atOffsets: offsets)
        }
    }
#endif
