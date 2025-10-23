import Foundation
import Testing

@testable import HomeLights

struct JSONStorageTests {
  struct TestData: Codable, Equatable {
    let name: String
    let value: Int
  }

  @Test func storeAndLoadObject() async throws {
    // Create a temporary directory for testing
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(
      UUID().uuidString
    )

    let storage = try JSONStorage(directory: tempDir)

    let testData = TestData(name: "Test", value: 42)

    // Store the object
    try storage.store(testData, filename: "test.json")

    // Load it back
    let loaded = try storage.load(TestData.self, filename: "test.json")

    #expect(loaded == testData)

    // Cleanup
    try? FileManager.default.removeItem(at: tempDir)
  }

  @Test func loadNonexistentFile() async throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(
      UUID().uuidString
    )

    let storage = try JSONStorage(directory: tempDir)

    let loaded = try storage.load(TestData.self, filename: "nonexistent.json")

    #expect(loaded == nil)

    // Cleanup
    try? FileManager.default.removeItem(at: tempDir)
  }

  @Test func deleteFile() async throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(
      UUID().uuidString
    )

    let storage = try JSONStorage(directory: tempDir)

    let testData = TestData(name: "Test", value: 42)

    // Store the object
    try storage.store(testData, filename: "test.json")

    #expect(storage.exists(filename: "test.json"))

    // Delete it
    try storage.delete(filename: "test.json")

    #expect(!storage.exists(filename: "test.json"))

    // Cleanup
    try? FileManager.default.removeItem(at: tempDir)
  }

  @Test func listFiles() async throws {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(
      UUID().uuidString
    )

    let storage = try JSONStorage(directory: tempDir)

    let testData = TestData(name: "Test", value: 42)

    // Store multiple files
    try storage.store(testData, filename: "test1.json")
    try storage.store(testData, filename: "test2.json")

    let files = try storage.listFiles()

    #expect(files.contains("test1.json"))
    #expect(files.contains("test2.json"))
    #expect(files.count == 2)

    // Cleanup
    try? FileManager.default.removeItem(at: tempDir)
  }
}
