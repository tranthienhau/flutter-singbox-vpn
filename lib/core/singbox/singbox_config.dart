import 'dart:convert';

class SingboxConfig {
  SingboxConfig({
    required this.servers,
    this.blockP2P = true,
    this.killSwitch = true,
  });

  final List<VpnServer> servers;
  final bool blockP2P;
  final bool killSwitch;

  Map<String, dynamic> build(String selectedTag) {
    final outbounds = <Map<String, dynamic>>[
      for (final s in servers) s.toOutbound(),
      {'type': 'direct', 'tag': 'direct'},
      {'type': 'block', 'tag': 'block'},
      {'type': 'dns', 'tag': 'dns-out'},
    ];

    final routeRules = <Map<String, dynamic>>[
      {'protocol': 'dns', 'outbound': 'dns-out'},
      if (blockP2P) ...[
        {'protocol': ['bittorrent'], 'outbound': 'block'},
        {
          'network': 'udp',
          'port_range': ['6881:6999'],
          'outbound': 'block',
        },
        {
          'rule_set': ['geosite-bittorrent', 'custom-p2p'],
          'outbound': 'block',
        },
      ],
      {'outbound': selectedTag},
    ];

    return {
      'log': {'level': 'info', 'timestamp': true},
      'dns': {
        'servers': [
          {'tag': 'cloudflare', 'address': 'https://1.1.1.1/dns-query'},
        ],
        'rules': [
          if (blockP2P)
            {
              'rule_set': ['geosite-bittorrent-trackers'],
              'action': 'reject',
              'method': 'default',
            },
        ],
      },
      'inbounds': [
        {
          'type': 'tun',
          'tag': 'tun-in',
          'interface_name': 'singbox0',
          'inet4_address': '172.19.0.1/30',
          'auto_route': true,
          'strict_route': killSwitch,
          'sniff': true,
          'sniff_override_destination': true,
        },
      ],
      'outbounds': outbounds,
      'route': {
        'rules': routeRules,
        'rule_set': [
          {
            'type': 'remote',
            'tag': 'geosite-bittorrent',
            'format': 'binary',
            'url': 'https://cdn.example/rules/geosite-bittorrent.srs',
          },
          {
            'type': 'remote',
            'tag': 'geosite-bittorrent-trackers',
            'format': 'binary',
            'url': 'https://cdn.example/rules/bt-trackers.srs',
          },
          {
            'type': 'local',
            'tag': 'custom-p2p',
            'format': 'source',
            'path': 'assets/configs/block-p2p.json',
          },
        ],
      },
    };
  }

  String buildJson(String selectedTag) =>
      const JsonEncoder.withIndent('  ').convert(build(selectedTag));
}

class VpnServer {
  VpnServer({
    required this.tag,
    required this.type,
    required this.server,
    required this.serverPort,
    required this.params,
  });

  final String tag;
  final String type;
  final String server;
  final int serverPort;
  final Map<String, dynamic> params;

  Map<String, dynamic> toOutbound() => {
        'type': type,
        'tag': tag,
        'server': server,
        'server_port': serverPort,
        ...params,
      };
}
