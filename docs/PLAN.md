# PLAN: TTS Party, Milestone M0 sampai M2

| Item | Isi |
|---|---|
| Versi | 0.1 (draft) |
| Rujukan | `docs/GDD.md` v0.2, `docs/SPEC.md` v0.1, `AGENTS.md` |
| Cakupan | M0 (setup), M1 (prototipe solo lokal), M2 (validasi server) |

Dokumen ini memecah SPEC menjadi tugas kecil yang dapat dikerjakan satu per satu. Bila PLAN dan SPEC berbeda, SPEC menang, lalu PLAN diperbarui.

---

## 1. Cara membaca dan memakai

**Ukuran**

| Kode | Arti |
|---|---|
| S | Kecil: kira-kira di bawah 100 baris, 1 sampai 2 file |
| M | Sedang: 100 sampai 250 baris, 2 sampai 4 file |
| L | Besar: lebih dari 250 baris. Pecah lagi bila memungkinkan (saran pemecahan tertera) |

**Jenis verifikasi**

| Tag | Arti |
|---|---|
| `[Auto]` | Dapat diverifikasi lewat `./scripts/check.sh` (Windows: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/check.ps1`) |
| `[Studio]` | Butuh Roblox Studio. **Dilakukan pengembang.** Agent hanya menyiapkan langkah ujinya |

**Aturan untuk setiap tugas (Definition of Done)**

- [ ] `./scripts/check.sh` hijau (Windows: gunakan `scripts/check.ps1`; setelah T0.6 selesai).
- [ ] Logika murni punya unit test.
- [ ] Satu tugas = satu cabang/PR atau beberapa commit kecil dengan pesan Conventional Commits.
- [ ] Dokumen terdampak diperbarui (SPEC/GDD/ADR).
- [ ] Laporan akhir sesuai `AGENTS.md` bagian 12 (yang diubah, verifikasi, belum diverifikasi di Studio, asumsi, langkah berikut).

**Prompt yang disarankan untuk Codex (per tugas)**

```
Kerjakan tugas T<ID> dari docs/PLAN.md. Baca docs/SPEC.md bagian terkait dan AGENTS.md.
Tulis test bersama implementasi. Jalankan `./scripts/check.sh` (Windows: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/check.ps1`).
Akhiri dengan laporan sesuai AGENTS.md bagian 12.
Jangan mengerjakan tugas lain.
```

---

## 2. Ringkasan tugas dan dependensi

| ID | Tugas | Ukuran | Bergantung pada | Verifikasi |
|---|---|---|---|---|
| T0.1 | Kerangka repositori | S | - | Auto |
| T0.2 | Toolchain Rokit + ADR-0002 | S | T0.1 | Auto |
| T0.3 | Project Rojo + skrip bootstrap | S | T0.1 | Auto + Studio |
| T0.4 | Konfigurasi format dan lint | S | T0.2 | Auto |
| T0.5 | Test runner + ADR-0001 | M | T0.2 | Auto |
| T0.6 | `scripts/check.sh` (PowerShell: `scripts/check.ps1`) | S | T0.4, T0.5 | Auto |
| T0.7 | AGENTS.md, docs, CI (opsional) | S | T0.6 | Auto |
| **CP0** | **Checkpoint M0** | | T0.1 sampai T0.7 | Studio |
| T1.1 | Tipe, konstanta, fixture, `WordUtils` | S | CP0 | Auto |
| T1.2 | `WheelLayout` | S | T1.1 | Auto |
| T1.3 | `GridLayout` | S | T1.1 | Auto |
| T1.4 | `DragSession` | M | T1.1, T1.2 | Auto |
| T1.5 | `MatchGui`: kerangka 70:30 | M | T1.3 | Studio |
| T1.6 | `GridView` | M | T1.3, T1.5 | Studio |
| T1.7 | `LetterWheel` | M | T1.2, T1.5 | Studio |
| T1.8 | `WheelInput` | L | T1.4, T1.7 | Studio |
| T1.9 | `MatchController` (stub lokal) | M | T1.6, T1.8 | Studio |
| **CP1** | **Checkpoint M1** | | T1.1 sampai T1.9 | Studio |
| T2.1 | `Remotes` + tipe snapshot | S | CP1 | Auto |
| T2.2 | `RateLimiter` | S | CP1 | Auto |
| T2.3 | `ValidationService.evaluate` | M | T2.1 | Auto |
| T2.4 | `SnapshotBuilder` | S | T2.1 | Auto |
| T2.5 | `PuzzleSchema` + `PuzzleService` | M | T2.1 | Auto + Studio |
| T2.6 | `MatchService` (sesi solo debug) | L | T2.2, T2.3, T2.4, T2.5 | Auto + Studio |
| T2.7 | Migrasi client ke server | M | T2.6 | Studio |
| T2.8 | Audit keamanan + uji exploit manual | S | T2.7 | Studio |
| **CP2** | **Checkpoint M2** | | T2.1 sampai T2.8 | Studio |

**Urutan dan paralelisme**

```
M0:  T0.1 -> T0.2 -> {T0.4, T0.5} -> T0.6 -> T0.7 -> CP0
     T0.1 -> T0.3 -----------------------------^
M1:  T1.1 -> {T1.2, T1.3} -> T1.4
     T1.3 -> T1.5 -> {T1.6, T1.7} -> T1.8 -> T1.9 -> CP1
M2:  T2.1 -> {T2.2, T2.3, T2.4, T2.5} -> T2.6 -> T2.7 -> T2.8 -> CP2
```

Tugas dalam kurung `{}` dapat dikerjakan paralel atau dalam urutan bebas.

---

## 3. Milestone M0: Setup Proyek

### T0.1 Kerangka repositori (S)

- Inisialisasi git, `.gitignore` (`build/`, `sourcemap.json`, `*.rbxl.lock`, berkas OS/editor).
- Buat struktur folder sesuai SPEC bagian 3 (gunakan `.gitkeep` untuk folder kosong).
- Salin `GDD.md` dan `SPEC.md` ke `docs/`, `PLAN.md` ke `docs/`, `AGENTS.md` ke root.
- `README.md` singkat (tujuan proyek, cara memulai).
- **Kriteria:** struktur folder sama dengan SPEC 3. Commit awal bersih.
- **Skill:** `$git-workflow-and-versioning`

### T0.2 Toolchain dan ADR-0002 (S)

- Pilih Rokit atau Aftman, buat `rokit.toml`/`aftman.toml` berisi Rojo, StyLua, Selene, Lune (dan luau-lsp bila tersedia lewat manajer).
- Tulis `docs/adr/0002-toolchain-manager.md` (konteks, keputusan, alasan, konsekuensi).
- **Kriteria:** di mesin bersih, `rokit install` memasang semua alat dan `rojo --version`, `stylua --version`, `selene --version`, `lune --version` berjalan.
- **Catatan:** verifikasi nama paket dan sintaks berkas konfigurasi ke dokumentasi manajer yang dipilih.
- **Skill:** `$source-driven-development`, `$documentation-and-adrs`

### T0.3 Project Rojo dan skrip bootstrap (S)

- Buat `default.project.json` sesuai SPEC 3.1.
- Buat `src/server/init.server.luau` dan `src/client/init.client.luau` (`--!strict`, masing-masing mencetak satu baris log).
- **Kriteria:**
  - [ ] `[Auto]` `rojo build -o build/TTSParty.rbxl` berhasil.
  - [ ] `[Studio]` `rojo serve` + plugin: skrip muncul di ReplicatedStorage/Shared, ServerScriptService/Server, StarterPlayerScripts/Client, ServerStorage/Puzzles. Saat Play, log server dan client muncul tanpa error.
- **Skill:** `$source-driven-development`

### T0.4 Konfigurasi format dan lint (S)

- `stylua.toml` (gaya konsisten: indentasi, lebar baris).
- `selene.toml` dan definisi standar library Roblox untuk Selene.
- **Kriteria:** `stylua --check src tests` dan `selene src tests` berjalan pada skrip bootstrap tanpa error.
- **Catatan:** cara membuat definisi std Roblox untuk Selene: verifikasi ke dokumentasi Selene.

### T0.5 Test runner dan ADR-0001 (M)

- Evaluasi opsi: Lune dengan runner ringan buatan sendiri, atau Jest-Lua. Pilih satu, tulis `docs/adr/0001-test-runner.md`.
- Buat `tests/run.luau` (menemukan dan menjalankan `tests/*.spec.luau`, menghitung lulus/gagal, exit code non-zero bila gagal).
- Tambah satu smoke test (`tests/smoke.spec.luau`) sebagai bukti runner bekerja. (SPEC menyebut contoh `WordUtils`, yang sebenarnya dikerjakan di T1.1.)
- **Kriteria:** `lune run tests/run` (atau padanannya) menjalankan smoke test dan lulus. Test yang sengaja dibuat gagal menghasilkan exit code non-zero.
- **Syarat runner:** dapat memuat modul `src/shared` di luar Studio. Bila `require` berbasis path Rojo bermasalah, dokumentasikan solusinya di ADR-0001.
- **Skill:** `$test-driven-development`, `$documentation-and-adrs`

### T0.6 `scripts/check.sh` dan pemeriksaan Windows (S)

- Jalankan berurutan: `stylua --check`, `selene`, analisis tipe (`rojo sourcemap` + `luau-lsp analyze`, bila tersedia), test.
- Di Windows tersedia padanan native `scripts/check.ps1`, dengan urutan pemeriksaan dan perilaku gagal yang sama.
- Berhenti dan exit non-zero pada kegagalan pertama, dengan pesan jelas.
- **Kriteria:** hijau pada repo bersih. Merah bila ada pelanggaran format, lint, tipe, atau test.
- **Skill:** `$ci-cd-and-automation` (prinsip saja)

### T0.7 AGENTS.md, dokumen, dan CI opsional (S)

- Pastikan `AGENTS.md` di root dan `docs/` lengkap. Perbarui baris "Status milestone saat ini".
- (Opsional; perlu persetujuan pengembang) GitHub Actions menjalankan `scripts/check.sh` pada push/PR. Workflow belum dibuat.
- **Kriteria:** dokumen terhubung dan tidak ada tautan/jalur yang salah. Bila CI dibuat, satu run hijau.

### CP0: Checkpoint M0

- [ ] `./scripts/check.sh` hijau di clone baru setelah `rokit install` (Windows: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/check.ps1`).
- [ ] `[Studio]` sinkron Rojo berhasil dan bootstrap berjalan tanpa error.
- [ ] ADR-0001 dan ADR-0002 ada.
- [ ] Perbarui status milestone di `AGENTS.md` menjadi M1.

---

## 4. Milestone M1: Prototipe Solo Lokal

Puzzle stub berjalan lokal di client. Ini satu-satunya tahap di mana jawaban boleh ada di client (SPEC 6).

### T1.1 Tipe, konstanta, fixture, `WordUtils` (S)

- `shared/Types.luau`: `Direction`, `PuzzleWord`, `Puzzle` (SPEC 6.1).
- `shared/Constants.luau`: mis. `MIN_WORD_LENGTH_DEFAULT`, `HIT_RADIUS_FACTOR = 1.2`.
- `puzzles/fixtures/test_puzzle_01.luau` sesuai SPEC 6.2.
- `shared/WordUtils.luau`: `normalize`, `canForm`, `isValidLength`.
- **Kriteria:** semua kasus test `WordUtils` di SPEC 9 lulus (huruf kecil, spasi, simbol, kosong, pas, kurang, berlebih, huruf kembar, huruf tidak ada).
- **Skill:** `$test-driven-development`

### T1.2 `WheelLayout` (S)

- `positions(count, radius)`: huruf pertama di atas, searah jarum jam, `angle = 2π * i / count - π/2`.
- `nearestLetter(points, pointer, hitRadius)`.
- **Kriteria:** test untuk count 4, 5, 6, 7 (jarak ke pusat sama dengan radius, sudut merata, huruf pertama di atas). `nearestLetter`: di dalam radius, di luar radius, dua kandidat (ambil terdekat).

### T1.3 `GridLayout` (S)

- `computeCellSize(panelW, panelH, rows, cols, gap)`: sel persegi terbesar yang membuat grid muat.
- **Kriteria:** test grid 3x4, 5x5, 15x15, panel lebar dan panel tinggi, gap 0 dan gap positif. Grid tidak pernah melebihi panel.

### T1.4 `DragSession` (M)

- Aksi: `begin`, `move`, `finish`, `cancel` sesuai SPEC 6.3 (satu huruf sekali per sesi, backtrack ke huruf kedua terakhir, huruf kembar dianggap node berbeda).
- Tidak memakai Roblox API. Posisi berupa `{ x, y }`.
- **Kriteria:** test: pilih satu, tambah, backtrack, tidak memilih dua kali, `finish` di bawah minimum menghasilkan `nil`, `finish` di atas minimum menghasilkan kata, `cancel` mereset, `begin` di luar radius diabaikan.

> **Checkpoint kecil (setelah T1.1 sampai T1.4):** semua modul murni M1 lulus test dan `check.sh` hijau, sebelum mulai UI.

### T1.5 `MatchGui`: kerangka layout 70:30 (M)

- `ScreenGui` `MatchGui` (`ResetOnSpawn = false`, `ScreenInsets = DeviceSafeInsets`), `TopBar`, `GridPanel` `{0.7, 0, 0.9, 0}`, `WheelPanel` `{0.3, 0, 0.9, 0}`. Semua Scale.
- Konten placeholder (label timer dan clue).
- Pengaturan orientasi game (`LandscapeSensor`) dicatat untuk dilakukan pengembang di pengaturan game.
- **Kriteria `[Studio]`:** rasio 70:30 tampil benar di ponsel kecil, ponsel besar, tablet, PC 16:9 dan 21:9. Tidak ada elemen tertutup notch/safe area.
- **Skill:** `$frontend-ui-engineering` (prinsip responsif saja)

### T1.6 `GridView` (M)

- Render grid dari `Puzzle` stub memakai `GridLayout.computeCellSize`, di dalam kontainer ber-`UIAspectRatioConstraint`. Kotak kosong tidak digambar.
- Tap kotak menyorot kata yang memuatnya dan menampilkan clue di `TopBar`.
- API: `setSolved(slotIndex, letters)` untuk mengisi huruf.
- **Kriteria `[Studio]`:** grid fixture 3x4 tampil benar dan terpusat. Tap menyorot slot dan menampilkan clue. Uji juga dengan fixture besar sementara (mis. 8x8) untuk memastikan layout skala.

### T1.7 `LetterWheel` (M)

- Render huruf pada lingkaran memakai `WheelLayout.positions`. Label pratinjau kata di atas lingkaran.
- Tombol **Acak** (mengacak urutan tampilan lokal) dan **Hint** (placeholder tanpa fungsi).
- API: `getLetterCenters()`, `setPreview(text)`, `setSelected(indices)`.
- **Kriteria `[Studio]`:** lingkaran 1:1 di tengah `WheelPanel` untuk 4 sampai 7 huruf. Acak mengubah tata letak tanpa mengubah puzzle.

### T1.8 `WheelInput` (L)

- Tangani `InputBegan/Changed/Ended` untuk `MouseButton1` dan `Touch`. Abaikan touch tambahan saat seretan aktif.
- Hubungkan ke `DragSession`. Radius hit = 1.2 x radius visual. Hit-test memakai jarak, bukan hover.
- Garis penghubung dengan pooling (tidak membuat objek baru tiap frame), termasuk segmen ke pointer.
- `WheelPanel.Active = true` dan serap input agar avatar/kamera tidak bergerak.
- **Saran pemecahan bila terlalu besar:** T1.8a (hit-test + `DragSession` + pratinjau), T1.8b (garis penghubung + penyerapan input).
- **Kriteria `[Studio]`:** seret dengan mouse dan touch (emulator dan minimal satu perangkat asli), backtrack berfungsi, lepas di luar lingkaran tidak error, seretan tidak menggerakkan avatar/kamera, tidak patah-patah di ponsel kelas menengah.

### T1.9 `MatchController` dengan stub lokal (M)

- Muat fixture puzzle secara lokal, hubungkan `WheelInput`, `GridView`, `LetterWheel`.
- Saat `finish` menghasilkan kata: cek lokal (`canForm` + cocok slot). Benar: isi grid. Salah: efek getar. Bonus: penanda sederhana.
- **Tandai jelas** seluruh kode stub (komentar `-- STUB M1: hapus di T2.7`) agar mudah dihapus.
- **Kriteria `[Studio]`:** `SAPI`, `PIA`, `PAS` mengisi grid, `API` dikenali sebagai bonus, `KUDA` memicu getar.

### CP1: Checkpoint M1

- [ ] `check.sh` hijau. Semua modul murni punya test.
- [ ] Semua kriteria `[Studio]` T1.5 sampai T1.9 lolos.
- [ ] Uji di minimal satu perangkat sentuh asli.
- [ ] Catat temuan masalah ergonomi (ukuran huruf, radius hit) untuk penyetelan.
- [ ] Perbarui status milestone di `AGENTS.md` menjadi M2.

---

## 5. Milestone M2: Validasi Server

### T2.1 `Remotes` dan tipe snapshot (S)

- Tambah ke `Types.luau`: `SlotView`, `Snapshot`, `RejectReason` (SPEC 7.2 dan 7.3).
- `shared/Remotes.luau`: definisi nama remote dan pembuatan `RemoteEvent` oleh server (`Match_SubmitWord`, `Match_Snapshot`, `Match_WordAccepted`, `Match_BonusFound`, `Match_WordRejected`), akses aman dari client.
- **Kriteria:** tipe lolos analisis tipe. Nama remote hanya didefinisikan di satu tempat.
- **Skill:** `$api-and-interface-design`

### T2.2 `RateLimiter` (S)

- Token bucket per pemain (kapasitas 5, isi ulang 3/detik, konstanta di `Constants`). Jam disuntikkan.
- **Kriteria:** test: burst lalu tolak, isi ulang seiring waktu (jam palsu), tidak melebihi kapasitas, pembersihan pemain yang keluar.

### T2.3 `ValidationService.evaluate` (M)

- Fungsi murni sesuai urutan SPEC 7.4. Menangani kata yang cocok dengan lebih dari satu slot.
- **Kriteria:** test untuk `NotSeated`, `WrongState`, `TooShort`, `InvalidLetters` (termasuk panjang berlebih dan karakter tidak valid), `AlreadySolved` (slot dan bonus), `NotAWord`, accepted, bonus, dan kata sama di dua slot.
- **Catatan:** `RateLimited` diputuskan di luar fungsi murni (oleh `MatchService`), tapi tipe hasilnya tetap dikenali.
- **Skill:** `$test-driven-development`, `$security-and-hardening`

### T2.4 `SnapshotBuilder` (S)

- Modul murni `server/SnapshotBuilder.luau`: membangun `Snapshot` dari puzzle dan state sesi.
- **Kriteria:** test bahwa snapshot **tidak mengandung key `word`**, slot belum solved tidak punya `letters`, slot solved punya `letters` dan `solvedBy`.
- **Catatan:** file ini menambah SPEC bagian 3. Perbarui SPEC.

### T2.5 `PuzzleSchema` dan `PuzzleService` (M)

- `server/PuzzleSchema.luau` (murni): validasi skema puzzle (kolom dalam batas grid, semua kata dapat dibentuk dari `letters`, persilangan konsisten, tidak ada dua kata menimpa huruf berbeda, tidak ada duplikat, `minWordLength` valid).
- `server/PuzzleService.luau`: memuat puzzle dari `ServerStorage/Puzzles`, memvalidasi saat start, menolak yang tidak valid dengan log jelas.
- **Kriteria:** `[Auto]` test skema (valid lolos, kata tidak dapat dibentuk gagal, persilangan konflik gagal, di luar grid gagal). `[Studio]` fixture terbaca dari ServerStorage saat Play.
- **Catatan:** file ini menambah SPEC bagian 3. Perbarui SPEC.

### T2.6 `MatchService`: sesi solo debug (L)

- Saat `PlayerAdded` (dan pemain yang sudah ada): buat sesi `tableId = "debug-<UserId>"` bila `Constants.DEBUG_SOLO_SESSION` aktif. Kirim `Match_Snapshot`.
- Handler `Match_SubmitWord`: cek tipe payload (string, panjang wajar), rate limit, `evaluate`, perbarui state dan skor, kirim `WordAccepted`/`BonusFound`/`WordRejected`.
- `PlayerRemoving`: bersihkan sesi dan bucket rate limiter.
- Log peringatan (dengan `UserId`) untuk payload salah tipe atau `RateLimited` berulang.
- **Saran pemecahan:** T2.6a (pembuatan sesi + snapshot), T2.6b (handler submit + rate limit + hasil), T2.6c (lifecycle dan log).
- **Kriteria:** `[Auto]` logika pemilihan hasil/perubahan state diuji lewat modul murni. `[Studio]` di Play: remote merespons benar untuk kata benar, bonus, salah, ulang, dan spam cepat tanpa error.
- **Skill:** `$security-and-hardening`, `$doubt-driven-development`

### T2.7 Migrasi client ke server (M)

- Hapus puzzle stub dan pengecekan lokal dari `MatchController` (semua kode bertanda `STUB M1`).
- Client: render `Snapshot`, kirim `Match_SubmitWord`, render hasil dari remote.
- Pastikan tidak ada modul di `ReplicatedStorage` yang berisi data jawaban.
- **Kriteria `[Studio]`:** alur akhir-ke-akhir sesuai SPEC 7.8: `SAPI` mengisi baris pertama, `PIA` dan `PAS` mengisi sisanya, `API` bonus, `KUDA` ditolak. Tidak ada sisa kode stub (`grep "STUB M1"` kosong).

### T2.8 Audit keamanan dan uji exploit manual (S)

- Minta review `security-auditor` (atau sudut pandang setara) untuk `MatchService`, `ValidationService`, `Remotes`.
- **Checklist `[Studio]`:**
  - [ ] Dari client (command bar/skrip uji), `ReplicatedStorage` tidak memuat jawaban.
  - [ ] `Match_SubmitWord` dengan tipe salah, string sangat panjang, `tableId` milik orang lain, dan spam cepat: server tetap stabil dan merespons/menolak dengan benar.
  - [ ] Tidak ada warning/error di Output selama 5 menit bermain.
- **Kriteria:** temuan dicatat dan diperbaiki, atau dicatat sebagai risiko yang diterima.

### CP2: Checkpoint M2

- [ ] `check.sh` hijau, semua test M2 lulus (SPEC 7.8).
- [ ] Semua kriteria `[Studio]` T2.5 sampai T2.8 lolos.
- [ ] Stub M1 sudah hilang dari client.
- [ ] SPEC diperbarui (SnapshotBuilder, PuzzleSchema, penyesuaian lain).
- [ ] Perbarui status milestone di `AGENTS.md` menjadi M3 dan mulai `SPEC.md` untuk M3 sampai M5.

---

## 6. Risiko dan hal yang perlu dijaga

| Risiko | Antisipasi |
|---|---|
| Sintaks/flag alat tidak sesuai rencana | Verifikasi di T0.2, T0.4, T0.5, perbarui `AGENTS.md` dan SPEC 2 |
| `require` modul `src/shared` dari runner di luar Studio bermasalah | Putuskan di ADR-0001 (T0.5), jangan menunda ke M1 |
| T1.8 dan T2.6 terlalu besar untuk satu sesi agent | Pecah sesuai saran a/b/c |
| Perilaku touch di emulator berbeda dari perangkat asli | Uji perangkat asli di CP1, bukan hanya emulator |
| Stub M1 tertinggal | Komentar `STUB M1` + `grep` di T2.7 |
| Fixture terlalu kecil | Tambah fixture besar sementara untuk uji layout (T1.6) |

## 7. Setelah M2

Buat `SPEC.md` untuk M3 sampai M5 (meja 1/2/4 kursi, state machine, Team, Duel FFA/1v1), lalu `PLAN.md` lanjutan. Dua hal yang sebaiknya diputuskan sebelum M3: penamaan/warna kursi tim 2v2 dan tampilan papan status meja.
