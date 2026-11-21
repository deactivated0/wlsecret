---
name: wlsecret-maintenance
description: Guide and instructions for AI agents and developers maintaining, optimizing, and releasing the wlsecret Secret Service codebase.
---

# wlsecret Repository Maintenance & Architecture Guide

This skill guide provides complete instructions for autonomous AI agents and systems engineers to maintain, profile, optimize, test, and release the `wlsecret` Secret Service workspace.

---

## 1. Workspace Architecture

`wlsecret` is a pure Rust implementation of the FreeDesktop Secret Service specification (`org.freedesktop.secrets`). The Cargo workspace is divided into modular crates:

| Crate | Directory | Purpose | Key Responsibilities |
|---|---|---|---|
| `oo7` / `wlsecret` | `client/` | Client Library | Key derivation (PBKDF2), AES-128-CBC encryption, GVariant serialization, file & D-Bus clients |
| `wlsecret-daemon` | `server/` | Service Daemon | FreeDesktop D-Bus interface (`org.freedesktop.secrets`), GNOME Keyring compatibility, session & prompt management |
| `wlsecret-cli` | `cli/` | Command Line Interface | User-facing terminal tool (`store`, `lookup`, `search`, `list`, `unlock`, `lock`, `migrate`) |
| `oo7-pam` | `pam/` | PAM Module | PAM module (`pam_oo7.so`) for unlocking the `login` keyring automatically on login |
| `kwallet-parser` | `kwallet/parser/` | Migration Parser | Parser for legacy KDE KWallet (`.kwl`) files to auto-migrate to wlsecret |
| `cargo-credential-oo7` | `cargo-credential/`| Cargo Plugin | Cargo registry credential provider backed by `wlsecret` |
| `git-credential-oo7` | `git-credential/`| Git Helper | Git credential helper replacing `git-credential-libsecret` |

---

## 2. Critical Invariants (DO NOT BREAK)

### 2.1 File & Wire Compatibility
- **GVariant File Layout:** v1 keyring files (`~/.local/share/keyrings/v1/*.keyring`) begin with header `GnomeKeyring\n\r\0\n` followed by versions `(1, 0)` and GVariant tuple `(uayutua(a{say}ay))`. Never alter this binary schema.
- **Crypto Specifications (FIPS 140-3 Compliant):**
  - **Cipher:** AES-128-CBC with PKCS#7 padding.
  - **Key Derivation:** PBKDF2-HMAC-SHA256 (minimum 100,000 iterations, 32-byte salt).
  - **MAC:** HMAC-SHA256 for attribute indexing and ciphertext authentication.
  - **Key Exchange:** RFC 3526 1024-bit MODP Group 2 Diffie-Hellman + HKDF-SHA256.

### 2.2 Behavior & D-Bus Contracts
- **D-Bus Object Paths:** Always maintain `/org/freedesktop/secrets`, `/org/freedesktop/secrets/collection/<name>`, and `/org/freedesktop/secrets/session/<id>`.
- **GNOME Keyring Fallback:** Maintain `org.gnome.keyring.InternalUnsupportedGuiltRiddenInterface` so legacy GNOME apps and helpers remain functional.
- **Passwordless Keyrings:** Keyrings initialized without a secret (`secret: None`) must be automatically unlocked on daemon startup so headless/minimal compositors (`labwc`, `sway`, `hyprland`) operate without blocking on missing GUI prompters.

---

## 3. Performance & Memory Guidelines

When modifying code in `client/` or `server/`, adhere strictly to these performance rules:

1. **Query Precomputation (`PreparedQuery`):**
   - In `client/src/file/api/encrypted_item.rs` and `client/src/file/api/mod.rs`, searches must use `PreparedQuery::new(attributes, key)`.
   - Never recompute HMACs or schema tags in per-item loops.
2. **Zero-Copy Decryption:**
   - `EncryptedItem::decrypt(&self, ...)` takes `&self`. Callers must never clone `EncryptedItem` before decrypting.
3. **In-Place Cipher Buffers:**
   - In `client/src/crypto/native.rs`, mutate destination vectors in-place using `blob.truncate(len)` / `data.truncate(len)` rather than calling `.to_vec()` on decrypted slices.
4. **Connection Pooling:**
   - In `server/src/session.rs`, reuse static `tokio::sync::OnceCell<zbus::Connection>` instances for system and session bus queries. Never spawn transient D-Bus connections.
5. **Private Key Zeroization:**
   - Any sensitive big integer or key buffer must be wrapped in `Zeroizing` or explicitly scrubbed with `exp.zeroize()` before dropping.

---

## 4. Routine Maintenance Workflows

### 4.1 Running Static Analysis
```bash
cargo clippy --workspace --all-targets -- -D warnings
```
Ensure zero clippy warnings exist across the workspace.

### 4.2 Running Full Test Suites
```bash
# Run all workspace test suites (excluding PAM integration which needs root/cdylib harness)
cargo test --workspace --exclude oo7-pam

# Run PAM module unit tests
cargo test -p oo7-pam
```

### 4.3 Building Optimized Production Binaries
```bash
# Uses the [profile.release] with fat LTO and abort-panic defined in root Cargo.toml
cargo build --release -p wlsecret-daemon -p wlsecret-cli

# Install binaries to system path
sudo install -m 755 target/release/wlsecret-daemon /usr/local/bin/wlsecret-daemon
sudo install -m 755 target/release/wlsecret-cli /usr/local/bin/wlsecret-cli
sudo ln -sf /usr/local/bin/wlsecret-daemon /usr/local/bin/oo7-daemon
sudo ln -sf /usr/local/bin/wlsecret-cli /usr/local/bin/oo7-cli
```

### 4.4 Verifying Secret Service D-Bus Communication
```bash
# Inspect registered D-Bus interfaces
busctl --user introspect org.freedesktop.secrets /org/freedesktop/secrets

# Test round-trip storage, retrieval, and deletion
echo "testsecret" | secret-tool store --label="Test Item" service test account user
secret-tool lookup service test account user
secret-tool clear service test account user
```

---

## 5. Release Workflow

1. Bump version numbers across `Cargo.toml` and workspace member manifests.
2. Ensure `Cargo.lock` is up-to-date:
   ```bash
   cargo check --workspace
   ```
3. Tag the release:
   ```bash
   git tag -a v0.8.0 -m "Release v0.8.0"
   git push origin v0.8.0
   ```
4. GitHub Actions will trigger `.github/workflows/release.yml`, building multi-platform binaries (Linux x86_64, Linux ARM64, macOS, Windows, FreeBSD) and publishing the GitHub Release with SHA256 checksums automatically.
