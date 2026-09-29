# AGENTS.md: TTS Party

Panduan kerja untuk agent AI (Codex) dan kontributor. Baca seluruhnya sebelum mengubah apa pun.

## 1. Tentang proyek

Game Roblox: teka-teki silang (TTS) dengan gameplay word connect (seret huruf ke huruf). Pemain duduk di meja lalu bermain **Team** (kerja sama) atau **Duel** (berebut kata). Landscape, UI 70:30 (grid TTS 70%, lingkaran huruf 30%), harus nyaman di PC dan mobile. Bahasa konten: Indonesia.

**Stack:** Roblox Studio, Luau (`--!strict`), Rojo, VS Code.

**Status milestone saat ini:** M0 (setup proyek). *Perbarui baris ini setiap pindah milestone.*

## 2. Dokumen rujukan (baca dulu)

| Dokumen | Isi |
|---|---|
| `docs/GDD.md` | *Apa* yang dibangun: visi, aturan game, mode, UI, keputusan |
| `docs/SPEC.md` | *Bagaimana dan kapan selesai* untuk M0 sampai M2: tipe data, kontrak remote, kriteria selesai |
| `docs/PLAN.md` | Pecahan tugas (bila sudah dibuat) |
| `docs/adr/` | Catatan keputusan arsitektur |

Bila dokumen bertentangan dengan kode atau permintaan, **tanyakan** dan jangan menebak. GDD menentukan perilaku game, SPEC menentukan teknis, dan permintaan eksplisit pengembang menang atas keduanya (lalu dokumen diperbarui).

## 3. Perintah

Sintaks dapat berubah. Verifikasi ke dokumentasi resmi tiap alat, lalu perbarui bagian ini.

| Tujuan | Perintah |
|---|---|
| Pasang alat | `rokit install` (atau `aftman install`) |
| Sinkron ke Studio | `rojo serve` |
| Build place | `rojo build -o build/TTSParty.rbxl` |
| Format | `stylua src tests` |
| Lint | `selene src tests` |
| Analisis tipe | `rojo sourcemap default.project.json -o sourcemap.json` lalu `luau-lsp analyze --sourcemap sourcemap.json src` |
| Unit test | `lune run tests/run` (runner final: lihat ADR-0001) |
| **Semua pemeriksaan** | Bash: `./scripts/check.sh`; Windows PowerShell: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/check.ps1` |

`./scripts/check.sh` wajib hijau sebelum commit dan sebelum melaporkan tugas selesai.
Di Windows, jalankan `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/check.ps1` dari root repo; skrip juga berpindah ke root secara otomatis.
Kedua skrip menjalankan pemeriksaan yang sama; analisis tipe dilewati hanya bila
`rojo` atau `luau-lsp` tidak tersedia di PATH.

## 4. Struktur proyek

```
src/shared/   -> ReplicatedStorage/Shared   (tipe, konstanta, remote, modul murni)
src/server/   -> ServerScriptService/Server (layanan server)
src/client/   -> StarterPlayerScripts/Client (UI, input, controller)
puzzles/      -> ServerStorage/Puzzles       (data puzzle, SERVER-ONLY)
assets/       -> model .rbxm dari Studio (meja, dll.)
tools/        -> skrip luar Roblox (generator/validator puzzle, Python)
tests/        -> *.spec.luau
docs/         -> GDD, SPEC, PLAN, adr/
```

Tempatkan kode di lapisan yang benar:

- Dapat dilihat client (semua di `src/shared` dan `src/client`) **tidak boleh** berisi rahasia (jawaban puzzle, logika penilaian yang menentukan hasil).
- Data puzzle hanya di `puzzles/` (ServerStorage).

## 5. Aturan kode

- `--!strict` di setiap file Luau. Tipe publik di `shared/Types.luau`.
- Identifier bahasa Inggris. Komentar dan dokumen boleh bahasa Indonesia.
- Modul `PascalCase.luau`, fungsi/variabel `camelCase`, konstanta `UPPER_SNAKE_CASE`.
- Gunakan `task.wait`, `task.spawn`, `task.delay`, `task.defer`. **Jangan** `wait`, `spawn`, `delay`.
- Ambil service lewat `game:GetService("Nama")`. Tidak ada `_G` dan tidak ada variabel global.
- Saat membuat Instance lewat kode, atur `Parent` **terakhir** setelah properti lain.
- `Players.PlayerAdded` harus juga menangani pemain yang sudah ada (`for _, p in Players:GetPlayers()`), karena di Studio pemain bisa masuk sebelum skrip terhubung.
- Fungsi pendek (kira-kira di bawah 50 baris), satu modul satu tanggung jawab.
- Bungkus operasi yang dapat gagal (DataStore, HTTP, dll.) dengan `pcall` dan tangani kegagalannya secara eksplisit.
- UI: pakai **Scale**, bukan Offset. Grid TTS pakai `UIAspectRatioConstraint`. Buat UI sekali lalu pakai ulang (pooling), hindari alokasi per frame.
- Jangan tinggalkan `print` debug. Pakai fungsi log terpusat (bila sudah ada) atau hapus sebelum commit.

### Modul murni

Logika yang bisa dipisah dari Roblox (validasi kata, layout, sesi seretan, rate limiter, skor, state machine) ditulis sebagai **modul murni**:

- Tidak memakai `game`, `Instance`, `Vector2`, `tick`, atau API Roblox lain.
- Memakai tabel biasa (`{ x: number, y: number }`) dan menyuntikkan ketergantungan (mis. fungsi jam).
- Wajib punya unit test.

## 6. Arsitektur: aturan yang tidak boleh dilanggar

1. **Server-authoritative.** Server memegang puzzle, state, skor, timer, koin. Client hanya merender dan mengirim niat.
2. **Jawaban tidak pernah dikirim ke client sebelum ditemukan.** Snapshot tidak boleh berisi field `word`. Letter sebuah slot hanya dikirim setelah slot itu terpecahkan.
3. **Kontrak remote hanya di `shared/Remotes.luau`.** Menambah/mengubah remote berarti memperbarui `docs/SPEC.md` (dan GDD bila perlu).
4. **Semua input dari client dianggap tidak tepercaya.** Periksa tipe, panjang, keanggotaan pemain di meja/sesi, state yang berlaku, dan rate limit. Tolak tanpa efek samping bila tidak valid.
5. **Server tidak memercayai skor, waktu, koin, atau hasil validasi dari client.**
6. Tidak ada `RemoteFunction` yang dipanggil server ke client (risiko menggantung).
7. Model meja dan aset visual dibuat di Studio dan disinkronkan sebagai `.rbxm`. Jangan menyunting `.rbxl`/`.rbxm` secara manual.

## 7. Konten dan lisensi

- Daftar kata: hanya dari sumber berlisensi jelas. Catat sumber dan lisensinya di `docs/`.
- **Jangan menyalin** definisi kamus (mis. KBBI), clue TTS terbitan lain, atau daftar kata tanpa lisensi jelas.
- Semua clue ditulis orisinal. Saring kata yang tidak pantas atau terlalu langka.
- Data fixture di `puzzles/fixtures/` hanya untuk uji, bukan konten final.

## 8. Testing

- Logika murni: unit test di `tests/*.spec.luau`. Tulis test **bersama atau sebelum** implementasi.
- Bug fix dimulai dengan test yang gagal (mereproduksi bug), lalu perbaikan.
- Test harus deterministik (jam disuntikkan, tidak bergantung waktu nyata atau urutan acak tanpa seed).
- **Agent tidak dapat menjalankan Roblox Studio.** Untuk hal yang butuh Studio (UI, input sentuh, multi-client, emulator), agent **tidak boleh mengklaim sudah diverifikasi**. Tulis di laporan: "belum diverifikasi di Studio" dan daftar langkah uji manual untuk pengembang.

## 9. Alur kerja

1. Baca dokumen rujukan dan kode terkait. Bila permintaan ambigu atau butuh keputusan desain, **tanya dulu**.
2. Kerjakan **satu irisan vertikal kecil**: implementasi, test, verifikasi, commit. Hindari mengubah banyak modul sekaligus.
3. Jalankan `./scripts/check.sh`. Perbaiki sampai hijau.
4. Perbarui dokumen yang terdampak (SPEC, GDD, ADR).
5. Laporkan hasil dengan format di bagian 12.

### Skill yang digunakan (Codex: panggil dengan `$nama-skill`)

Skill dari paket `addyosmani/agent-skills`, terpasang di `.agents/skills/` (repo) atau `~/.agents/skills/` (pengguna). Bila skill tidak muncul, restart Codex/muat ulang jendela VS Code. Isinya cenderung berorientasi web, jadi terapkan **prinsip prosesnya** dan abaikan hal spesifik web (WCAG, React, Core Web Vitals) yang tidak berlaku di Roblox.

| Situasi | Skill |
|---|---|
| Kebutuhan belum jelas | `$interview-me`, `$idea-refine` |
| Menulis atau memperbarui spec | `$spec-driven-development` |
| Memecah pekerjaan | `$planning-and-task-breakdown` |
| Implementasi apa pun | `$incremental-implementation`, `$test-driven-development` |
| Memakai API Roblox/Luau/Rojo | `$source-driven-development` (rujuk dokumentasi resmi, jangan mengarang API) |
| Mendesain kontrak remote/antarmuka modul | `$api-and-interface-design` |
| Keputusan berisiko (keamanan, tidak dapat dibatalkan) | `$doubt-driven-development` |
| Input dari client, validasi, anti-exploit | `$security-and-hardening` |
| Test gagal atau perilaku aneh | `$debugging-and-error-recovery` |
| Sebelum merge | `$code-review-and-quality`, `$code-simplification` |
| Keputusan arsitektur | `$documentation-and-adrs` |
| Commit dan cabang | `$git-workflow-and-versioning` |
| Menjelang rilis | `$shipping-and-launch` |

Tidak relevan untuk proyek ini: `browser-testing-with-devtools`, `performance-optimization` (berorientasi web), dan persona `web-performance-auditor`.

Persona review (bila tersedia di lingkungan): `code-reviewer` di tiap milestone, `security-auditor` sebelum milestone Duel dan sebelum rilis, `test-engineer` untuk strategi test state machine dan validasi. Bila persona tidak tersedia, minta review dengan sudut pandang tersebut.

## 10. Git

- Cabang: `mN/deskripsi-singkat` (mis. `m1/wheel-input`).
- Commit kecil dan atomik (kira-kira di bawah 100 baris bila memungkinkan). Satu commit satu maksud.
- Pesan commit gaya Conventional Commits: `feat(wheel): tambah backtrack pada DragSession`, `fix(validation): tolak kata di bawah panjang minimum`, `test:`, `docs:`, `chore:`, `refactor:`.
- Jangan commit `build/`, `sourcemap.json`, file `.rbxl`, kredensial, atau token.
- Jangan menulis ulang riwayat cabang bersama.

## 11. Batasan

**Selalu**

- Jalankan `./scripts/check.sh` sebelum commit.
- Verifikasi API Roblox ke dokumentasi resmi (`create.roblox.com/docs`). Bila tidak yakin, katakan tidak yakin.
- Tulis test untuk logika murni.
- Simpan keputusan arsitektur sebagai ADR di `docs/adr/`.

**Tanya dulu**

- Menambah dependensi/paket pihak ketiga.
- Mengubah kontrak remote, skema puzzle, `default.project.json`, atau struktur folder.
- Mengganti pendekatan UI (mis. memakai framework UI).
- Perubahan yang menyentuh lebih dari beberapa modul sekaligus.
- Mengubah aturan gameplay yang sudah ada di GDD.

**Jangan**

- Mengirim jawaban puzzle ke client sebelum ditemukan.
- Memercayai data client.
- Memakai API Roblox di modul murni.
- Menyunting `.rbxl`/`.rbxm` manual atau menyimpan rahasia di repositori.
- Menyalin data atau clue dari sumber tanpa lisensi jelas.
- Menonaktifkan test, lint, atau `--!strict` agar "lolos".
- Mengklaim sudah menguji di Studio padahal belum.

## 12. Laporan setelah tugas

Akhiri setiap tugas dengan ringkasan singkat:

1. **Yang diubah:** file dan alasannya.
2. **Verifikasi:** perintah yang dijalankan dan hasilnya (mis. `check.sh` hijau, jumlah test).
3. **Belum diverifikasi:** hal yang butuh Studio, plus langkah uji manual.
4. **Asumsi dan pertanyaan:** keputusan yang diambil sendiri dan yang butuh konfirmasi.
5. **Langkah berikutnya** yang disarankan.

## 13. Alasan yang tidak diterima

| Alasan | Tanggapan |
|---|---|
| "Test-nya nanti saja" | Logika murni wajib punya test bersama implementasinya |
| "Cuma prototipe, jawaban di client saja" | Hanya diizinkan di M1 sebagai stub dan harus dihapus di M2 (SPEC 6 dan 7.6) |
| "Client kan sudah memvalidasi" | Validasi client hanya kenyamanan UI. Server tetap memutuskan |
| "API ini pasti ada" | Verifikasi ke dokumentasi. Jangan mengarang |
| "Lint/tipe mengganggu" | Perbaiki penyebabnya, jangan mematikan aturan |
| "Sekalian ubah modul lain" | Irisan kecil. Ajukan sebagai tugas terpisah |
| "Sudah jalan di Studio" (tanpa Studio) | Agent tidak menjalankan Studio. Laporkan sebagai belum diverifikasi |

## 14. Glosarium

| Istilah | Arti |
|---|---|
| TTS | Teka-teki silang |
| Word connect | Menyeret huruf pada lingkaran untuk membentuk kata |
| Wheel / lingkaran huruf | Huruf-huruf sumber pembentuk kata |
| Slot | Satu kata pada grid (posisi, arah, panjang, clue) |
| Snapshot | Keadaan match yang dikirim ke client, **tanpa jawaban** |
| Kata bonus | Kata valid yang tidak ada di grid (memberi koin) |
| Meja (Table) | Model dengan 1, 2, atau 4 kursi tempat match dimulai |
| Host | Pemain yang pertama duduk di meja |
| FFA | Duel semua lawan semua. 2v2 = dua tim berpasangan |
