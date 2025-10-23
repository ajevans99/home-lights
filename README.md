# home-lights

[![CI](https://github.com/ajevans99/home-lights/actions/workflows/ci.yml/badge.svg)](https://github.com/ajevans99/home-lights/actions/workflows/ci.yml)

HomeLights keeps my HomeKit lights and Nanoleaf Lines in sync so I can orchestrate scenes across platforms for a fun personal project.

## Features

- **HomeKit Discovery**: Discover and manage HomeKit homes, rooms, and accessories
- **Single Home View**: Display one home at a time with a menu to switch between homes (defaults to primary home)
- **Light Detail View**: Navigate to room detail pages that show only light accessories
- **JSON Storage**: Store and retrieve JSON objects on disk for caching and persistence

## Usage

### JSON Storage

Store and retrieve Codable objects as JSON on disk:

```swift
import HomeLights

// Create storage instance (uses Application Support directory by default)
let storage = try JSONStorage()

// Store an object
struct MyData: Codable {
  let name: String
  let value: Int
}

let data = MyData(name: "Test", value: 42)
try storage.store(data, filename: "mydata.json")

// Load it back
if let loaded = try storage.load(MyData.self, filename: "mydata.json") {
  print(loaded.name) // "Test"
}

// Check if file exists
if storage.exists(filename: "mydata.json") {
  print("File exists!")
}

// List all files
let files = try storage.listFiles()

// Delete a file
try storage.delete(filename: "mydata.json")
```
