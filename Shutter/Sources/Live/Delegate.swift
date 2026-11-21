import AppKit
import ServiceManagement
import SwiftUI

/// The menu bar side. Two status items: the divider (made first) and Shutter's icon. The user ⌘-drags icons to
/// the left of the divider; hiding widens the divider so macOS pushes everything left of it off the screen.
/// Nothing here needs a permission.
@MainActor final class Delegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
  let model = Model()
  private var divider: NSStatusItem!, icon: NSStatusItem!
  private var shelf = Shelf()
  private var timer: Timer?
  private var settings: NSWindow?, tip: NSWindow?
  private var placementPopover: NSPopover?
  private var tipStep = 0, menuOpen = false
  private let lineImage = NSImage.mark(LineMark(), size: LineMark.statusSize, ink: LineMark.ink)
  private var now: TimeInterval { ProcessInfo.processInfo.systemUptime }

  func applicationDidFinishLaunching(_ notification: Notification) {
    // First run: ask macOS to put the icon rightmost and the divider just left of it.
    let defaults = UserDefaults.standard
    for (name, slot) in [("Shutter.icon", 0), ("Shutter.divider", 1)] {
      let key = "NSStatusItem Preferred Position \(name)"
      if defaults.object(forKey: key) == nil { defaults.set(slot, forKey: key) }
    }
    divider = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    divider.autosaveName = "Shutter.divider"
    divider.button?.image = lineImage
    divider.button?.toolTip = "Shutter divider: ⌘-drag icons to the left of this line"
    icon = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    icon.autosaveName = "Shutter.icon"
    icon.button?.image = .mark(SlatMark(), size: SlatMark.statusSize, ink: SlatMark.ink)
    icon.button?.toolTip = "Shutter: click to hide or show"
    icon.button?.target = self
    icon.button?.action = #selector(clicked)
    icon.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
    icon.button?.addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self, userInfo: nil))

    model.setLogin = { [weak self] on in
      do { if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() } } catch {}
      self?.model.login = SMAppService.mainApp.status == .enabled
    }
    model.login = SMAppService.mainApp.status == .enabled
    model.showTip = { [weak self] in self?.openTip() }
    model.hotKeyChanged = { [weak self] in self?.registerHotKey() }
    registerHotKey()

    NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
      MainActor.assumeIsolated { self?.shelf.resumeAutoHide(); self?.updateTimer() }
    }
    model.autoHideChanged = { [weak self] in self?.updateTimer() }
    updateTimer()

    if !model.prefs.tipSeen {
      openTip()
    } else if model.prefs.startsHidden {
      hideAtStart(StartHide(), after: StartHide.firstDelay)
    }
  }

  /// At login macOS can take a while to lay the items out; until it has, hiding is refused, so try again a few times.
  private func hideAtStart(_ start: StartHide, after delay: TimeInterval) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
      guard let self else { return }
      var start = start
      switch start.step(hidden: shelf.hidden, canHide: canHide) {
      case .hide: hide()
      case .retry(let after): hideAtStart(start, after: after)
      case .done: break
      }
    }
  }

  func applicationWillTerminate(_ notification: Notification) {
    cancelHover()
    timer?.invalidate()
    shelf.quit()
    apply()
  }

  // MARK: Hide and show

  @objc(mouseEntered:) private func enteredIcon(_ event: NSEvent) {
    cancelHover()
    guard shelf.hidden, model.prefs.showOnHover else { return }
    perform(#selector(hoverElapsed), with: nil, afterDelay: 0.25, inModes: [.common])
  }

  @objc(mouseExited:) private func leftIcon(_ event: NSEvent) { cancelHover() }

  private func cancelHover() {
    NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hoverElapsed), object: nil)
  }

  @objc private func hoverElapsed() {
    guard !menuOpen, NSEvent.pressedMouseButtons == 0,
          shelf.hoverShow(now: now, autoHide: model.prefs.autoHide, enabled: model.prefs.showOnHover) else { return }
    updateTimer()
    apply()
  }

  private func apply() {
    divider.length = shelf.hidden ? Safety.hiddenLength : NSStatusItem.variableLength
    divider.button?.image = shelf.hidden ? nil : lineImage
    icon.button?.toolTip = shelf.hidden ? "Shutter: click to show hidden icons" : "Shutter: click to hide icons"
  }

  private func show() {
    cancelHover()
    shelf.show(now: now, autoHide: model.prefs.autoHide)
    updateTimer()
    apply()
  }

  private var canHide: Bool {
    Safety.canHide(dividerMinX: divider.button?.window?.frame.minX, iconMinX: icon.button?.window?.frame.minX)
  }

  private func hide(userInitiated: Bool = false) {
    guard shelf.hide(allowed: canHide) else {
      if userInitiated { showPlacementPopover() }
      return
    }
    applyHide()
  }

  private func applyHide() {
    updateTimer()
    placementPopover?.close()
    apply()
    // Safety net: if Shutter's own icon ended up off screen, undo at once.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
      guard let self, shelf.hidden else { return }
      if !Safety.iconVisible(icon.button?.window?.frame, screens: NSScreen.screens.map(\.frame)) {
        shelf.rescue()                      // no auto-hide until the user hides by hand or the screens change
        updateTimer(); apply()
      }
    }
  }

  private func toggle() {
    if shelf.hidden { show() } else { hide(userInitiated: true) }
  }

  private func showPlacementPopover() {
    guard let button = icon.button else { return }
    placementPopover?.close()
    let popover = NSPopover()
    popover.behavior = .transient
    popover.contentViewController = NSHostingController(rootView: PlacementHint { [weak popover] in popover?.close() })
    placementPopover = popover
    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak popover] in popover?.close() }
  }

  private func updateTimer() {
    guard shelf.needsAutoHideTimer(autoHide: model.prefs.autoHide) else {
      timer?.invalidate()
      timer = nil
      return
    }
    guard timer == nil else { return }
    let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
      MainActor.assumeIsolated { self?.tick() }
    }
    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer
  }

  private func tick() {
    let location = NSEvent.mouseLocation
    let inBar = NSScreen.screens.first { NSMouseInRect(location, $0.frame, false) }.map {
      location.y >= $0.frame.maxY - max(NSStatusBar.system.thickness, $0.frame.maxY - $0.visibleFrame.maxY)
    } ?? false
    let busy = inBar || menuOpen || NSEvent.pressedMouseButtons != 0
    if shelf.tick(now: now, autoHide: model.prefs.autoHide, busy: busy, canHide: canHide) { applyHide() }
  }

  // MARK: Clicks and menu

  @objc private func clicked() {
    cancelHover()
    let event = NSApp.currentEvent
    if event?.type == .rightMouseUp || event?.modifierFlags.contains(.option) == true {
      let menu = NSMenu()
      menu.delegate = self
      let toggleItem = menu.addItem(withTitle: shelf.hidden ? "Show Icons" : "Hide Icons", action: #selector(menuToggle), keyEquivalent: "")
      toggleItem.target = self
      if let key = model.hotKey, let letter = key.display.last, letter.isLetter || letter.isNumber {   // show the shortcut in the menu
        toggleItem.keyEquivalent = String(letter).lowercased()
        toggleItem.keyEquivalentModifierMask = NSEvent.ModifierFlags(rawValue: key.modifiers)
      }
      menu.addItem(.separator())
      menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",").target = self
      menu.addItem(.separator())
      menu.addItem(withTitle: "Quit Shutter", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
      icon.menu = menu
      icon.button?.performClick(nil)
      icon.menu = nil
    } else {
      if placementPopover?.isShown == true { placementPopover?.close(); return }
      toggle()
    }
  }
  @objc private func menuToggle() { toggle() }
  func menuWillOpen(_ menu: NSMenu) { menuOpen = true }
  func menuDidClose(_ menu: NSMenu) { menuOpen = false }

  private func registerHotKey() {
    HotKeys.shared.unregister(1)
    if let key = model.hotKey { _ = HotKeys.shared.register(1, .init(key)) { [weak self] in self?.toggle() } }
  }

  // MARK: Windows

  @objc private func openSettings() {
    if settings == nil {
      let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 520, height: 560), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: true)
      window.title = "Shutter Settings"
      window.isReleasedWhenClosed = false
      window.contentView = NSHostingView(rootView: SettingsFace(model: model))
      window.center()
      settings = window
    }
    settings?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  private func openTip() {
    tipStep = 0
    if tip == nil {
      let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 440, height: 400), styleMask: [.titled, .closable], backing: .buffered, defer: true)
      window.title = "Welcome to Shutter"
      window.isReleasedWhenClosed = false
      window.center()
      tip = window
      NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { [weak self] _ in
        MainActor.assumeIsolated { self?.model.prefs.tipSeen = true }
      }
    }
    renderTip()
    tip?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  private func renderTip() {
    tip?.contentView = NSHostingView(rootView: TipFace(
      step: tipStep,
      next: { [weak self] in
        guard let self else { return }
        if tipStep == 2 { KitSound.play(.confirm); tip?.close() } else { tipStep += 1; renderTip() }
      },
      back: { [weak self] in self?.tipStep -= 1; self?.renderTip() }))
  }
}
