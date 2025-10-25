import Foundation

/// Manages debouncing and queuing of light color writes to prevent HomeKit request buildup.
///
/// This actor solves a common problem with HomeKit light control: when users interact with UI
/// controls (like color pickers or sliders), many write requests can be generated rapidly.
/// HomeKit queues all these requests and executes them sequentially, which can cause:
/// - Long delays before lights respond to the latest values
/// - Unnecessary network traffic to accessories
/// - Poor user experience as lights "catch up" to stale color values
///
/// ## How Debouncing Works
///
/// When you call `queueWrite(accessoryName:hue:saturation:brightness:execute:)`:
///
/// 1. **Cancellation**: Any existing pending write for the same accessory is immediately cancelled
/// 2. **Debounce Wait**: A timer starts (default 100ms) before the write executes
/// 3. **Cancellable Window**: If another write arrives during this window, step 1-2 repeat
/// 4. **Execute**: Once the debounce interval elapses without new writes, the operation executes
/// 5. **Latest Values Only**: Only the most recent color values are sent to HomeKit
///
/// Example timeline:
/// ```
/// Time:  0ms    50ms   100ms  150ms  200ms  250ms
/// Call:  ┬─────┬──────┬──────────────────────┬───────►
///        │     │      │                      │
///        │     │      │                      └─ Execute (only this one)
///        │     │      └─ Cancelled by next call
///        │     └─ Cancelled by next call
///        └─ Cancelled by next call
/// ```
///
/// ## Multi-Accessory Support
///
/// Each accessory has its own independent queue, so debouncing one light doesn't affect others:
/// ```swift
/// // These don't interfere with each other
/// let livingRoomWrite = await queue.queueWrite(accessoryName: "Living Room", ...)
/// let bedroomWrite = await queue.queueWrite(accessoryName: "Bedroom", ...)
/// _ = await livingRoomWrite.value
/// _ = await bedroomWrite.value
/// ```
///
/// ## Performance Characteristics
///
/// - **Memory**: O(n) where n = number of accessories with pending writes
/// - **Concurrency**: Actor-isolated, ensuring thread-safe access to pending writes
/// - **Latency**: Adds debounceInterval delay, but eliminates queue buildup
actor LightWriteQueue {
  /// Represents a pending write operation for an accessory
  private struct PendingWrite {
    let hue: Double
    let saturation: Double
    let brightness: Double
    let task: Task<Bool, Never>
  }

  private var pendingWrites: [String: PendingWrite] = [:]
  private let debounceInterval: Duration

  /// Creates a new light write queue with the specified debounce interval
  /// - Parameter debounceInterval: Time to wait before executing a write (default: 100ms)
  ///   - Shorter intervals (50-100ms): More responsive, but may send more requests
  ///   - Longer intervals (200-500ms): Fewer requests, but less responsive to user input
  init(debounceInterval: Duration = .milliseconds(100)) {
    self.debounceInterval = debounceInterval
  }

  /// Queue a light color write with automatic debouncing.
  ///
  /// This method ensures only the most recent color values are sent to HomeKit by cancelling
  /// any previous pending writes for the same accessory. The write is delayed by the debounce
  /// interval to allow additional calls to supersede it.
  ///
  /// - Parameters:
  ///   - accessoryName: The name of the accessory (used as the queue key)
  ///   - hue: Hue value (0-360)
  ///   - saturation: Saturation value (0-100)
  ///   - brightness: Brightness value (0-100)
  ///   - execute: The actual write operation to perform after debouncing
  /// - Returns: A task that completes with the write result once the debounce interval elapses
  func queueWrite(
    accessoryName: String,
    hue: Double,
    saturation: Double,
    brightness: Double,
    execute: @escaping @Sendable (Double, Double, Double) async -> Bool
  ) -> Task<Bool, Never> {
    // Cancel any existing pending write for this accessory
    if let existing = pendingWrites[accessoryName] {
      existing.task.cancel()
    }

    // Create a new debounced task
    let task = Task<Bool, Never> {
      do {
        try await Task.sleep(for: debounceInterval)
        guard !Task.isCancelled else { return false }
        return await execute(hue, saturation, brightness)
      } catch {
        return false
      }
    }

    // Store the pending write
    pendingWrites[accessoryName] = PendingWrite(
      hue: hue,
      saturation: saturation,
      brightness: brightness,
      task: task
    )

    Task { [weak self] in
      guard let self else { return }
      _ = await task.value
      await self.cleanup(accessoryName: accessoryName, task: task)
    }

    return task
  }

  /// Cancel all pending writes across all accessories.
  ///
  /// Use this when you need to immediately stop all in-flight operations,
  /// such as when the user navigates away from a control screen.
  func cancelAll() {
    for (_, pending) in pendingWrites {
      pending.task.cancel()
    }
    pendingWrites.removeAll()
  }

  /// Cancel pending write for a specific accessory.
  ///
  /// Use this when you want to stop updates to a specific light without
  /// affecting other accessories, such as when hiding a control for one light.
  ///
  /// - Parameter accessoryName: The name of the accessory to cancel writes for
  func cancel(accessoryName: String) {
    if let pending = pendingWrites[accessoryName] {
      pending.task.cancel()
      pendingWrites.removeValue(forKey: accessoryName)
    }
  }

  private func cleanup(accessoryName: String, task: Task<Bool, Never>) {
    if pendingWrites[accessoryName]?.task == task {
      pendingWrites.removeValue(forKey: accessoryName)
    }
  }
}
