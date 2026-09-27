import Foundation

/// The page a new window opens: the first web address among the launch arguments, otherwise the
/// configured home page. Anything else on the command line is left for the app to interpret.
public func startURL(arguments: [String], home: URL) -> URL {
  for argument in arguments.dropFirst() {
    if let url = URL(string: argument), let scheme = url.scheme?.lowercased(),
      scheme == "http" || scheme == "https"
    {
      return url
    }
  }
  return home
}
