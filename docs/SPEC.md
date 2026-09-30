# SPEC: TTS Party, Milestone M0 sampai M2

| Item | Isi |
|---|---|
| Versi | 0.1 (draft) |
| Rujukan | `docs/GDD.md` v0.2 |
| Cakupan | M0 (setup proyek), M1 (prototipe solo lokal), M2 (validasi server) |
| Status | Draft v0.1; sudah dirinci di `docs/PLAN.md` dan diperbarui bersama implementasi |

Dokumen ini adalah kontrak kerja untuk agent dan pengembang. Bila ada konflik, GDD menentukan *apa*, SPEC ini menentukan *bagaimana dan kapan dianggap selesai*.

---

## 1. Tujuan

Membangun fondasi teknis dan loop gameplay inti word connect yang **aman di server**, sebelum sistem meja dan multiplayer (M3 dan seterusnya).

| M | Hasil akhir yang dapat didemokan |
|---|---|
| M0 | Proyek Rojo tersinkron ke Studio, lint/format/test berjalan dengan satu perintah |
| M1 | Di Studio (PC dan emulator mobile), pemain melihat UI 70:30, menyeret huruf, dan melihat pratinjau kata serta garis penghubung. Puzzle masih stub lokal |
| M2 | Kata yang diseret divalidasi server. Jawaban tidak pernah ada di client sebelum ditemukan. Ada rate limit dan unit test |

### Di luar cakupan (M0 sampai M2)

Meja/kursi, state machine meja, mode Team/Duel, DataStore, koin, hint, generator puzzle, animasi/suara final, monetisasi.

---

## 2. Perintah (Commands)

Versi alat yang dipakai dipin di `rokit.toml`. Sintaks perintah di bagian ini diverifikasi terhadap dokumentasi resmi alat tersebut.

| Tujuan | Perintah |
|---|---|
| Pasang alat | `rokit install`; paket dan versi dipin di `rokit.toml`, keputusan di `docs/adr/0002-toolchain-manager.md` |
| Sinkron ke Studio | `rojo serve` lalu sambungkan lewat plugin Rojo |
| Build place | `rojo build -o build/TTSParty.rbxl` |
| Format | `stylua src tests` |
| Cek format | `stylua --check src tests` |
| Lint | `selene src tests` |
| Analisis tipe | Bila `rojo` dan `luau-lsp` tersedia: `rojo sourcemap default.project.json -o sourcemap.json`, lalu `luau-lsp analyze --sourcemap sourcemap.json src` (saat ini LSP memperingatkan definisi Roblox belum dikonfigurasi) |
| Unit test | `lune run tests/run` (runner Lune dipilih; alasan di `docs/adr/0001-test-runner.md`) |
| Validasi puzzle (rencana M6; skrip belum tersedia) | `python tools/puzzle_gen/validate.py` |
| Semua pemeriksaan | Bash: `./scripts/check.sh`; Windows PowerShell: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/check.ps1` (format-check + lint + analisis tipe bila tersedia + test) |

`scripts/check.sh` wajib hijau sebelum commit; di Windows gunakan `scripts/check.ps1` melalui perintah PowerShell di atas.

---

## 3. Struktur Proyek target (subset M0 sampai M2)

Pohon berikut menggambarkan struktur yang dituju; modul fitur pada tugas mendatang belum tentu ada di checkout M0.

```
proyek/
├─ default.project.json
├─ rokit.toml
├─ stylua.toml
├─ selene.toml
├─ roblox.yml                 # definisi std Roblox untuk Selene
├─ AGENTS.md
├─ scripts/check.sh
├─ scripts/check.ps1          # pemeriksaan native Windows
├─ docs/
│  ├─ GDD.md
│  ├─ SPEC.md
│  └─ adr/
│     ├─ 0001-test-runner.md
│     └─ 0002-toolchain-manager.md
├─ puzzles/
│  └─ fixtures/test_puzzle_01.luau   # fixture uji, bukan konten final
├─ src/
│  ├─ shared/
│  │  ├─ Types.luau
│  │  ├─ Constants.luau
│  │  ├─ Remotes.luau
│  │  ├─ WordUtils.luau              # murni
│  │  ├─ WheelLayout.luau            # murni
│  │  ├─ GridLayout.luau             # murni
│  │  └─ DragSession.luau            # murni
│  ├─ server/
│  │  ├─ init.server.luau            # bootstrap
│  │  ├─ PuzzleService.luau
│  │  ├─ ValidationService.luau
│  │  ├─ RateLimiter.luau            # murni (jam dapat disuntik)
│  │  └─ MatchService.luau           # sesi solo debug (M2)
│  └─ client/
│     ├─ init.client.luau            # bootstrap
│     ├─ MatchController.luau
│     ├─ Input/WheelInput.luau
│     └─ UI/
│        ├─ MatchGui.luau
│        ├─ GridView.luau
│        └─ LetterWheel.luau
└─ tests/
   ├─ run.luau
   └─ *.spec.luau
```

### 3.1 `default.project.json` (rencana)

```json
{
  "name": "TTSParty",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",
      "Shared": { "$path": "src/shared" }
    },
    "ServerScriptService": {
      "$className": "ServerScriptService",
      "Server": { "$path": "src/server" }
    },
    "ServerStorage": {
      "$className": "ServerStorage",
      "Puzzles": { "$path": "puzzles" }
    },
    "StarterPlayer": {
      "$className": "StarterPlayer",
      "StarterPlayerScripts": {
        "$className": "StarterPlayerScripts",
        "Client": { "$path": "src/client" }
      }
    }
  }
}
```

Penamaan file untuk Rojo: `init.server.luau` / `init.client.luau` untuk skrip bootstrap, `*.luau` biasa untuk ModuleScript.

---

## 4. Aturan Kode (Code Style)

- `--!strict` di setiap file Luau. Semua tipe publik di `Types.luau`.
- Identifier dalam bahasa Inggris. Komentar dan dokumen boleh bahasa Indonesia.
- Modul: `PascalCase.luau`. Fungsi/variabel: `camelCase`. Konstanta: `UPPER_SNAKE_CASE`.
- Pakai `task.wait`/`task.spawn`/`task.delay`, bukan `wait`/`spawn`/`delay`.
- Tanpa variabel global dan tanpa `_G`.
- **Modul murni** (`WordUtils`, `WheelLayout`, `GridLayout`, `DragSession`, `RateLimiter`, logika di `ValidationService`) **tidak boleh memakai Roblox API atau datatype** (`game`, `Instance`, `Vector2`, `tick`, dst.). Gunakan tabel biasa (`{ x: number, y: number }`) dan suntikkan ketergantungan (mis. fungsi jam) agar dapat diuji di luar Studio.
- Satu modul, satu tanggung jawab. Fungsi di bawah kira-kira 50 baris.
- Setiap `RemoteEvent` didefinisikan hanya di `shared/Remotes.luau`.
- Setiap perubahan tidak lebih dari kira-kira 100 baris per commit bila memungkinkan.

---

## 5. M0: Setup Proyek

### 5.1 Kebutuhan

1. Repositori git dengan struktur pada Bagian 3 dan `default.project.json` yang valid.
2. Toolchain terpasang lewat Rokit sesuai `rokit.toml`: Rojo, StyLua, Selene, Lune, dan luau-lsp. Keputusan dicatat di `docs/adr/0002-toolchain-manager.md`.
3. `stylua.toml`, `selene.toml`, definisi std Roblox `roblox.yml`, dan `.gitignore` (mengabaikan `build/`, `sourcemap.json`, `*.rbxl.lock`).
4. Runner test berjalan di luar Studio dengan smoke test saat ini (`tests/smoke.spec.luau`); test WordUtils dibuat di T1.1. Pilihan runner dicatat di `docs/adr/0001-test-runner.md`.
5. `scripts/check.sh` (Windows: `scripts/check.ps1`) menjalankan format-check, lint, analisis tipe bila tersedia, dan test, lalu gagal (exit non-zero) bila salah satunya gagal.
6. `AGENTS.md` (draf dari GDD Lampiran A) di root repositori.
7. (Opsional; belum dibuat) GitHub Actions yang menjalankan `scripts/check.sh` pada tiap push/PR. Penambahan CI memerlukan persetujuan pengembang.

### 5.2 Kriteria selesai

- [ ] `rojo serve` + plugin Rojo: skrip dari `src/` muncul di Studio (ReplicatedStorage/Shared, ServerScriptService/Server, StarterPlayerScripts/Client, ServerStorage/Puzzles).
- [ ] `rojo build` menghasilkan file `.rbxl` yang dapat dibuka di Studio tanpa error.
- [ ] `./scripts/check.sh` hijau di mesin bersih setelah `rokit install` (Windows: gunakan PowerShell untuk `scripts/check.ps1`).
- [ ] Skrip bootstrap server dan client mencetak satu baris log saat start dan tidak ada error di Output.
- [ ] ADR-0001 dan ADR-0002 ada dan menjelaskan alasan pilihan.

---

## 6. M1: Prototipe Solo Lokal

Semua puzzle dan logika di M1 berjalan **lokal di client sebagai stub**. Ini satu-satunya tahap di mana jawaban boleh berada di client. Stub dan kodenya harus dihapus di M2 (lihat 7.6).

### 6.1 Tipe data (puzzle)

```lua
--!strict
export type Direction = "across" | "down"

export type PuzzleWord = {
    word: string,        -- huruf besar A-Z
    row: number,         -- mulai dari 1
    col: number,         -- mulai dari 1
    dir: Direction,
    clue: string,
}

export type Puzzle = {
    id: string,
    difficulty: "easy" | "medium" | "hard",
    letters: { string },        -- huruf lingkaran, huruf besar
    minWordLength: number,
    grid: { rows: number, cols: number },
    words: { PuzzleWord },
    bonusWords: { string },
}
```

### 6.2 Fixture uji (`puzzles/fixtures/test_puzzle_01.luau`)

Data contoh untuk pengembangan dan test. Bukan konten final.

```lua
return {
    id = "test-0001",
    difficulty = "easy",
    letters = { "S", "A", "P", "I" },
    minWordLength = 3,
    grid = { rows = 3, cols = 4 },
    words = {
        { word = "SAPI", row = 1, col = 1, dir = "across", clue = "Hewan ternak penghasil susu dan daging" },
        { word = "PIA",  row = 1, col = 3, dir = "down",   clue = "Kue kecil bulat dengan isi manis" },
        { word = "PAS",  row = 3, col = 2, dir = "across", clue = "Ukuran yang tepat, tidak sempit dan tidak longgar" },
    },
    bonusWords = { "API", "ASI", "SAP" },
}
```

Tata letak fixture (`.` = kotak kosong):

```
   c1 c2 c3 c4
r1  S  A  P  I
r2  .  .  I  .
r3  .  P  A  S
```

### 6.3 Modul murni

**`WordUtils`**

| Fungsi | Perilaku |
|---|---|
| `normalize(s: string): string` | Trim, huruf besar. Kembalikan string kosong bila mengandung karakter selain A-Z setelah normalisasi |
| `canForm(word: string, letters: {string}): boolean` | `true` bila multiset huruf `word` merupakan subset dari `letters` (tiap huruf lingkaran dipakai paling banyak sekali per kemunculannya) |
| `isValidLength(word, min, max): boolean` | Panjang dalam rentang |

**`WheelLayout`**

- `positions(count: number, radius: number): { {x: number, y: number} }` menghitung posisi pusat huruf pada lingkaran, dimulai dari atas dan searah jarum jam: `angle = 2π * i / count - π/2`.
- `nearestLetter(points, pointer, hitRadius): number?` mengembalikan indeks huruf dalam `hitRadius`, atau `nil`. Bila lebih dari satu, ambil yang terdekat.

**`GridLayout`**

- `computeCellSize(panelW, panelH, rows, cols, gap): number` mengembalikan ukuran sel persegi terbesar agar seluruh grid muat dalam panel.
- Grid harus tetap terpusat dan tidak melebihi panel untuk grid dari 3x3 sampai 15x15.

**`DragSession`** (logika seretan, tanpa UI)

State: urutan indeks huruf terpilih.

| Aksi | Perilaku |
|---|---|
| `begin(pointer)` | Bila ada huruf dalam radius hit: mulai sesi dan pilih huruf itu. Selain itu abaikan |
| `move(pointer)` | Bila pointer dalam radius hit huruf yang belum dipilih: tambahkan. Bila pointer masuk ke huruf kedua terakhir: hapus huruf terakhir (backtrack). Selain itu tidak ada perubahan |
| `finish(): string?` | Kembalikan kata (dari huruf terpilih) bila panjang di atas atau sama dengan `minWordLength`, selain itu `nil`. Reset sesi |
| `cancel()` | Reset sesi tanpa hasil |

Aturan: satu huruf hanya sekali per sesi. Tidak ada huruf yang dipilih dua kali walau ada huruf kembar di lingkaran (huruf kembar dianggap dua node berbeda).

### 6.4 UI

**Root:** `ScreenGui` bernama `MatchGui`, `ResetOnSpawn = false`, `ScreenInsets = DeviceSafeInsets`, orientasi game `LandscapeSensor`.

**Layout (Scale, bukan Offset):**

| Elemen | Ukuran |
|---|---|
| `TopBar` | Tinggi sekitar 0.1 dari layar, lebar penuh. Isi placeholder: timer dan clue aktif |
| `GridPanel` | `{0.7, 0, 0.9, 0}`, di kiri bawah `TopBar` |
| `WheelPanel` | `{0.3, 0, 0.9, 0}`, di kanan bawah `TopBar` |

- Di dalam `GridPanel`: kontainer grid dengan `UIAspectRatioConstraint` sesuai `cols/rows`. Ukuran sel dari `GridLayout.computeCellSize`. Kotak kosong (`.`) tidak digambar. Kotak kata digambar kosong (tanpa huruf) di M1 kecuali huruf yang sudah ditemukan.
- Di dalam `WheelPanel`: lingkaran huruf 1:1 di tengah, label pratinjau kata di atasnya, tombol **Acak** dan **Hint** (Hint hanya placeholder tanpa fungsi di M1).
- Tap kotak di grid menyorot kata yang memuatnya dan menampilkan clue-nya di `TopBar` (clue hybrid).

**Input (`WheelInput`):**

- Tangani `InputBegan/Changed/Ended` untuk `MouseButton1` dan `Touch`. Abaikan touch tambahan selama sesi seretan aktif.
- Radius hit = 1.2 x radius visual huruf. Hit-test memakai jarak ke pusat huruf, **bukan** hover/`MouseEnter`.
- Garis penghubung: `Frame` yang diposisikan dan diputar dari huruf ke huruf, ditambah satu segmen dari huruf terakhir ke pointer. Segmen dipakai ulang (pooling), bukan dibuat ulang tiap frame.
- `WheelPanel.Active = true` dan input diserap agar seretan tidak menggerakkan avatar atau kamera.
- **Acak** hanya mengubah urutan tampilan huruf secara lokal dan tidak memengaruhi puzzle.

### 6.5 Kriteria selesai M1

- [ ] Semua modul murni di 6.3 punya unit test yang lulus (lihat 9).
- [ ] UI tampil benar dengan rasio 70:30 di emulator: ponsel kecil, ponsel besar, tablet, dan PC.
- [ ] Tidak ada elemen penting tertutup notch/safe area.
- [ ] Seret huruf berfungsi dengan mouse (PC) dan touch (emulator dan minimal satu perangkat asli), termasuk backtrack.
- [ ] Seretan tidak menggerakkan avatar atau kamera.
- [ ] Pratinjau kata dan garis penghubung mengikuti seretan tanpa patah-patah di ponsel kelas menengah.
- [ ] Kata yang cocok dengan fixture (dicek lokal, stub) mengisi kotak grid. Kata yang salah memicu efek getar.
- [ ] `./scripts/check.sh` hijau.

---

## 7. M2: Validasi Server

Sasaran: memindahkan seluruh keputusan benar/salah ke server, dan memastikan client tidak pernah memegang jawaban yang belum ditemukan.

### 7.1 Sesi solo debug

Karena sistem meja baru dibuat di M3, M2 memakai **sesi solo debug** per pemain:

- Di `PlayerAdded`, `MatchService` membuat sesi dengan `tableId = "debug-<UserId>"` memakai fixture puzzle.
- Diaktifkan lewat `Constants.DEBUG_SOLO_SESSION = true`. Dihapus/diganti oleh `TableService` di M3.

### 7.2 Kontrak remote

Semua didefinisikan di `shared/Remotes.luau` dan dibuat oleh server saat start.

**Client ke server**

| Remote | Payload |
|---|---|
| `Match_SubmitWord` | `tableId: string, word: string` |

**Server ke client**

| Remote | Payload |
|---|---|
| `Match_Snapshot` | `Snapshot` (7.3), dikirim saat pemain bergabung |
| `Match_WordAccepted` | `{ playerId: number, slotIndex: number, letters: string, score: number }` |
| `Match_BonusFound` | `{ playerId: number, coins: number }` |
| `Match_WordRejected` | `{ reason: RejectReason }` |

```lua
export type RejectReason =
    "NotSeated" | "WrongState" | "RateLimited" | "TooShort"
    | "InvalidLetters" | "AlreadySolved" | "NotAWord"
```

Catatan: di M2, `NotSeated` berarti pemain bukan pemilik sesi `tableId` tersebut.

### 7.3 Snapshot (tidak boleh membocorkan jawaban)

```lua
export type SlotView = {
    index: number,
    row: number,
    col: number,
    dir: Direction,
    length: number,
    clue: string,
    solved: boolean,
    solvedBy: number?,     -- UserId
    letters: string?,      -- hanya ada bila solved = true
}

export type Snapshot = {
    tableId: string,
    state: "Playing",
    grid: { rows: number, cols: number },
    letters: { string },
    minWordLength: number,
    slots: { SlotView },
    scores: { [number]: number },
}
```

Aturan keras: **field `word` dari data puzzle tidak pernah dimasukkan ke snapshot**. `letters` pada slot hanya diisi setelah slot terpecahkan.

### 7.4 Urutan validasi (`ValidationService`)

Fungsi murni `evaluate(puzzle, sessionState, playerId, rawWord) -> Result`. Urutan:

1. Sesi ada dan `playerId` adalah anggotanya, selain itu `NotSeated`.
2. State `Playing`, selain itu `WrongState`.
3. Rate limit (di luar fungsi murni, oleh `RateLimiter`), gagal berarti `RateLimited`.
4. `WordUtils.normalize`. Bila kosong (karakter tidak valid) berarti `InvalidLetters`.
5. Panjang di bawah `minWordLength` berarti `TooShort`. Panjang berlebihan (lebih dari jumlah huruf lingkaran) berarti `InvalidLetters`.
6. `WordUtils.canForm(word, puzzle.letters)`, bila gagal `InvalidLetters`.
7. Cocok dengan slot yang belum terisi berarti **accepted** (kembalikan indeks slot). Bila cocok dengan slot yang sudah terisi berarti `AlreadySolved`.
8. Ada di `bonusWords` dan belum pernah ditemukan pemain ini berarti **bonus**. Bila sudah pernah, `AlreadySolved`.
9. Selain itu `NotAWord`.

Bila satu kata cocok dengan lebih dari satu slot (kata sama di dua slot), semua slot yang belum terisi dengan kata itu terisi sekaligus.

### 7.5 Rate limiter

- Token bucket per pemain: kapasitas awal 5, isi ulang 3 token per detik (nilai awal, konstanta di `Constants`).
- Jam disuntikkan (`RateLimiter.new(clockFn)`) agar deterministik saat diuji.
- Pemain yang keluar dibersihkan dari tabel (tidak ada kebocoran memori).

### 7.6 Migrasi client dari stub ke server

- Hapus puzzle stub dan pengecekan lokal dari `MatchController`.
- Client hanya: (a) merender `Snapshot`, (b) mengirim `Match_SubmitWord`, (c) merender hasil dari `WordAccepted`, `BonusFound`, `WordRejected`.
- Sisipkan cek murah di client (panjang minimal) hanya sebagai kenyamanan UI. Keputusan tetap di server.
- Tidak ada modul di `shared/` atau `ReplicatedStorage` yang berisi data jawaban puzzle.

### 7.6.1 Puzzle di server

`PuzzleService` memuat puzzle dari `ServerStorage/Puzzles` dan memvalidasi skemanya saat start (kolom valid, semua kata dapat dibentuk dari `letters`, persilangan konsisten, tidak ada dua kata menimpa huruf berbeda). Puzzle tidak valid menghasilkan error jelas di log dan tidak dimuat.

### 7.7 Keamanan

- Payload `Match_SubmitWord`: cek `typeof(tableId) == "string"`, `typeof(word) == "string"`, panjang `word` tidak lebih dari batas wajar (mis. 16), tolak yang lain tanpa memproses.
- Server tidak memercayai skor atau apa pun dari client. Skor dihitung server.
- Tidak ada `RemoteFunction` yang dapat dibuat menggantung oleh client.
- Log peringatan (dengan `UserId`) untuk payload tipe salah atau `RateLimited` berulang.

### 7.8 Kriteria selesai M2

- [ ] Semua jalur di 7.4 punya test (accepted, bonus, dan tiap `RejectReason`).
- [ ] Test khusus: **snapshot tidak mengandung `word`** untuk slot yang belum terpecahkan, dan `letters` hanya ada pada slot yang solved.
- [ ] Test rate limiter: burst lalu tolak, isi ulang seiring waktu (jam palsu), pemain keluar dibersihkan.
- [ ] Uji manual di Studio: dari client, periksa `ReplicatedStorage` dan tidak ditemukan data jawaban. Memanggil `Match_SubmitWord` dengan kata salah/tipe salah/berulang cepat tidak merusak server dan mengembalikan alasan yang benar.
- [ ] Alur akhir-ke-akhir: seret `SAPI` mengisi baris pertama, seret `PIA` dan `PAS` mengisi sisanya, `API` menghasilkan bonus, `KUDA` ditolak (`InvalidLetters`).
- [ ] Stub lokal M1 sudah dihapus dari client.
- [ ] `./scripts/check.sh` hijau.

---

## 8. Batasan (Boundaries)

**Selalu**

- Jalankan `./scripts/check.sh` sebelum commit.
- Tulis test dulu (atau bersama) untuk logika murni.
- Rujuk dokumentasi resmi Roblox untuk API. Catat sumbernya di komentar bila penting.
- Perbarui `SPEC.md`/`GDD.md`/ADR bila keputusan berubah.

**Tanya dulu**

- Menambah dependensi/paket pihak ketiga (mis. Wally package).
- Mengubah kontrak remote atau skema puzzle.
- Mengubah struktur folder atau `default.project.json`.
- Memilih framework UI selain Luau polos.

**Jangan**

- Mengirim jawaban puzzle (atau field `word`) ke client sebelum ditemukan.
- Memercayai data dari client (skor, waktu, koin, hasil validasi).
- Memakai API Roblox di modul murni.
- Mengedit `.rbxl`/`.rbxm` secara manual atau menyimpan rahasia di repositori.
- Menyalin daftar kata atau clue dari sumber tanpa lisensi jelas.

---

## 9. Rencana Test

Runner: Lune dengan runner ringan sesuai `docs/adr/0001-test-runner.md`. Test ada di `tests/*.spec.luau` dan setiap spec mengikuti kontrak di ADR.

| Modul | Kasus minimum |
|---|---|
| `WordUtils.normalize` | huruf kecil, spasi tepi, angka/simbol, string kosong |
| `WordUtils.canForm` | pas, huruf kurang, huruf berlebih, huruf kembar (`SAPI` bukan `SAPII`), huruf tidak ada |
| `WheelLayout.positions` | jumlah 4, 5, 6, 7. Huruf pertama di atas, jarak ke pusat sama dengan radius, sudut merata |
| `WheelLayout.nearestLetter` | di dalam/luar radius, dua kandidat (ambil terdekat) |
| `GridLayout.computeCellSize` | grid 3x4, 5x5, 15x15, panel lebar dan panel tinggi, gap 0 dan gap positif |
| `DragSession` | pilih satu, tambah, backtrack, tidak memilih dua kali, `finish` di bawah minimum menghasilkan `nil`, `cancel` |
| `ValidationService.evaluate` | semua `RejectReason`, accepted, bonus, kata sama di dua slot |
| `RateLimiter` | burst, isi ulang, batas kapasitas, pembersihan |
| `Snapshot builder` | tidak ada `word`, `letters` hanya pada slot solved |
| `PuzzleService` (skema) | puzzle valid lolos, kata tidak dapat dibentuk gagal, persilangan konflik gagal |

### Checklist manual Studio (dilakukan pengembang, bukan agent)

- [ ] Emulator: ponsel kecil, ponsel besar, tablet, PC 16:9 dan 21:9
- [ ] Seret dengan mouse dan touch, termasuk backtrack dan lepas di luar lingkaran
- [ ] Seretan tidak menggeser kamera/avatar
- [ ] Test server/client lokal: `Match_SubmitWord` dari klien memberi respons benar
- [ ] Tidak ada warning/error di Output selama satu sesi 5 menit

---

## 10. Risiko dan Asumsi Khusus M0 sampai M2

| Risiko/Asumsi | Penanganan |
|---|---|
| Agent tidak dapat menjalankan Studio | Logika penting dibuat murni dan diuji di luar Studio. Verifikasi Studio lewat checklist manual |
| Sintaks/flag alat berubah | Verifikasi ke dokumentasi resmi, perbarui Bagian 2 |
| `ScreenInsets` dan perilaku emulator berbeda antar perangkat | Uji di perangkat asli sedini mungkin (M1) |
| Puzzle fixture terlalu kecil untuk menguji layout | Tambah fixture medium (grid 8x8) untuk uji `GridLayout` dan UI |
| Sesi solo debug tertinggal setelah M3 | Ditandai `DEBUG_SOLO_SESSION`, dihapus pada M3 |

---

## 11. Urutan Kerja yang Disarankan

1. M0, satu commit per butir kebutuhan 5.1.
2. M1: `WordUtils`, `WheelLayout`, `GridLayout`, `DragSession` (murni, dengan test) lalu `MatchGui` (layout) lalu `LetterWheel` + `WheelInput` lalu `GridView` lalu integrasi stub.
3. M2: `Remotes` + tipe lalu `RateLimiter` lalu `ValidationService` lalu `PuzzleService` lalu `MatchService` (sesi debug + snapshot) lalu migrasi client lalu uji keamanan manual.

Setiap butir dikerjakan sebagai irisan vertikal kecil: implementasi, test, verifikasi, commit.
