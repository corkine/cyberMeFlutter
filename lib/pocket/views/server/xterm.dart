import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:xterm/xterm.dart';

class XTermView extends ConsumerStatefulWidget {
  final String ip;
  final String username;
  final String password;
  final Terminal terminal = Terminal();
  XTermView(
      {required this.ip,
      required this.username,
      required this.password,
      super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _XTermViewState();
}

class _XTermViewState extends ConsumerState<XTermView> {
  late final terminal = widget.terminal;
  String title = 'Terminal';
  SSHClient? _client;
  SSHSession? _session;
  final Set<StreamSubscription> _subs = {};

  @override
  void initState() {
    super.initState();
    initTerminal();
  }

  @override
  void dispose() {
    debugPrint("closing ssh conn to ${widget.ip}");
    for (var element in _subs) {
      element.cancel();
    }
    _session?.close();
    _client?.close();
    super.dispose();
  }

  Future<void> initTerminal() async {
    try {
      terminal.write('Connecting...\r\n');

      String ip;
      int port = 22;

      if (widget.ip.contains(':')) {
        final parts = widget.ip.split(':');
        ip = parts[0];
        port = int.parse(parts[1]);
      } else {
        ip = widget.ip;
      }

      _client = SSHClient(
        await SSHSocket.connect(ip, port),
        username: widget.username,
        onPasswordRequest: () => widget.password,
        //printDebug: (msg) => debugPrint(msg),
      );

      terminal.write('Connected\r\n');

      _session = await _client?.shell(
        pty: SSHPtyConfig(
          width: terminal.viewWidth,
          height: terminal.viewHeight,
        ),
      );

      terminal.buffer.clear();
      terminal.buffer.setCursor(0, 0);

      terminal.onTitleChange = (title) {
        setState(() => this.title = title);
      };

      terminal.onResize = (width, height, pixelWidth, pixelHeight) {
        _session?.resizeTerminal(width, height, pixelWidth, pixelHeight);
      };

      terminal.onOutput = (data) {
        _session?.write(utf8.encode(data));
      };

      _subs.add(_session!.stdout
          .cast<List<int>>()
          .transform(const Utf8Decoder())
          .listen(terminal.write));

      _subs.add(_session!.stderr
          .cast<List<int>>()
          .transform(const Utf8Decoder())
          .listen(terminal.write));
    } catch (e) {
      _session?.close();
      _client?.close();
      for (var element in _subs) {
        element.cancel();
      }
      terminal.write('Connection failed: $e\r\n');
    }
  }

  @override
  Widget build(BuildContext context) {
    return TerminalView(terminal,
        padding: const EdgeInsets.all(5),
        theme: TerminalTheme(
            cursor: Theme.of(context).colorScheme.secondary,
            selection: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
            foreground: const Color(0XFF1E1E1E),
            background: const Color.fromARGB(255, 248, 249, 255),
            black: const Color(0XFF000000),
            red: const Color(0XFFCD3131),
            green: const Color(0XFF0DBC79),
            yellow: const Color(0XFFE5E510),
            blue: const Color(0XFF2472C8),
            magenta: const Color(0XFFBC3FBC),
            cyan: const Color(0XFF11A8CD),
            white: const Color(0XFFE5E5E5),
            brightBlack: const Color(0XFF666666),
            brightRed: const Color(0XFFF14C4C),
            brightGreen: const Color(0XFF23D18B),
            brightYellow: const Color(0XFFF5F543),
            brightBlue: const Color(0XFF3B8EEA),
            brightMagenta: const Color(0XFFD670D6),
            brightCyan: const Color(0XFF29B8DB),
            brightWhite: const Color(0XFFFFFFFF),
            searchHitBackground: const Color(0XFFFFFF2B),
            searchHitBackgroundCurrent: const Color(0XFF31FF26),
            searchHitForeground: const Color(0XFF000000)));
  }
}
