import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import 'package:xterm/xterm.dart';

class ExecResult {
  final int code;
  final String output;
  ExecResult(this.code, this.output);
  bool get ok => code == 0;
}

class SshSessionController {
  SSHClient? _client;
  SSHSession? _shell;
  String? error;

  bool get connected => _client != null;

  Future<bool> connect({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    try {
      final socket = await SSHSocket.connect(host, port,
          timeout: const Duration(seconds: 15));
      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );
      await _client!.authenticated;
      return true;
    } catch (e) {
      error = e.toString();
      _client = null;
      return false;
    }
  }

  /// Silent, non-interactive command — used by the setup flow.
  Future<ExecResult> exec(String command) async {
    final c = _client;
    if (c == null) return ExecResult(-1, 'not connected');
    try {
      final session = await c.execute(command);
      final buf = <int>[];
      session.stdout.listen(buf.addAll);
      session.stderr.listen(buf.addAll);
      await session.done;
      return ExecResult(
          session.exitCode ?? -1, utf8.decode(buf, allowMalformed: true));
    } catch (e) {
      return ExecResult(-1, e.toString());
    }
  }

  /// Interactive shell wired to the terminal emulator (for the OpenCode TUI).
  Future<void> startShell(Terminal terminal, {String? initialCommand}) async {
    final c = _client;
    if (c == null) return;
    final w = terminal.viewWidth > 0 ? terminal.viewWidth : 80;
    final h = terminal.viewHeight > 0 ? terminal.viewHeight : 24;
    _shell = await c.shell(pty: SSHPtyConfig(width: w, height: h));
    terminal.onOutput = (data) => _shell?.write(utf8.encode(data));
    terminal.onResize = (cw, ch, pw, ph) => _shell?.resizeTerminal(cw, ch);
    _shell!.stdout
        .listen((d) => terminal.write(utf8.decode(d, allowMalformed: true)));
    _shell!.stderr
        .listen((d) => terminal.write(utf8.decode(d, allowMalformed: true)));
    if (initialCommand != null) {
      _shell!.write(utf8.encode('$initialCommand\n'));
    }
  }

  void run(String command) => _shell?.write(utf8.encode('$command\n'));
  void send(String raw) => _shell?.write(utf8.encode(raw));

  void close() {
    _shell?.close();
    _client?.close();
    _shell = null;
    _client = null;
  }
}

/// Detect package manager + install Node and git. Returns non-zero on failure.
const String kInstallDepsCmd = r'''
if command -v node >/dev/null 2>&1 && command -v git >/dev/null 2>&1; then exit 0; fi
SUDO=""; [ "$(id -u)" != "0" ] && command -v sudo >/dev/null 2>&1 && SUDO="sudo"
if command -v apt-get >/dev/null 2>&1; then $SUDO apt-get update -y && $SUDO apt-get install -y nodejs npm git
elif command -v dnf >/dev/null 2>&1; then $SUDO dnf install -y nodejs npm git
elif command -v pacman >/dev/null 2>&1; then $SUDO pacman -S --noconfirm nodejs npm git
elif command -v apk >/dev/null 2>&1; then $SUDO apk add nodejs npm git
elif command -v zypper >/dev/null 2>&1; then $SUDO zypper -n install nodejs npm git
elif command -v brew >/dev/null 2>&1; then brew install node git
else echo "no known package manager"; exit 1; fi
''';

const String kInstallOpencodeCmd =
    'command -v opencode >/dev/null 2>&1 || npm i -g opencode-ai';
