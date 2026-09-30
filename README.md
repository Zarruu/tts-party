# TTS Party

TTS Party adalah game Roblox teka-teki silang dengan gameplay word connect:
pemain menyeret huruf untuk mengisi kata pada papan TTS. Proyek ini memakai
Luau strict, Rojo, dan Roblox Studio.

## Memulai

Pasang toolchain yang versinya dipin di `rokit.toml` dengan `rokit install`
(diperlukan Rokit di PATH). Keputusan dan versi alat ada di
[`docs/adr/0002-toolchain-manager.md`](docs/adr/0002-toolchain-manager.md).

Jalankan pemeriksaan dari root repo:

- Bash/Git Bash: `./scripts/check.sh`
- Windows PowerShell: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/check.ps1`

Untuk build, jalankan `rojo build -o build/TTSParty.rbxl`. Untuk sync ke Studio,
jalankan `rojo serve`, lalu sambungkan plugin Rojo. Panduan arsitektur ada di
[`docs/SPEC.md`](docs/SPEC.md), rencana tugas di [`docs/PLAN.md`](docs/PLAN.md),
dan aturan kontribusi di [`AGENTS.md`](AGENTS.md). Test runner dijelaskan di
[`docs/adr/0001-test-runner.md`](docs/adr/0001-test-runner.md).

