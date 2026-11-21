import SwiftUI

enum Tab: String, CaseIterable {
  case general = "General"
  case behaviour = "Behaviour"
  case about = "About"
}

let steel = Color(hex: 0xD8DDE6)

/// Settings state shared by the Settings window and the menu bar controller.
@MainActor final class Model: ObservableObject {
  let defaults: UserDefaults
  @Published var prefs: Prefs {
    didSet {
      prefs.save(defaults)
      if prefs.autoHide != oldValue.autoHide { autoHideChanged() }
    }
  }
  @Published var hotKey: KitHotKey? {
    didSet {
      if let data = try? JSONEncoder().encode(Stored(key: hotKey)) { defaults.set(data, forKey: "shutter.hotkey") }
      hotKeyChanged()
    }
  }
  @Published var login = false
  @Published var tab = "General"
  var setLogin: (Bool) -> Void = { _ in }
  var showTip: () -> Void = {}
  var hotKeyChanged: () -> Void = {}
  var autoHideChanged: () -> Void = {}

  private struct Stored: Codable { var key: KitHotKey? }
  static let defaultHotKey = KitHotKey(keyCode: 4, modifiers: 1_835_008, display: "⌃⌥⌘H")   // ⌃⌥⌘H

  init(_ defaults: UserDefaults = .standard) {
    self.defaults = defaults
    prefs = Prefs.read(defaults)
    if let data = defaults.data(forKey: "shutter.hotkey"), let stored = try? JSONDecoder().decode(Stored.self, from: data) {
      hotKey = stored.key
    } else {
      hotKey = Model.defaultHotKey
    }
  }
}
