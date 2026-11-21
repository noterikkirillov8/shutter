import SwiftUI

/// Off-screen PNG renders for visual QA. Never touches the menu bar.
@MainActor enum Proofs {
  static func run(_ dir: URL) throws {
    let domain = "Shutter.Proofs.\(UUID())"
    let store = UserDefaults(suiteName: domain)!
    defer { store.removePersistentDomain(forName: domain) }
    let model = Model(store)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    func save<V: View>(_ view: V, _ file: String, scale: CGFloat = 2) throws {
      let renderer = ImageRenderer(content: view.environment(\.colorScheme, .dark).defaultAppStorage(store))
      renderer.scale = scale
      var payload: Data?
      NSAppearance(named: .darkAqua)!.performAsCurrentDrawingAppearance {
        payload = renderer.cgImage.flatMap { NSBitmapImageRep(cgImage: $0).representation(using: .png, properties: [:]) }
      }
      guard let payload else { throw CocoaError(.fileWriteUnknown) }
      try payload.write(to: dir.appendingPathComponent(file + ".png"), options: .atomic)
      print("PNG  \(file)")
    }
    try save(MenuMock(), "menu-shown")
    try save(MenuMock(hidden: true), "menu-hidden")
    try FileManager.default.createDirectory(at: dir.appendingPathComponent("polish"), withIntermediateDirectories: true)
    try save(VStack(spacing: 0) {
      HStack(spacing: 0) {
        SlatMark().fill(KitColor.text).frame(width: 18, height: 16)
        LineMark().fill(KitColor.text2).frame(width: 6, height: 16).offset(x: 24)
      }.offset(x: 3).frame(maxWidth: .infinity).frame(height: 28).background(KitColor.well)
      Image(systemName: "arrowtriangle.up.fill").font(.system(size: 12)).foregroundStyle(KitColor.raised)
      PlacementHint().clipShape(RoundedRectangle(cornerRadius: 10)).padding([.horizontal, .bottom], 16)
    }.background(KitColor.window), "polish/hide-refused")
    for step in 0..<3 { try save(TipFace(step: step), "tip-\(step + 1)") }
    for tab in Tab.allCases {
      model.tab = tab.rawValue
      try save(SettingsFace(model: model, bitmap: true), "settings-" + tab.rawValue.lowercased())
    }
    model.tab = "Behaviour"
    model.prefs.autoHide = 0
    try save(SettingsFace(model: model, bitmap: true), "settings-behaviour-off")
    for density in [1, 2, 4] {
      try save(
        HStack(spacing: 0) {
          LineMark().fill(.white).frame(width: 6, height: 16)
          SlatMark().fill(.white).frame(width: 18, height: 16)
        }.frame(width: 24, height: 16).background(.black), "icon-\(density)x", scale: CGFloat(density))
    }
    print("Off-screen only.")
  }
}
