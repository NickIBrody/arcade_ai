import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import 'package:xterm/xterm.dart';

enum SshState { idle, connecting, connected, error }

class SshSessionController {
  SSHClient? _client;
  SSHSession? _shell;
  SshState state = SshState.idle;
  String? error;

  Future<bool> connect({
    required String host,
    required int port,
    required String username,
    required String password,
    required Terminal terminal,
  }) async {
    state = SshState.connecting;
    try {
      final socket = await SSHSocket.connect(host, port,
          timeout: const Duration(seconds: 15));
      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );

      final w = terminal.viewWidth > 0 ? terminal.viewWidth : 80;
      final h = terminal.viewHeight > 0 ? terminal.viewHeight : 24;
      _shell = await _client!.shell(
        pty: SSHPtyConfig(width: w, height: h),
      );

      terminal.onOutput = (data) => _shell?.write(utf8.encode(data));
      terminal.onResize = (cw, ch, pw, ph) => _shell?.resizeTerminal(cw, ch);

      _shell!.stdout
          .listen((d) => terminal.write(utf8.decode(d, allowMalformed: true)));
      _shell!.stderr
          .listen((d) => terminal.write(utf8.decode(d, allowMalformed: true)));

      state = SshState.connected;
      return true;
    } catch (e) {
      error = e.toString();
      state = SshState.error;
      return false;
    }
  }

  /// Type a command into the live shell (adds the trailing newline).
  void run(String command) => _shell?.write(utf8.encode('$command\n'));

  void send(String raw) => _shell?.write(utf8.encode(raw));

  void close() {
    _shell?.close();
    _client?.close();
    _shell = null;
    _client = null;
    state = SshState.idle;
  }
}

/// One-liner that detects the package manager, installs Node + git, then
/// installs OpenCode. Sent into the live shell on "Setup".
const String kProvisionScript = r'''
sh -c '
echo "== detecting package manager ==";
if command -v apt-get >/dev/null 2>&1; then PM="sudo apt-get update && sudo apt-get install -y nodejs npm git";
elif command -v dnf >/dev/null 2>&1; then PM="sudo dnf install -y nodejs npm git";
elif command -v pacman >/dev/null 2>&1; then PM="sudo pacman -S --noconfirm nodejs npm git";
elif command -v apk >/dev/null 2>&1; then PM="sudo apk add nodejs npm git";
elif command -v zypper >/dev/null 2>&1; then PM="sudo zypper -n install nodejs npm git";
elif command -v brew >/dev/null 2>&1; then PM="brew install node git";
else echo "!! unknown package manager — install nodejs + git manually"; PM=""; fi;
echo "PM: $PM";
command -v node >/dev/null 2>&1 || eval "$PM";
echo "== node: $(node -v 2>/dev/null) | git: $(git --version 2>/dev/null) ==";
command -v opencode >/dev/null 2>&1 || npm i -g opencode-ai;
echo "== opencode: $(opencode --version 2>/dev/null || echo not-installed) ==";
'
''';
