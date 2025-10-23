import Foundation

/// Provides functionality to store and retrieve JSON objects on disk
public struct JSONStorage {
  private let fileManager: FileManager
  private let baseDirectory: URL

  /// Initialize with a specific directory, or use the application support directory by default
  public init(directory: URL? = nil) throws {
    self.fileManager = FileManager.default

    if let directory = directory {
      self.baseDirectory = directory
    } else {
      // Use Application Support directory
      guard
        let appSupport = fileManager.urls(
          for: .applicationSupportDirectory,
          in: .userDomainMask
        ).first
      else {
        throw JSONStorageError.directoryNotFound
      }

      let bundleID = Bundle.main.bundleIdentifier ?? "com.homelights"
      self.baseDirectory = appSupport.appendingPathComponent(bundleID)
    }

    // Create directory if it doesn't exist
    try fileManager.createDirectory(
      at: baseDirectory,
      withIntermediateDirectories: true,
      attributes: nil
    )
  }

  /// Store a Codable object as JSON to disk
  /// - Parameters:
  ///   - object: The object to store
  ///   - filename: The filename (without path) to store the object under
  public func store<T: Encodable>(_ object: T, filename: String) throws {
    let fileURL = baseDirectory.appendingPathComponent(filename)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    let data = try encoder.encode(object)
    try data.write(to: fileURL, options: .atomic)
  }

  /// Load a Codable object from disk
  /// - Parameters:
  ///   - type: The type to decode
  ///   - filename: The filename (without path) to load from
  /// - Returns: The decoded object, or nil if file doesn't exist
  public func load<T: Decodable>(_ type: T.Type, filename: String) throws -> T? {
    let fileURL = baseDirectory.appendingPathComponent(filename)

    guard fileManager.fileExists(atPath: fileURL.path) else {
      return nil
    }

    let data = try Data(contentsOf: fileURL)
    let decoder = JSONDecoder()
    return try decoder.decode(type, from: data)
  }

  /// Delete a stored object
  /// - Parameter filename: The filename to delete
  public func delete(filename: String) throws {
    let fileURL = baseDirectory.appendingPathComponent(filename)
    try fileManager.removeItem(at: fileURL)
  }

  /// Check if a file exists
  /// - Parameter filename: The filename to check
  /// - Returns: True if the file exists
  public func exists(filename: String) -> Bool {
    let fileURL = baseDirectory.appendingPathComponent(filename)
    return fileManager.fileExists(atPath: fileURL.path)
  }

  /// List all files in the storage directory
  /// - Returns: Array of filenames
  public func listFiles() throws -> [String] {
    let contents = try fileManager.contentsOfDirectory(
      at: baseDirectory,
      includingPropertiesForKeys: nil
    )
    return contents.map { $0.lastPathComponent }
  }
}

// MARK: - Errors

public enum JSONStorageError: Error {
  case directoryNotFound
  case encodingFailed
  case decodingFailed
  case fileNotFound
}
