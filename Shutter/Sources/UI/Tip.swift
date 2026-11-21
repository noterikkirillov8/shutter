import SwiftUI

/// A mock menu bar strip: a few icons, the divider, Shutter's slats.
private struct MiniBar: View {
  var items = true        // the icons left of the divider are visible
  var captions = false
  var accentDivider = false

  var body: some View {
    ZStack(alignment: .top) {
      RoundedRectangle(cornerRadius: 8).fill(KitColor.well).frame(height: 32)
      HStack(alignment: .top, spacing: 22) {
        column(caption: "Can hide") {
          HStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { _ in icon }
          }.opacity(items ? 1 : 0)
        }
        column(caption: "Line") {
          LineMark().fill(accentDivider ? steel : KitColor.text2).frame(width: 6, height: 16)
            .opacity(items ? 1 : 0)
        }
        column(caption: "Stays") { icon }
        column(caption: "Shutter") { SlatMark().fill(KitColor.text).frame(width: 16, height: 12) }
      }.padding(.horizontal, 16)
    }.frame(width: 300)
  }

  private var icon: some View { RoundedRectangle(cornerRadius: 3).fill(KitColor.text3).frame(width: 14, height: 12) }

  private func column<V: View>(caption: String, @ViewBuilder _ glyph: () -> V) -> some View {
    VStack(spacing: 8) {
      glyph().frame(height: 32)
      if captions { Text(caption).font(KitFont.detail).foregroundStyle(KitColor.text2) }
    }
  }
}

struct PlacementHint: View {
  var dismiss: () -> Void = {}

  var body: some View {
    Button(action: dismiss) {
      VStack(alignment: .leading, spacing: 6) {
        Text("Move the divider left of Shutter").font(KitFont.title).foregroundStyle(KitColor.text)
        Text("The thin line has to sit to the left of the slats icon. Hold ⌘ and drag it there, then try again.")
          .font(KitFont.body).foregroundStyle(KitColor.text2).fixedSize(horizontal: false, vertical: true)
      }
      .padding(16).frame(width: 290, alignment: .leading).background(KitColor.raised)
    }.buttonStyle(.plain)
  }
}

struct TipFace: View {
  var step: Int            // 0, 1, 2
  var next: () -> Void = {}
  var back: () -> Void = {}

  private static let scenes: [(String, String)] = [
    ("Choose what stays", "Icons left of the thin line hide when you click Shutter. Hold ⌘ and drag the ones you always want, like battery or Wi-Fi, to the right of the line."),
    ("Click Shutter to hide or show", "Click the slats or press ⌃⌥⌘H. Or just rest the pointer on it. Right-click for Settings."),
    ("They hide again by themselves", "A few seconds after you show them, they go away again. You can change this in Settings."),
  ]

  var body: some View {
    VStack(spacing: 22) {
      ZStack {
        illustration.id(step).transition(.opacity)
      }.frame(height: 176)
      VStack(spacing: 6) {
        Text(Self.scenes[step].0).font(.system(size: 17, weight: .semibold)).foregroundStyle(KitColor.text)
        Text(Self.scenes[step].1).font(KitFont.body).foregroundStyle(KitColor.text2)
          .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
      }.id(step).transition(.opacity).frame(height: 84, alignment: .top)
      HStack {
        Button("Back", action: back).buttonStyle(.kitQuiet).focusable(false).opacity(step == 0 ? 0 : 1).disabled(step == 0)
        Spacer()
        HStack(spacing: 6) {
          ForEach(0..<3, id: \.self) { Circle().fill($0 == step ? steel : KitColor.unlit).frame(width: 6, height: 6) }
        }
        Spacer()
        Button(step == 2 ? "Get started" : "Next", action: next).buttonStyle(.kitPrimary).focusable(false).keyboardShortcut(.defaultAction)
      }
    }
    .padding(28).frame(width: 440, height: 400).background(KitColor.window)
    .foregroundStyle(KitColor.text).kitAccent(steel)
    .animation(.easeInOut(duration: 0.25), value: step)
  }

  @ViewBuilder private var illustration: some View {
    switch step {
    case 0:
      MiniBar(captions: true, accentDivider: true)
    case 1:
      VStack(spacing: 14) {
        label("Shown")
        MiniBar()
        Image(systemName: "arrow.down").foregroundStyle(KitColor.text3)
        label("Hidden")
        MiniBar(items: false)
      }
    default:
      VStack(spacing: 14) {
        MiniBar()
        VStack(spacing: 5) {
          RoundedRectangle(cornerRadius: 2).fill(KitColor.unlit).frame(width: 220, height: 3)
            .overlay(alignment: .leading) { RoundedRectangle(cornerRadius: 2).fill(steel).frame(width: 140, height: 3) }
          Text("A few seconds").font(KitFont.detail).foregroundStyle(KitColor.text2)
        }
        MiniBar(items: false)
      }
    }
  }

  private func label(_ text: String) -> some View {
    Text(text).font(KitFont.detail).foregroundStyle(KitColor.text2).frame(width: 300, alignment: .leading)
  }
}

/// What the right-click menu looks like, for the QA render (the real one is a system NSMenu).
struct MenuMock: View {
  var hidden = false
  private func row(_ title: String, _ key: String) -> some View {
    HStack { Text(title); Spacer(minLength: 30); Text(key).foregroundStyle(KitColor.text2) }
      .font(KitFont.body).padding(.horizontal, 12).frame(height: 24)
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      row(hidden ? "Show Icons" : "Hide Icons", "⌃⌥⌘H")
      KitDivider(inset: 8).padding(.vertical, 3)
      row("Settings…", "⌘,")
      KitDivider(inset: 8).padding(.vertical, 3)
      row("Quit Shutter", "⌘Q")
    }
    .padding(.vertical, 6).frame(width: 240)
    .background(RoundedRectangle(cornerRadius: 8).fill(KitColor.raised))
    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(KitColor.line))
    .foregroundStyle(KitColor.text).padding(20).background(KitColor.window)
  }
}
