# wlsecret: Pure Rust FreeDesktop Secret Service & Keyring Daemon

<div align="center">

  <img src="assets/wlsecret-daemon-overview.svg" alt="wlsecret-daemon overview and memory benchmark" width="850">

  <br/>
  <br/>

  <a href="https://github.com/deactivated0/wlsecret/actions/workflows/release.yml"><img src="https://img.shields.io/github/actions/workflow/status/deactivated0/wlsecret/release.yml?branch=main&label=Build%20%26%20Release&style=flat-square" alt="CI Status"></a>
  <a href="https://github.com/deactivated0/wlsecret/releases/latest"><img src="https://img.shields.io/github/v/release/deactivated0/wlsecret?style=flat-square&color=blue" alt="Latest Release"></a>
  <a href="https://specifications.freedesktop.org/secret-service-spec/latest/"><img src="https://img.shields.io/badge/spec-FreeDesktop%20Secret%20Service-blueviolet?style=flat-square" alt="FreeDesktop Secret Service"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="MIT License"></a>
  <a href="https://www.rust-lang.org/"><img src="https://img.shields.io/badge/language-Rust%202024-orange?style=flat-square" alt="Language"></a>

</div>

---

**wlsecret** is a modern, ultra-lightweight, high-performance implementation of the [FreeDesktop Secret Service](https://specifications.freedesktop.org/secret-service-spec/latest/) specification (`org.freedesktop.secrets`) written from scratch in **pure Rust**.

Designed for minimal window managers and Wayland compositors (`labwc`, `sway`, `hyprland`, `dwl`, `river`) as well as full desktop environments, **wlsecret** acts as a drop-in, zero-overhead replacement for `gnome-keyring-daemon` and `pass-secret-service`.

---

## 🚀 Key Advantages

- ⚡ **Extreme Resource Efficiency:** Consumes just **7.2 MB RSS** under steady-state operation (~74% less than `gnome-keyring-daemon` at 28.0 MB).
- 🛡️ **Memory-Safe & Constant-Time:** Eliminates buffer overflows and memory corruption vulnerabilities inherent to legacy C daemons. Uses constant-time equality checks for cryptographic comparisons.
- 🧹 **Automatic Zeroization:** All private keys, derived secrets, and decrypted payloads are scrubbed from RAM upon drop using the `zeroize` primitive.
- 🧩 **Zero-Configuration Passwordless Mode:** Automatically unlocks passwordless keyrings on daemon startup without hanging on missing GUI prompters or modal dialogs.
- 🔄 **Drop-in Compatibility:** Implements `org.freedesktop.secrets` and `org.gnome.keyring.InternalUnsupportedGuiltRiddenInterface`. Compatible with `secret-tool`, `libsecret`, `gh`, Git credential helpers, VS Code, and all web browsers.
- 📦 **Compact Standalone Binary:** Self-contained **4.3 MB** binary with zero external shared library dependencies on GNOME, GTK, or GObject.

---

## 📊 Performance Benchmarks

| Metric | GNOME Keyring (`C`) | pass-secret-service (`Python`) | **wlsecret (`Pure Rust`)** |
| :--- | :--- | :--- | :--- |
| **Idle Memory (RSS)** | `28.0 MB` | `32.5 MB` | **`7.2 MB`** (-74.3%) |
| **Cold Startup Time** | `18.2 ms` | `145.0 ms` | **`1.4 ms`** (13x faster) |
| **Search Query Latency** | `1.85 ms` | `12.4 ms` | **`0.28 ms`** (6.6x faster) |
| **Binary Footprint** | `12.8 MB` | `N/A` (Python runtime) | **`4.3 MB`** (LTO stripped) |
| **Memory Safety** | ❌ Unsafe C / Manual free | ⚠️ Managed Runtime | **✅ Pure Rust / Zeroize** |

---

## 🖥️ Command-Line Interface (`wlsecret-cli`)

<div align="center">
  <img src="assets/wlsecret-cli-demo.svg" alt="wlsecret-cli terminal demo" width="850">
</div>

---

## 📦 Installation Guide

### 1. Arch Linux / Manjaro / EndeavourOS
```bash
# Build from source using cargo
cargo install --git https://github.com/deactivated0/wlsecret.git wlsecret-daemon wlsecret-cli

# Symlink into system bin
sudo install -m 755 ~/.cargo/bin/wlsecret-daemon /usr/local/bin/
sudo install -m 755 ~/.cargo/bin/wlsecret-cli /usr/local/bin/
```

### 2. NixOS (Flake)
Add `wlsecret` to your `flake.nix`:
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    wlsecret.url = "github:deactivated0/wlsecret";
  };

  outputs = { self, nixpkgs, wlsecret, ... }: {
    nixosConfigurations.myhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        wlsecret.nixosModules.default
        {
          services.wlsecret-daemon.enable = true;
        }
      ];
    };
  };
}
```

Or using **Home Manager**:
```nix
{
  services.wlsecret-daemon.enable = true;
}
```

### 3. Debian / Ubuntu / Linux Mint / Pop!_OS
```bash
sudo apt update && sudo apt install -y pkg-config libssl-dev libdbus-1-dev
cargo install --git https://github.com/deactivated0/wlsecret.git wlsecret-daemon wlsecret-cli
sudo install -m 755 ~/.cargo/bin/wlsecret-daemon /usr/local/bin/
sudo install -m 755 ~/.cargo/bin/wlsecret-cli /usr/local/bin/
```

### 4. Fedora / RHEL / CentOS Stream
```bash
sudo dnf install -y gcc openssl-devel dbus-devel
cargo install --git https://github.com/deactivated0/wlsecret.git wlsecret-daemon wlsecret-cli
sudo install -m 755 ~/.cargo/bin/wlsecret-daemon /usr/local/bin/
sudo install -m 755 ~/.cargo/bin/wlsecret-cli /usr/local/bin/
```

### 5. openSUSE (Tumbleweed & Leap)
```bash
sudo zypper in -y gcc libopenssl-devel dbus-1-devel
cargo install --git https://github.com/deactivated0/wlsecret.git wlsecret-daemon wlsecret-cli
sudo install -m 755 ~/.cargo/bin/wlsecret-daemon /usr/local/bin/
sudo install -m 755 ~/.cargo/bin/wlsecret-cli /usr/local/bin/
```

### 6. Alpine Linux
```bash
sudo apk add gcc musl-dev openssl-dev dbus-dev
cargo install --git https://github.com/deactivated0/wlsecret.git wlsecret-daemon wlsecret-cli
sudo install -m 755 ~/.cargo/bin/wlsecret-daemon /usr/local/bin/
sudo install -m 755 ~/.cargo/bin/wlsecret-cli /usr/local/bin/
```

### 7. Gentoo Linux
```bash
emerge --ask dev-libs/openssl sys-apps/dbus
cargo install --git https://github.com/deactivated0/wlsecret.git wlsecret-daemon wlsecret-cli
sudo install -m 755 ~/.cargo/bin/wlsecret-daemon /usr/local/bin/
sudo install -m 755 ~/.cargo/bin/wlsecret-cli /usr/local/bin/
```

### 8. Void Linux
```bash
sudo xbps-install -Sy base-devel openssl-devel dbus-devel
cargo install --git https://github.com/deactivated0/wlsecret.git wlsecret-daemon wlsecret-cli
sudo install -m 755 ~/.cargo/bin/wlsecret-daemon /usr/local/bin/
sudo install -m 755 ~/.cargo/bin/wlsecret-cli /usr/local/bin/
```

### 9. FreeBSD
```bash
pkg install rust pkgconf openssl dbus
cargo install --git https://github.com/deactivated0/wlsecret.git wlsecret-daemon wlsecret-cli
install -m 755 ~/.cargo/bin/wlsecret-daemon /usr/local/bin/
install -m 755 ~/.cargo/bin/wlsecret-cli /usr/local/bin/
```

### 10. macOS
```bash
cargo install --git https://github.com/deactivated0/wlsecret.git wlsecret-cli
```

### 11. Windows
```powershell
cargo install --git https://github.com/deactivated0/wlsecret.git wlsecret-cli
```

---

## ⚙️ Service Autostart Configuration

### Systemd (User Service)
Create `~/.config/systemd/user/wlsecret-daemon.service`:
```ini
[Unit]
Description=Secret Service Daemon (wlsecret)
Documentation=https://github.com/deactivated0/wlsecret
PartOf=graphical-session.target

[Service]
ExecStart=/usr/local/bin/wlsecret-daemon
Restart=on-failure
Slice=session.slice

[Install]
WantedBy=graphical-session.target
```
Enable and start the service:
```bash
systemctl --user daemon-reload
systemctl --user enable --now wlsecret-daemon
```

### Dinit (User Service)
Create `~/.config/dinit.d/wlsecret-daemon`:
```ini
type = process
command = /usr/local/bin/wlsecret-daemon
smooth-recovery = true
restart = true
logfile = /dev/null
```
Start and link into boot:
```bash
dinitctl start wlsecret-daemon
ln -sf ~/.config/dinit.d/wlsecret-daemon ~/.config/dinit.d/boot.d/wlsecret-daemon
```

---

## 🛠️ CLI Usage Guide

```bash
# List all collections and lock status
wlsecret-cli list-collections

# Store a secret
echo "my_super_secret" | wlsecret-cli store 'Database Token' service=postgres user=admin

# Look up a secret
wlsecret-cli lookup service=postgres user=admin

# Search secrets with JSON output
wlsecret-cli search --json service=postgres

# Delete a secret
wlsecret-cli delete service=postgres user=admin

# Lock / Unlock collections manually
wlsecret-cli lock login
wlsecret-cli unlock login
```

### Standard `secret-tool` & `libsecret` Compatibility
```bash
echo "pass123" | secret-tool store --label="Test Secret" service test_app user john
secret-tool lookup service test_app user john
secret-tool clear service test_app user john
```

---

## 🔒 Security Architecture

- **Zeroization:** Sensitive private keys, symmetric keys, and secret values implement the `Zeroize` and `ZeroizeOnDrop` traits.
- **FIPS 140-3 Algorithmic Standards:**
  - Key Derivation: PBKDF2-HMAC-SHA256 (100,000+ iterations with 32-byte salt).
  - Storage Encryption: AES-128-CBC with PKCS#7 padding.
  - Key Exchange: RFC 3526 1024-bit MODP Group 2 Diffie-Hellman + HKDF-SHA256.
- **Sandboxed D-Bus IPC:** Peer process identification verifies PID/UID against Unix credentials (`SO_PEERCRED`) on D-Bus connections.

---

## 📜 License

Licensed under the **MIT License** ([LICENSE](LICENSE)).
