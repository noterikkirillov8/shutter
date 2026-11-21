import CoreGraphics
import Foundation

/// Saved settings. `autoHide` is seconds, 0 = never hide again by itself.
struct Prefs: Codable, Equatable {
  var autoHide = 8
  var hideOnStart = false
  var tipSeen = false
  var showOnHover = true
  static let key = "shutter.prefs"
  static func read(_ defaults: UserDefaults) -> Prefs {
    guard let data = defaults.data(forKey: key), var prefs = try? JSONDecoder().decode(Prefs.self, from: data)
    else { return Prefs() }
    prefs.autoHide = min(60, max(0, prefs.autoHide))
    return prefs
  }
  func save(_ defaults: UserDefaults) {
    if let data = try? JSONEncoder().encode(self) { defaults.set(data, forKey: Prefs.key) }
  }
  /// First run always starts shown, so nothing disappears before the user has seen the tip.
  var startsHidden: Bool { hideOnStart && tipSeen }
}

extension Prefs {
  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    autoHide = try values.decode(Int.self, forKey: .autoHide)
    hideOnStart = try values.decode(Bool.self, forKey: .hideOnStart)
    tipSeen = try values.decode(Bool.self, forKey: .tipSeen)
    showOnHover = try values.decodeIfPresent(Bool.self, forKey: .showOnHover) ?? true
  }
}

/// Shown / hidden plus the auto-hide countdown. Time is passed in, so it tests without a clock.
struct Shelf: Equatable {
  private(set) var hidden: Bool
  private(set) var deadline: TimeInterval?
  init(hidden: Bool = false) { self.hidden = hidden }

  mutating func needsAutoHideTimer(autoHide: Int) -> Bool {
    guard autoHide > 0 else { deadline = nil; return false }
    return !hidden
  }

  mutating func show(now: TimeInterval, autoHide: Int) {
    hidden = false
    deadline = autoHide > 0 ? now + Double(autoHide) : nil
  }
  mutating func hoverShow(now: TimeInterval, autoHide: Int, enabled: Bool) -> Bool {
    guard hidden, enabled else { return false }
    show(now: now, autoHide: autoHide)
    return true
  }
  @discardableResult mutating func hide(allowed: Bool = true) -> Bool {
    deadline = nil
    guard allowed else { return false }
    hidden = true
    return true
  }
  mutating func toggle(now: TimeInterval, autoHide: Int) {
    if hidden { show(now: now, autoHide: autoHide) } else { hide() }
  }
  /// Call about twice a second. While `busy` (pointer in the menu bar, a menu open) the countdown restarts.
  /// Returns true when it just hid.
  mutating func tick(now: TimeInterval, autoHide: Int, busy: Bool, canHide: Bool = true) -> Bool {
    guard !hidden else { return false }
    guard autoHide > 0 else { deadline = nil; return false }
    guard let due = deadline else { deadline = now + Double(autoHide); return false }
    if busy { deadline = now + Double(autoHide); return false }
    guard now >= due else { return false }
    return hide(allowed: canHide)
  }
  /// Quitting always leaves the divider at normal width.
  mutating func quit() {
    hidden = false
    deadline = nil
  }
}

/// Checks that keep Shutter's own icon from being pushed off the screen.
enum Safety {
  /// Hiding widens the divider, which pushes everything left of it away. Shutter's icon must be right of it.
  static func canHide(dividerMinX: CGFloat?, iconMinX: CGFloat?) -> Bool {
    guard let dividerMinX, let iconMinX else { return false }
    return dividerMinX < iconMinX
  }
  /// After hiding: the icon must still be on a screen, otherwise show everything again.
  static func iconVisible(_ icon: CGRect?, screens: [CGRect]) -> Bool {
    guard let icon, icon.width > 0 else { return false }
    return screens.contains { $0.contains(CGPoint(x: icon.midX, y: icon.midY)) }
  }
  static let hiddenLength: CGFloat = 10000
}
