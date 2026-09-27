import Foundation
import Network

/// A minimal HTTP server on the loopback interface, so tests download through WebKit's real
/// network stack. A `WKURLSchemeHandler` cannot stand in: WebKit does not turn a custom-scheme
/// load into a download, and `startDownload(using:)` ignores scheme handlers.
@MainActor
final class TestServer {
  enum Ending {
    case finish
    /// Sends half the promised body, then closes the connection.
    case drop
    /// Sends half the promised body, then nothing, like a stalled connection.
    case stall
  }

  struct Reply {
    var headers: [String: String] = [:]
    var body = Data()
    var ending = Ending.finish
  }

  /// Replies by URL path.
  var replies: [String: Reply] = [:]

  private let listener: NWListener
  // Held so a stalled connection stays open until the server goes.
  private var connections: [NWConnection] = []
  private let port: NWEndpoint.Port

  /// Starts listening on 127.0.0.1 only, so no firewall prompt asks about incoming connections.
  static func start() async throws -> TestServer {
    let parameters = NWParameters.tcp
    parameters.requiredLocalEndpoint = .hostPort(host: .ipv4(.loopback), port: .any)
    let listener = try NWListener(using: parameters)
    let port = try await withCheckedThrowingContinuation {
      (continuation: CheckedContinuation<NWEndpoint.Port, Error>) in
      listener.stateUpdateHandler = { state in
        switch state {
        case .ready:
          listener.stateUpdateHandler = nil
          continuation.resume(returning: listener.port!)
        case .failed(let error):
          listener.stateUpdateHandler = nil
          continuation.resume(throwing: error)
        default: break
        }
      }
      listener.newConnectionHandler = { _ in }
      listener.start(queue: .main)
    }
    return TestServer(listener: listener, port: port)
  }

  private init(listener: NWListener, port: NWEndpoint.Port) {
    self.listener = listener
    self.port = port
    listener.newConnectionHandler = { [weak self] connection in
      MainActor.assumeIsolated { self?.accept(connection) }
    }
  }

  func url(_ path: String) -> URL {
    URL(string: "http://127.0.0.1:\(port.rawValue)\(path)")!
  }

  private func accept(_ connection: NWConnection) {
    connections.append(connection)
    connection.start(queue: .main)
    readRequest(on: connection, received: Data())
  }

  private func readRequest(on connection: NWConnection, received: Data) {
    connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) {
      [weak self] data, _, _, error in
      MainActor.assumeIsolated {
        guard let self, error == nil else { return }
        let received = received + (data ?? Data())
        if received.range(of: Data("\r\n\r\n".utf8)) == nil {
          self.readRequest(on: connection, received: received)
        } else {
          self.respond(to: received, on: connection)
        }
      }
    }
  }

  private func respond(to request: Data, on connection: NWConnection) {
    let line = String(decoding: request, as: UTF8.self).prefix { $0 != "\r" }
    let path = line.split(separator: " ").dropFirst().first.map(String.init) ?? "/"
    guard let reply = replies[path] else {
      send(
        "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n", on: connection)
      return
    }
    let promised = reply.ending == .finish ? reply.body.count : reply.body.count * 2
    var head = "HTTP/1.1 200 OK\r\nContent-Length: \(promised)\r\nConnection: close\r\n"
    var headers = reply.headers
    headers["Content-Type"] = headers["Content-Type"] ?? "application/octet-stream"
    for (name, value) in headers { head += "\(name): \(value)\r\n" }
    head += "\r\n"
    let data = Data(head.utf8) + reply.body
    switch reply.ending {
    case .finish, .drop:
      connection.send(content: data, completion: .contentProcessed { _ in connection.cancel() })
    case .stall:
      connection.send(content: data, completion: .contentProcessed { _ in })
    }
  }

  private func send(_ text: String, on connection: NWConnection) {
    connection.send(
      content: Data(text.utf8), completion: .contentProcessed { _ in connection.cancel() })
  }
}
