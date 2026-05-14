import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

enum SingboxState { idle, connecting, connected, error }

class SingboxRunner {
  Process? _proc;
  final _stateController = StreamController<SingboxState>.broadcast();
  SingboxState _state = SingboxState.idle;

  Stream<SingboxState> get state$ => _stateController.stream;
  SingboxState get state => _state;

  Future<void> start(String configJson) async {
    if (_state == SingboxState.connecting || _state == SingboxState.connected) {
      return;
    }
    _emit(SingboxState.connecting);

    final dir = await getApplicationSupportDirectory();
    final cfg = File('${dir.path}/sing-box.json');
    await cfg.writeAsString(configJson);

    final bin = _resolveBinary();
    _proc = await Process.start(bin, ['run', '-c', cfg.path]);
    _proc!.stdout.listen((_) {});
    _proc!.stderr.listen((_) {});
    _proc!.exitCode.then((code) {
      _emit(code == 0 ? SingboxState.idle : SingboxState.error);
    });

    await Future<void>.delayed(const Duration(milliseconds: 800));
    _emit(SingboxState.connected);
  }

  Future<void> stop() async {
    final p = _proc;
    if (p == null) return;
    p.kill(ProcessSignal.sigterm);
    await p.exitCode;
    _proc = null;
    _emit(SingboxState.idle);
  }

  void dispose() {
    stop();
    _stateController.close();
  }

  String _resolveBinary() {
    if (Platform.isLinux) return '/usr/bin/sing-box';
    if (Platform.isMacOS) return '/usr/local/bin/sing-box';
    if (Platform.isWindows) {
      return r'C:\Program Files\sing-box\sing-box.exe';
    }
    throw UnsupportedError('Desktop platforms only');
  }

  void _emit(SingboxState s) {
    _state = s;
    _stateController.add(s);
  }
}
