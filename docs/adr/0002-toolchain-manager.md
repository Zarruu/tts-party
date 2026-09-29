# ADR-0002: Rokit untuk toolchain proyek

## Status

Accepted

## Date

2026-09-29

## Context

TTS Party memerlukan versi Rojo, StyLua, Selene, Lune, dan luau-lsp yang
reprodusibel di Windows serta dapat dipasang dengan satu perintah. SPEC bagian
2 masih membuka pilihan antara Rokit dan Aftman.

## Decision

Gunakan Rokit dengan versi eksplisit dalam `rokit.toml`. Jalankan
`rokit install` dari root proyek, lalu periksa `rojo --version`,
`stylua --version`, `selene --version`, `lune --version`, dan
`luau-lsp --version`. Versi yang dipin harus diperbarui secara sengaja,
setelah diuji bersama.

## Alternatives considered

**Aftman** juga memakai tabel `[tools]`, mendukung Windows, dan menjalankan
`aftman install`. Namun, repositori resminya telah diarsipkan dan pembuatnya
merekomendasikan pengganti. Rokit adalah manajer yang dikelola oleh organisasi
Rojo, menyediakan pemasangan Windows, dan mendukung manifes Aftman. Karena
itu Rokit lebih tepat untuk proyek baru ini.

## Consequences

- Kontributor perlu memasang Rokit terlebih dahulu dan menyediakan akses
  jaringan saat pertama kali menjalankan `rokit install`.
- Versi alat seragam antar mesin; pembaruan perlu mengubah manifes dan menguji
  kembali seluruh pemeriksaan proyek.
- `rokit install` berhasil pada Windows ini. Rojo 7.7.0, StyLua 2.3.0, Selene 0.30.1, Lune 0.10.4, dan luau-lsp 1.54.0 terverifikasi.
- Plugin Studio 7.6.0-Boatly meminta protokol 5. Rojo 7.5.0 dan 7.6.1 yang diuji masih melaporkan protokol 4. Server Rojo 7.7.0 melaporkan protokol 5 dan berhasil membangun place; plugin terkelola resmi Rojo 7.7.0 dipasang dengan `rojo plugin install` setelah plugin lama dicadangkan di `build/`. Koneksi Studio tetap perlu diuji ulang setelah Studio dimulai kembali.
- Ada laporan masalah pemantauan file baru pada Rojo 7.7.0 di Windows. Jika perubahan baru tidak muncul saat `rojo serve` berjalan, mulai ulang server dan catat hasil uji Studio.

## Sources

- [Rokit README](https://github.com/rojo-rbx/rokit): sintaks, pemasangan
  Windows, `rokit install`, dan kompatibilitas Aftman.
- [Aftman README](https://github.com/LPGhatguy/aftman): sintaks manifes,
  platform Windows, dan status arsip.
- [Rojo 7.7.0 release](https://github.com/rojo-rbx/rojo/releases/tag/v7.7.0): spesifikasi
  paket `rojo-rbx/rojo@7.7.0` untuk Rokit.
- [Lune rokit.toml](https://github.com/lune-org/lune/blob/main/rokit.toml):
  contoh resmi paket Lune, StyLua, dan luau-lsp.
- [Rojo Windows watcher report](https://github.com/rojo-rbx/rojo/issues/1300): risiko pemantauan file baru pada 7.7.0.
- [Selene releases](https://github.com/Kampfkarren/selene/releases):
  rilis alat lint.

