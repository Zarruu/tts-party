# ADR-0001: Lune dengan runner ringan untuk unit test

## Status

Accepted oleh pengembang. Second opinion lintas model dilewati atas pilihannya.

## Date

2026-09-29

## Context

PLAN T0.5 dan SPEC bagian 9 membutuhkan test Luau murni di luar Studio,
termasuk memuat sumber asli dari src/shared lewat path. Lune 0.10.4 sudah
dipin dalam rokit.toml; tidak diperlukan paket baru. WordUtils tetap T1.1.

## Decision

Gunakan tests/run.luau dengan Lune 0.10.4. Dari root repo, jalankan
`lune run tests/run`.

- Discovery hanya file langsung tests/*.spec.luau, diurutkan berdasarkan nama.
- Setiap spec mengembalikan tabel nama test -> fungsi tanpa argumen.
  Nama harus string tidak kosong, nilai harus fungsi, dan tabel tidak kosong.
- Kasus dijalankan berurutan berdasarkan nama. Assertion memakai assert
  dengan pesan yang menjelaskan hasil yang diharapkan.
- Runner menghitung kasus lulus/gagal; kegagalan pemuatan atau kontrak spec
  dihitung sebagai satu kegagalan tambahan. Spec lain tetap dijalankan.
- Discovery gagal atau tidak menemukan spec menghasilkan kegagalan.
  Exit 0 hanya saat seluruh pemeriksaan lulus; kegagalan menghasilkan exit 1.
- Runner mendukung test sinkron saja. Jangan melepas task/coroutine/Promise
  yang berjalan setelah fungsi test kembali. Tidak ada timeout atau mocking.

## Memuat modul dan isolasi

Smoke spec memakai require("../src/shared/ProjectInfo") untuk memuat file
produksi langsung. ProjectInfo hanya metadata publik nama game, tanpa API
Roblox, jawaban puzzle, atau logika gameplay. Ini bukti integrasi loader,
bukan test fitur gameplay dan bukan pengganti kasus SPEC bagian 9.

Path require relatif terhadap file pemanggil; filesystem discovery relatif
terhadap working directory, sehingga perintah wajib dijalankan dari root.
Gunakan slash maju dan kapitalisasi nama yang tepat. Runner menghapus hanya
akhiran .luau saat memuat spec. Tidak ada salinan sumber, rewrite require,
atau emulasi DataModel. Rojo project/sourcemap tidak mengatur loader Lune.

Modul murni tidak boleh bergantung pada script.Parent, game, Instance, atau
library @lune. Untuk dependensi produksi gunakan injeksi dari lapisan pemanggil,
atau impor yang sudah dibuktikan kompatibel pada kedua runtime. Path filesystem
lintas folder belum tentu cocok dengan hierarki hasil Rojo di Studio.
Impor leaf ProjectInfo sudah dibuktikan; rantai dependensi produksi masa depan
harus diuji tersendiri, dan kompatibilitas Studio belum diverifikasi.

Require memakai cache. Setiap test membuat state melalui konstruktor/fixture
sendiri; runner tidak mengosongkan cache dan tidak menjanjikan isolasi otomatis.
Dua risiko ini menerima temuan reviewer: pembuktian impor transitif diperlukan
saat dependensinya ada, dan state mutable harus dikelola eksplisit per kasus.

## Alternatives considered

- Jest-Lua: matcher dan mocking lengkap, tetapi README resmi menyebut runtime
  yang didukung hanya Roblox. Porting ke Lune di luar cakupan T0.5.
- TestEZ + Lemur: mendukung lingkungan di luar Roblox, tetapi Lemur memakai
  Lua 5.1/LuaJIT, bukan runtime Luau bertipe. Emulasi menambah pekerjaan;
  kedua repositori telah diarsipkan.

## Consequences

Runner kecil tanpa dependensi baru, namun kontrak dan pelaporannya dirawat
proyek. Tidak ada dukungan async, coverage, atau isolasi proses per kasus.
Test Studio, UI, input, dan multi-client tetap dijalankan pengembang.

## Verification at T0.5

Pada Windows dengan Lune 0.10.4:

- Sebelum ProjectInfo tersedia: 0 passed, 1 failed, exit 1 (kegagalan impor).
- Smoke memuat ProjectInfo: 1 passed, 0 failed, exit 0.
- Expected name sementara diganti menjadi INTENTIONAL FAILURE:
  0 passed, 1 failed, exit 1; kemudian file dipulihkan dan kembali exit 0.
- Probe spec kosong sementara: 1 passed, 1 failed, exit 1; smoke tetap dijalankan.
- stylua --check src tests: exit 0; selene src tests: exit 0, tanpa error/warning.
- Pada T0.5, `scripts/check.sh` memang belum tersedia; hasil setelah T0.6 dicatat di bawah.

Untuk mengulang bukti negatif, ubah sementara expected name dalam smoke spec,
jalankan runner, periksa $LASTEXITCODE di PowerShell, lalu pulihkan dan jalankan
lagi. Jangan menyimpan assertion yang sengaja salah.

## Verifikasi setelah T0.6

Di Windows, `scripts/check.sh` (Git Bash) dan `scripts/check.ps1` sama-sama
lulus pada repo ini. Keduanya gagal di tahap format saat format dirusak dan
mengembalikan exit non-zero saat test sengaja gagal. Setelah probe dibersihkan,
keduanya kembali hijau dengan satu smoke test lulus. Analisis tipe mengembalikan
exit 0 tetapi memperingatkan bahwa definisi Roblox belum dikonfigurasi; cek API
Roblox perlu dievaluasi setelah konfigurasi tipe tersedia.

## Sources

- [Lune modules](https://lune-org.github.io/docs/the-book/7-modules/): path dan cache require.
- [Lune fs](https://lune-org.github.io/docs/api-reference/fs/): readDir dan isFile.
- [Lune process](https://lune-org.github.io/docs/api-reference/process/): exit code.
- [Jest-Lua](https://github.com/jsdotlua/jest-lua): batas runtime Roblox.
- [TestEZ](https://github.com/Roblox/testez): integrasi Lemur dan status arsip.
- [Lemur](https://github.com/LPGhatguy/lemur): runtime Lua 5.1/LuaJIT.
