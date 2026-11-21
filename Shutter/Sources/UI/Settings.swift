import SwiftUI

struct SettingsFace: View {
  @ObservedObject var model: Model
  var bitmap = false   // ImageRenderer cannot draw a ScrollView, so the QA render uses a plain stack
  private var tab: Binding<Tab> {
    Binding(get: { Tab(rawValue: model.tab) ?? .general }, set: { model.tab = $0.rawValue })
  }
  private var tabs: [(Tab, String)] { Tab.allCases.map { ($0, $0.rawValue) } }

  var body: some View {
    Group {
      if bitmap {
        VStack(alignment: .leading, spacing: 16) {
          Text("Shutter Settings").font(KitFont.title)
          KitSegmented(selection: tab, options: tabs)
          VStack(alignment: .leading, spacing: 18) { content(tab.wrappedValue) }
          Spacer(minLength: 0)
        }
        .padding(20).frame(width: 520, height: 560, alignment: .topLeading).background(KitColor.window)
      } else {
        KitSettings(title: "Shutter Settings", tabs: tabs, selection: tab) { content($0) }
      }
    }
    .foregroundStyle(KitColor.text).kitAccent(steel)
  }

  @ViewBuilder func content(_ selected: Tab) -> some View {
    switch selected {
    case .general:
      KitSection {
        KitToggleRow(title: "Launch at login", isOn: Binding(get: { model.login }, set: { model.setLogin($0) }))
        KitRow(title: "Hide / show shortcut") { KitHotKeyField(hotKey: $model.hotKey) }
        KitRow(title: "Show the tip again") { Button("Show tip", action: model.showTip).buttonStyle(.kitSecondary) }
      }
      KitSoundSection()
    case .behaviour:
      KitSection(title: "Show") {
        KitToggleRow(title: "Show on hover", isOn: $model.prefs.showOnHover)
      }
      KitSection(title: "Hide again", footer: "Shutter hides your icons again after this many seconds. It waits while the pointer is in the menu bar. 0 turns it off.") {
        KitRow(title: "Hide after") {
          KitStepper(value: $model.prefs.autoHide, range: 0...60, format: { $0 == 0 ? "Off" : "\($0) s" })
        }
      }
      KitSection(title: "Start") {
        KitToggleRow(title: "Hide icons when Shutter starts", isOn: $model.prefs.hideOnStart)
      }
    case .about:
      KitAboutView(
        name: "Shutter", tagline: "Hide menu bar icons behind one click.",
        repoURL: URL(string: "https://github.com/noterikkirillov8/shutter"))
    }
  }
}
