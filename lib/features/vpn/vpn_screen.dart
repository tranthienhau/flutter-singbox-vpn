import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/singbox/singbox_config.dart';
import '../../core/singbox/singbox_runner.dart';

final _runnerProvider = Provider<SingboxRunner>((ref) {
  final r = SingboxRunner();
  ref.onDispose(r.dispose);
  return r;
});

final _stateProvider = StreamProvider<SingboxState>((ref) {
  return ref.watch(_runnerProvider).state$;
});

const _servers = <VpnServerInfo>[
  VpnServerInfo(tag: 'us-nyc', label: 'United States - New York'),
  VpnServerInfo(tag: 'de-fra', label: 'Germany - Frankfurt'),
  VpnServerInfo(tag: 'jp-tok', label: 'Japan - Tokyo'),
];

class VpnServerInfo {
  const VpnServerInfo({required this.tag, required this.label});
  final String tag;
  final String label;
}

class VpnScreen extends ConsumerStatefulWidget {
  const VpnScreen({super.key});

  @override
  ConsumerState<VpnScreen> createState() => _VpnScreenState();
}

class _VpnScreenState extends ConsumerState<VpnScreen> {
  String _selected = _servers.first.tag;
  bool _blockP2P = true;
  bool _killSwitch = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_stateProvider).valueOrNull ?? SingboxState.idle;
    final connected = state == SingboxState.connected;

    return Scaffold(
      appBar: AppBar(title: const Text('Sing-box VPN')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatusCard(state: state),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selected,
              decoration: const InputDecoration(labelText: 'Server'),
              items: [
                for (final s in _servers)
                  DropdownMenuItem(value: s.tag, child: Text(s.label)),
              ],
              onChanged: connected ? null : (v) => setState(() => _selected = v!),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Block BitTorrent / P2P'),
              subtitle: const Text('Enforced at Sing-box rule-set layer'),
              value: _blockP2P,
              onChanged: connected ? null : (v) => setState(() => _blockP2P = v),
            ),
            SwitchListTile(
              title: const Text('Kill switch'),
              subtitle: const Text('Drop all traffic when tunnel is down'),
              value: _killSwitch,
              onChanged: connected ? null : (v) => setState(() => _killSwitch = v),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => _toggle(connected),
              child: Text(connected ? 'Disconnect' : 'Connect'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggle(bool connected) async {
    final runner = ref.read(_runnerProvider);
    if (connected) {
      await runner.stop();
      return;
    }
    final cfg = SingboxConfig(
      servers: [
        for (final s in _servers)
          VpnServer(
            tag: s.tag,
            type: 'wireguard',
            server: '${s.tag}.vpn.example',
            serverPort: 51820,
            params: const {
              'private_key': '<PRIVATE_KEY>',
              'peer_public_key': '<PEER_PUBLIC_KEY>',
              'local_address': ['10.0.0.2/32'],
            },
          ),
      ],
      blockP2P: _blockP2P,
      killSwitch: _killSwitch,
    );
    await runner.start(cfg.buildJson(_selected));
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});
  final SingboxState state;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      SingboxState.idle => ('Disconnected', Colors.grey),
      SingboxState.connecting => ('Connecting...', Colors.amber),
      SingboxState.connected => ('Connected', Colors.green),
      SingboxState.error => ('Error', Colors.red),
    };
    return Card(
      child: ListTile(
        leading: Icon(Icons.shield, color: color),
        title: Text(label),
        subtitle: Text('Sing-box tunnel state: ${state.name}'),
      ),
    );
  }
}
