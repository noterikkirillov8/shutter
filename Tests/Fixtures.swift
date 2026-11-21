import CoreGraphics
import Foundation

@main struct FixtureTests {
  static func main() {
    var count = 0
    func check(_ label: String, _ result: Bool) {
      guard result else {
        print("FAIL  \(label)")
        exit(1)
      }
      count += 1
      print("PASS  \(label)")
    }

    // State machine
    var shelf = Shelf()
    check("starts shown", !shelf.hidden && shelf.deadline == nil)
    check("refused hide leaves shelf shown", !shelf.hide(allowed: false) && !shelf.hidden)
    shelf.show(now: 0, autoHide: 8)
    check("refused auto-hide leaves shelf shown", !shelf.tick(now: 8, autoHide: 8, busy: false, canHide: false) && !shelf.hidden && shelf.deadline == nil)
    shelf.hide()
    check("hide", shelf.hidden)
    shelf.toggle(now: 100, autoHide: 8)
    check("toggle shows and starts the countdown", !shelf.hidden && shelf.deadline == 108)
    check("not hidden early", !shelf.tick(now: 107.9, autoHide: 8, busy: false) && !shelf.hidden)
    check("auto-hides at the deadline", shelf.tick(now: 108, autoHide: 8, busy: false) && shelf.hidden)
    check("tick does nothing while hidden", !shelf.tick(now: 200, autoHide: 8, busy: false))
    shelf.show(now: 0, autoHide: 8)
    check("busy pointer restarts the countdown", !shelf.tick(now: 9, autoHide: 8, busy: true) && shelf.deadline == 17 && !shelf.hidden)
    check("hides 8 s after the pointer leaves", !shelf.tick(now: 16.9, autoHide: 8, busy: false) && shelf.tick(now: 17, autoHide: 8, busy: false))
    shelf.show(now: 0, autoHide: 0)
    check("auto-hide 0 never hides", shelf.deadline == nil && !shelf.tick(now: 9999, autoHide: 0, busy: false) && !shelf.hidden)
    shelf.show(now: 0, autoHide: 8)
    check("turning auto-hide off cancels the countdown", !shelf.tick(now: 50, autoHide: 0, busy: false) && shelf.deadline == nil && !shelf.hidden)
    shelf.hide()
    shelf.quit()
    check("quit restores shown", !shelf.hidden && shelf.deadline == nil)
    check("starting hidden", Shelf(hidden: true).hidden)

    var hovered = Shelf(hidden: true)
    check("disabled hover leaves icons hidden", !hovered.hoverShow(now: 0.25, autoHide: 8, enabled: false) && hovered.hidden)
    check("hover shows icons and starts auto-hide", hovered.hoverShow(now: 0.25, autoHide: 8, enabled: true) && !hovered.hidden && hovered.deadline == 8.25)
    check("hovered icons stay shown in the menu bar", !hovered.tick(now: 9, autoHide: 8, busy: true) && hovered.deadline == 17)
    check("hovered icons auto-hide after leaving the menu bar", !hovered.tick(now: 16.9, autoHide: 8, busy: false) && hovered.tick(now: 17, autoHide: 8, busy: false) && hovered.hidden)

    shelf.show(now: 0, autoHide: 8)
    check("timer runs when shown with auto-hide on", shelf.needsAutoHideTimer(autoHide: 8))
    check("timer stops and clears countdown when switched off", !shelf.needsAutoHideTimer(autoHide: 0) && shelf.deadline == nil)
    shelf.hide()
    check("timer stays stopped when hidden with auto-hide off", !shelf.needsAutoHideTimer(autoHide: 0))
    check("timer stays stopped when auto-hide is enabled while hidden", !shelf.needsAutoHideTimer(autoHide: 8))
    shelf.show(now: 20, autoHide: 8)
    check("timer restarts when icons are shown again", shelf.needsAutoHideTimer(autoHide: 8))

    var rescued = Shelf(hidden: true)
    rescued.rescue()
    check("rescue shows icons with no countdown and no timer", !rescued.hidden && rescued.deadline == nil && !rescued.needsAutoHideTimer(autoHide: 8))
    check("rescued icons never auto-hide again", !rescued.tick(now: 0, autoHide: 8, busy: false) && !rescued.tick(now: 100, autoHide: 8, busy: false) && !rescued.hidden)
    rescued.resumeAutoHide()
    check("a layout change resumes auto-hide", rescued.needsAutoHideTimer(autoHide: 8))
    rescued.rescue(); rescued.hide()
    rescued.show(now: 50, autoHide: 8)
    check("hiding by hand resumes auto-hide", rescued.deadline == 58 && rescued.needsAutoHideTimer(autoHide: 8))

    var start = StartHide()
    check("start hide: hides as soon as the layout allows", start.step(hidden: false, canHide: true) == .hide)
    check("start hide: stops once hidden", start.step(hidden: true, canHide: false) == .done)
    start = StartHide()
    let steps = (0..<6).map { _ in start.step(hidden: false, canHide: false) }
    check("start hide: four retries 2 s apart, then gives up", steps == Array(repeating: .retry(after: 2), count: 4) + [.done, .done] && StartHide.firstDelay == 1)

    // Safety
    check("can hide when divider is left of the icon", Safety.canHide(dividerMinX: 1000, iconMinX: 1020))
    check("cannot hide when divider is right of the icon", !Safety.canHide(dividerMinX: 1030, iconMinX: 1020))
    check("cannot hide when positions are unknown", !Safety.canHide(dividerMinX: nil, iconMinX: 1020) && !Safety.canHide(dividerMinX: 1000, iconMinX: nil))
    let screens = [CGRect(x: 0, y: 0, width: 1512, height: 982)]
    check("icon on screen", Safety.iconVisible(CGRect(x: 1400, y: 0, width: 24, height: 24), screens: screens))
    check("icon pushed off screen", !Safety.iconVisible(CGRect(x: -9000, y: 0, width: 24, height: 24), screens: screens))
    check("no icon frame counts as not visible", !Safety.iconVisible(nil, screens: screens))

    // Settings and first run
    let name = "ShutterFixtures.\(UUID())"
    let store = UserDefaults(suiteName: name)!
    defer { store.removePersistentDomain(forName: name) }
    check("defaults: 8 s, not hidden at start, tip unseen", Prefs.read(store) == Prefs(autoHide: 8, hideOnStart: false, tipSeen: false))
    check("first run starts shown even with hide-on-start", !Prefs(hideOnStart: true, tipSeen: false).startsHidden)
    check("later runs start hidden when asked", Prefs(hideOnStart: true, tipSeen: true).startsHidden)
    check("later runs start shown by default", !Prefs(hideOnStart: false, tipSeen: true).startsHidden)
    var prefs = Prefs()
    store.set(Data(#"{"autoHide":15,"hideOnStart":true,"tipSeen":true}"#.utf8), forKey: Prefs.key)
    check("older settings enable hover without losing preferences", Prefs.read(store) == Prefs(autoHide: 15, hideOnStart: true, tipSeen: true, showOnHover: true))
    prefs.showOnHover = false
    prefs.autoHide = 15
    prefs.hideOnStart = true
    prefs.tipSeen = true
    prefs.save(store)
    check("preferences round trip", Prefs.read(UserDefaults(suiteName: name)!) == prefs)
    prefs.autoHide = 999
    prefs.save(store)
    check("auto-hide is clamped to 60", Prefs.read(store).autoHide == 60)
    store.set(Data(#"{"hideOnStart":true,"tipSeen":true,"autoHide":"x"}"#.utf8), forKey: Prefs.key)
    check("a blob missing or damaged in some keys keeps the rest", Prefs.read(store) == Prefs(autoHide: 8, hideOnStart: true, tipSeen: true, showOnHover: true))
    store.set(Data(#"{"showOnHover":false}"#.utf8), forKey: Prefs.key)
    check("a blob missing the older keys keeps showOnHover", Prefs.read(store) == Prefs(autoHide: 8, hideOnStart: false, tipSeen: false, showOnHover: false))
    store.set(Data([255]), forKey: Prefs.key)
    check("damaged preferences recover", Prefs.read(store) == Prefs())
    print("\(count) fixture checks passed")
  }
}
