import CommonCore
import Foundation
import Testing
import WebKit

@testable import CommonApp

private func loaded(_ problems: [ConfigProblem], unreadable: String? = nil) -> LoadedConfig {
  let defaults = loadConfigFrom(path: "/nonexistent/common.toml").settings
  return LoadedConfig(
    path: "/tmp/common.toml", settings: defaults, problems: problems, unreadable: unreadable)
}

private func problem(line: UInt32, _ summary: String) -> ConfigProblem {
  ConfigProblem(line: line, column: 1, key: "", summary: summary)
}

@Test func aCleanConfigShowsNoBanner() {
  #expect(configBannerText(for: loaded([])) == nil)
}

@Test func theBannerNamesTheFirstProblemsLineAndCountsTheRest() {
  let text = configBannerText(
    for: loaded([
      problem(line: 3, "3:1: unknown key `thme` (did you mean `theme`?)"),
      problem(line: 9, "9:10: `accent` must be a hex colour"),
      problem(line: 12, "12:1: Spaces arrive in v0.2"),
    ]))
  #expect(
    text == "common.toml, line 3: unknown key `thme` (did you mean `theme`?) · 2 more problems")
}

@Test func anUnreadableConfigSaysSo() {
  #expect(configBannerText(for: loaded([], unreadable: "cannot read x")) == "cannot read x")
}

@Test func aBrokenKeyKeepsItsDefaultWhileTheOthersApply() throws {
  let dir = FileManager.default.temporaryDirectory.appending(path: "common-banner-\(UUID())")
  try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: dir) }
  let file = dir.appending(path: "common.toml")
  try "theme = \"paper\"\naccent = \"orange\"\n".write(to: file, atomically: true, encoding: .utf8)
  let result = loadConfigFrom(path: file.path)
  #expect(result.settings.theme == "paper")
  #expect(result.settings.accent == "#d9895b")
  #expect(configBannerText(for: result)?.hasPrefix("common.toml, line 2: ") == true)
}

// The only test that sets XDG_CONFIG_HOME; nothing else in the suite reads the environment.
@MainActor
@Test func openingTheConfigCreatesTheTemplateAndOpensIt() throws {
  let dir = FileManager.default.temporaryDirectory.appending(path: "common-open-\(UUID())")
  defer { try? FileManager.default.removeItem(at: dir) }
  let previous = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"]
  setenv("XDG_CONFIG_HOME", dir.path, 1)
  defer {
    if let previous { setenv("XDG_CONFIG_HOME", previous, 1) } else { unsetenv("XDG_CONFIG_HOME") }
  }

  var opened: URL?
  try openConfigFile { opened = $0 }
  let file = dir.appending(path: "common/common.toml")
  #expect(opened?.path == file.path)
  let text = try String(contentsOf: file, encoding: .utf8)
  #expect(text.contains("# home = \"about:blank\""))
  #expect(text.contains("# start = \"windowed\""))
}

@MainActor
@Test func theBannerStaysOverEveryPage() throws {
  let controller = BrowserWindowController(url: URL(string: "about:blank")!)
  controller.showConfigBanner("common.toml, line 1: something")
  controller.newPage(nil)
  controller.previousPage(nil)
  let views = try #require(controller.window?.contentView?.subviews)
  let banner = try #require(views.lastIndex { $0 is ConfigBanner })
  // Above every page; the launcher, when open, may sit above it.
  #expect(views.indices.filter { views[$0] is WKWebView }.allSatisfy { $0 < banner })
}
