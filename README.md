# flutter-singbox-vpn

Flutter desktop VPN client built on top of Sing-box. Targets Linux, macOS, Windows. Demonstrates:

- Sing-box config generation + lifecycle (start, stop, status)
- Connect / disconnect, server selection, kill switch
- Auto-update channel hooks
- BitTorrent / P2P traffic blocking platform-wide via Sing-box rule-sets, protocol sniffing, and route rules
- Linux packaging: `.deb`, `.AppImage`, Flatpak manifest, Snapcraft yaml
- Tun mode integration notes for Linux (`tun` device + DNS handling)

## Architecture

```
lib/
  core/
    singbox/        # config builder + process supervisor (start/stop/status)
    tun/            # Linux tun interface notes + capability requirements
    killswitch/     # firewall rules drop when tunnel down
  features/
    vpn/            # connect screen, server picker, status
    settings/       # auto-update channel, logs, advanced
assets/
  configs/
    base.json           # base Sing-box config
    block-p2p.json      # rule-set for BitTorrent/P2P blocking
linux/
  packaging/
    deb/                # debian/control + postinst
    appimage/           # AppDir + AppRun
    flatpak/            # manifest
    snap/               # snapcraft.yaml
```

## BitTorrent / P2P blocking

Enforced at the Sing-box layer so the rule applies platform-wide (Linux, Windows, macOS, Android) regardless of client UI.

Mechanisms used (see `assets/configs/block-p2p.json`):

1. **Sniffing** - `sniff: true` on the inbound tun + mixed inbound. Sing-box reads the first packets and identifies the protocol (`bittorrent`, `dns`, `http`, `tls`, `quic`, etc.) before routing.
2. **Protocol matcher route rule** - `protocol: ["bittorrent"]` -> `outbound: block`. Catches uTP, classic BT, and DHT handshakes once sniffed.
3. **Rule-set (geosite + custom)** - `rule_set: ["geosite-bittorrent-trackers", "custom-p2p-domains"]` -> `block`. Catches tracker discovery and known P2P CDNs even when payload is encrypted.
4. **Port heuristics** - `network: udp, port_range: 6881:6999` -> `block`. Cheap fallback for unsniffed traffic.
5. **DNS rejection** - `dns.rules` returns `rcode: REFUSED` for tracker domains so DHT bootstrap fails.
6. **Server-side enforcement** - same rule-set is shipped to the WireGuard/Reality server's Sing-box so a tampered client cannot bypass: client says "go", server still drops.

Bypass resistance:

- Rules pushed via signed remote config; client refuses to start with stale signature.
- Kill switch closes the tun before any leak window when the daemon restarts.
- Server-side rule mirror guarantees blocking even if the client config is patched.

## Linux desktop build

```bash
flutter config --enable-linux-desktop
flutter build linux --release
# .deb
dpkg-deb --build build/linux/x64/release/bundle dist/singboxvpn.deb
# AppImage
./linux/packaging/appimage/build.sh
# Flatpak
flatpak-builder build-dir linux/packaging/flatpak/app.singboxvpn.yml
# Snap
snapcraft pack --output dist/singboxvpn.snap
```

Tun mode on Linux requires `CAP_NET_ADMIN` - granted via `setcap` post-install or via systemd unit.

## Stack

- Flutter 3.24+, Dart 3.5+
- `process_run` for sing-box subprocess
- `flutter_riverpod` for state
- `freezed` for immutable config models
- `path_provider` for log + config paths
