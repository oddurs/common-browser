/// How long a test waits for the UI or a web content process before failing. It is generous on
/// purpose: a loaded machine can take many seconds to start WebKit's processes and to give the main
/// actor time, while a sheet or page that never appears still fails, only later.
let uiTimeout: Duration = .seconds(60)
