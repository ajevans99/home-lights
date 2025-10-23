import Testing

@testable import HomeLights

struct HomeLightsTests {
  @Test("greet returns greeting for provided name")
  func greet() async throws {
    let sut = HomeLights()
    #expect(sut.greet(name: "World") == "Hello, World!")
  }
}
