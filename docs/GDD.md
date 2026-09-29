# Game Design Document: TTS Party (judul sementara)

| Item | Isi |
|---|---|
| Versi | 0.2 (keputusan Bagian 15 sudah dimasukkan) |
| Platform | Roblox (PC + Mobile), landscape |
| Engine / Toolchain | Roblox Studio, Luau, Rojo, VS Code, Codex |
| Genre | Word connect + teka-teki silang (TTS), multiplayer party |
| Bahasa konten | Indonesia (utama) |
| Status | Konsep. Perlu diturunkan ke `SPEC.md` dan `PLAN.md` sebelum implementasi |

---

## 1. Visi dan Pilar

**Visi satu kalimat:** Game TTS sosial di Roblox. Pemain duduk di meja, lalu bermain bersama (kerja sama) atau saling berebut (duel) menyelesaikan TTS dengan cara menyeret huruf ala word connect.

**Pilar desain**

1. **Cepat dimengerti.** Pemain baru paham cara main dalam kurang dari 30 detik tanpa tutorial panjang.
2. **Sosial.** Duduk semeja, melihat siapa yang menemukan kata, reaksi avatar, dan obrolan adalah bagian dari hiburan.
3. **Adil dan aman.** Server yang memegang semua jawaban dan penilaian. Client tidak pernah tahu jawaban sebelum ditemukan.
4. **Nyaman di mobile.** Semua interaksi utama harus enak dengan satu jari di layar landscape.
5. **Konten berkualitas.** Puzzle dibuat dan diuji secara offline, bukan digenerate sembarangan saat runtime.

**Bukan tujuan (v1):** single-player campaign panjang, chat suara, editor puzzle buatan pemain, bahasa selain Indonesia.

---

## 2. Target Pemain

- Pemain Roblox usia santai/remaja/dewasa muda yang suka game kata dan game meja (tebak kata, dsb).
- Sesi bermain singkat: 3 sampai 10 menit per ronde.
- Dominan mobile, sehingga UI dan performa dirancang mobile-first, lalu diskalakan ke PC.

---

## 3. Core Loop

```
Jalan ke meja -> Duduk -> (Host pilih mode + kesulitan) -> Countdown
   -> Ronde: seret huruf -> kata terisi di TTS -> ...
   -> Hasil (skor, koin, bintang) -> kembali ke meja / ganti puzzle / berdiri
```

**Loop mikro (per kata):** lihat kotak TTS/petunjuk -> seret huruf di lingkaran -> lepas -> kata benar terisi (animasi + suara) atau salah (getar).

---

## 4. Gameplay Inti: Word Connect + TTS

### 4.1 Aturan dasar

- Setiap puzzle punya **lingkaran huruf** (4 sampai 7 huruf) dan **grid TTS** yang berisi kata-kata yang seluruhnya dapat dibentuk dari huruf lingkaran tersebut.
- Pemain menyeret dari huruf ke huruf. Tiap huruf hanya boleh dipilih sekali per satu seretan.
- Saat jari/mouse dilepas, kata dikirim ke server untuk divalidasi.
- Kata yang cocok dengan kata di grid mengisi kotaknya. Kata valid yang tidak ada di grid menjadi **kata bonus** (hadiah koin kecil).
- Panjang kata minimal 3 huruf (dapat dikonfigurasi per puzzle).
- Puzzle selesai bila semua kata di grid terisi.

### 4.2 Petunjuk (clue) TTS

TTS Indonesia biasanya punya pertanyaan mendatar/menurun. Karena word connect biasanya "temukan kata apa saja", ada dua opsi:

- **Opsi A (rekomendasi):** *Hybrid.* Pemain boleh menyeret kata apa saja. Tap sebuah kotak di grid akan menyorot kata tersebut dan menampilkan clue-nya di bar clue. Clue berfungsi sebagai bantuan, bukan syarat.
- **Opsi B:** Clue wajib. Pemain memilih clue dulu, lalu menyeret jawabannya.

> **Keputusan: Opsi A (hybrid).** Pemain bebas menyeret kata apa saja, clue hanya bantuan. Lihat Bagian 15.

### 4.3 Kontrol seret huruf

Algoritma input (client):

1. `InputBegan` (MouseButton1 atau Touch) di area lingkaran: cari huruf terdekat dalam radius hit. Jika ada, mulai seretan.
2. `InputChanged`: bila posisi input berada dalam radius hit huruf lain yang belum dipilih, tambahkan ke urutan. Bila masuk lagi ke huruf sebelumnya (kedua terakhir), hapus huruf terakhir (backtrack).
3. `InputEnded`: bila panjang di atas atau sama dengan minimum, kirim ke server. Reset seretan.
4. Garis penghubung digambar dari huruf ke huruf, dan dari huruf terakhir ke posisi pointer.
5. Pratinjau kata yang sedang dibentuk ditampilkan di atas lingkaran.

Ketentuan:

- Hit detection berbasis **jarak posisi input ke pusat tiap huruf**, bukan hover/`MouseEnter`, karena tidak andal di layar sentuh.
- Radius hit sedikit lebih besar dari radius visual huruf (kira-kira 1.2x) supaya toleran.
- Hanya satu touch yang diproses untuk seretan (abaikan multi-touch tambahan).
- Selama match aktif, input di area game **tidak boleh** menggerakkan avatar atau kamera (sink lewat `ContextActionService`).
- Tombol pendukung: **Acak** (shuffle huruf, hanya visual lokal), **Hint**, **Keluar**.

### 4.4 Validasi kata (server)

Urutan pemeriksaan pada tiap `SubmitWord`:

1. Pemain benar-benar duduk di meja tersebut dan state = `Playing`.
2. Lolos rate limit.
3. Normalisasi: huruf besar, trim, hanya A-Z.
4. Panjang dalam rentang yang diizinkan.
5. Multiset huruf kata merupakan subset dari huruf lingkaran.
6. Cocok dengan kata grid yang belum terisi -> **diterima**.
7. Jika tidak: cek daftar kata bonus -> **bonus**.
8. Jika tidak: **ditolak** (`NotAWord`).

---

## 5. Sistem Meja (Lobby)

- Satu **Table** = satu Model dengan `Seat`, satu papan status, dan satu `ProximityPrompt`/panel pemilih mode.
- Ada **tiga jenis meja** di lobby:

| Jenis meja | Minimal mulai | Mode yang tersedia |
|---|---|---|
| 1 kursi | 1 | Team (solo/latihan). Tidak ada Duel |
| 2 kursi | 2 (asumsi) | Team (duo) atau Duel 1v1 |
| 4 kursi | 2 | Team, Duel FFA, atau Duel 2v2 (2v2 hanya jika 4 kursi terisi) |
- Beberapa meja tersebar di area lobby. Tiap meja punya state mesin sendiri (independen).
- **Host** = pemain yang pertama duduk. Jika host berdiri, host berpindah ke pemain yang duduk paling lama.
- Papan di meja menampilkan: mode, kesulitan, jumlah pemain, status (Menunggu/Bermain).
- Pemain yang sudah duduk tidak bisa dipindah paksa. **Kursi dikunci setelah match mulai** (tidak ada join in progress). Kursi yang kosong baru bisa diisi lagi saat state kembali ke Waiting.
- Di Duel 2v2, kursi diberi **warna tim** (dua warna). Pemain menentukan timnya dengan memilih kursi.

### 5.1 State machine meja

```
Waiting --(pemain >= min meja & host Start)--> Countdown (5 dtk)
Countdown --(pemain < min)--> Waiting
Countdown --(selesai)--> Playing
Playing --(puzzle selesai | waktu habis | Duel: lawan tersisa < 1 | Team: semua keluar)--> Result (10 dtk)
Result --> Waiting
```

### 5.2 Kasus khusus

| Kasus | Perilaku |
|---|---|
| Pemain berdiri/lompat saat Playing | Dianggap keluar dari match. UI ditutup, kontrol karakter dikembalikan |
| Pemain disconnect | Sama dengan keluar |
| Mode Team, anggota keluar | Progres tim tetap jalan |
| Duel FFA/1v1, tersisa 1 pemain | Match berakhir, pemain tersisa menang |
| Duel 2v2, satu anggota keluar | Timnya lanjut dengan sisa anggota, skor tetap |
| Duel 2v2, satu tim kehilangan semua anggota | Tim lawan menang |
| Host keluar | Host berpindah otomatis |
| Semua pemain keluar | Meja reset ke Waiting |

---

## 6. Mode Permainan

### 6.1 Team (kooperatif)

- Satu papan bersama. Kata yang ditemukan siapa pun langsung terisi untuk semua.
- Setiap kata yang terisi menampilkan siapa penemunya (warna/nama pemain di kotak).
- Tujuan: menyelesaikan puzzle secepat mungkin.
- Hasil: bintang (1 sampai 3) berdasarkan waktu dan jumlah hint. Tampilkan kontribusi tiap pemain.

### 6.2 Duel (kompetitif)

- **Papan bersama dengan klaim.** Kata yang pertama ditemukan memberi poin ke penemunya. Kata itu terisi untuk semua.
- Server memproses `SubmitWord` sesuai urutan kedatangan. Pemenang klaim adalah yang tiba lebih dulu di server.
- Skor kata = `panjang x 10` (nilai awal, perlu balancing). Bonus kecil untuk kata terpanjang.
- Pemenang = skor tertinggi saat puzzle selesai atau waktu habis (default 4 menit, dapat diatur per kesulitan).
- Kata bonus tidak memberi poin duel, hanya koin.
- **Tebakan salah tidak dikenai penalti.** Pencegahan spam cukup lewat rate limit di server.
- Hint dinonaktifkan atau dikenai penalti skor di Duel (ditentukan saat balancing).

**Format Duel (host memilih saat opsi meja diatur):**

| Format | Meja | Aturan |
|---|---|---|
| 1v1 | 2 kursi | Dua pemain berebut kata |
| FFA | 4 kursi (2 sampai 4 pemain) | Semua lawan semua, skor individu |
| 2v2 | 4 kursi (harus 4 pemain) | Tim ditentukan warna kursi. Skor tim = jumlah skor dua anggota. Kata milik penemunya, poin masuk ke tim |

### 6.3 Ide setelah MVP

- Mode "Marathon": beberapa puzzle berurutan, skor akumulatif.
- Mode event/harian dengan tema kata tertentu.

---

## 7. UI/UX

### 7.1 Layout (landscape, rasio 70:30)

```
+-----------------------------------------+----------------+
| [Bar atas: timer | skor/pemain | clue]                    |
+-----------------------------------------+----------------+
|                                         |                |
|            GRID TTS (70%)               |  LINGKARAN     |
|                                         |  HURUF (30%)   |
|                                         |  + pratinjau   |
|                                         |  + Acak/Hint   |
+-----------------------------------------+----------------+
```

- Panel kiri `Size = {0.7, 0, 1, 0}`, panel kanan `Size = {0.3, 0, 1, 0}`. Gunakan **Scale**, bukan Offset.
- Grid TTS memakai `UIAspectRatioConstraint`. Ukuran sel dihitung dari dimensi grid (kolom x baris) agar grid besar tetap muat.
- Lingkaran huruf dipusatkan di panel kanan dan dibatasi aspect ratio 1:1.
- Bar atas menampilkan avatar/nama/skor pemain di meja dan clue aktif.
- `ScreenInsets = DeviceSafeInsets` agar tidak tertutup notch. Orientasi `LandscapeSensor`.
- UI menutup layar penuh saat match. Ada **tombol perkecil UI** yang menyusutkan panel menjadi bar ringkas (skor + timer) sehingga avatar dan meja terlihat. Status ini hanya visual lokal, tidak memengaruhi match.

### 7.2 Ukuran sentuh dan keterbacaan

- Target huruf minimal setara 44 sampai 48 px pada layar kecil.
- Font huruf grid dan lingkaran tegas, kontras tinggi. Jangan mengandalkan warna saja untuk status (tambahkan ikon/pola).
- Uji di emulator perangkat Studio: ponsel kecil, ponsel besar, tablet, PC 16:9 dan 21:9.

### 7.3 Umpan balik

| Kejadian | Visual | Audio |
|---|---|---|
| Huruf terpilih | Highlight + garis | Nada naik per huruf |
| Kata benar | Huruf terbang ke grid, sel menyala | Chime |
| Kata bonus | Ikon koin | Chime lembut |
| Kata salah | Getar ringan | Buzz pendek |
| Puzzle selesai | Konfeti + layar hasil | Fanfare |

Avatar pemain di sekitar meja dapat memainkan emote singkat saat menang/salah (opsional, setelah MVP).

### 7.4 Implementasi UI

- UI dibangun **lewat kode Luau** (bukan hanya drag-drop di Studio) agar dapat dibuat, diubah, dan ditinjau agent lewat file. Buat helper komponen kecil (`Button`, `Panel`, `LetterNode`).
- Buat UI sekali lalu pakai ulang (object pooling untuk garis penghubung dan sel).

---

## 8. Puzzle dan Konten

### 8.1 Skema data puzzle

```lua
-- Contoh (Luau / diserialisasi dari JSON)
{
  id = "id-easy-0001",
  difficulty = "easy",           -- easy | medium | hard
  letters = {"S","A","P","I"},   -- huruf lingkaran
  minWordLength = 3,
  grid = { rows = 5, cols = 5 },
  words = {
    { word = "SAPI", row = 1, col = 1, dir = "across", clue = "Hewan ternak penghasil susu" },
    { word = "PIA",  row = 1, col = 3, dir = "down",   clue = "Kue kecil berbentuk bulat pipih" },
  },
  bonusWords = { "API", "PAS", "SIA" },
}
```

- File puzzle disimpan di **ServerStorage** (server-only), tidak pernah direplikasi ke client.
- Server mengirim ke client hanya: dimensi grid, posisi dan panjang tiap kata, nomor awal kata, clue teks, huruf lingkaran. **Bukan** huruf jawaban.

### 8.2 Pipeline pembuatan puzzle (offline)

1. **Daftar kata berlisensi terbuka** sebagai dasar (catat sumber dan lisensinya di `docs/`), lalu saring manual: buang kata terlalu langka, ambigu, atau tidak pantas.
2. Skrip generator (Python) di `tools/puzzle_gen/`: pilih himpunan huruf, cari kata yang dapat dibentuk, susun grid yang saling silang, hitung kata bonus.
3. Validator otomatis: semua kata grid dapat dibentuk dari huruf lingkaran, tidak ada kotak konflik, grid terhubung, tidak ada kata yang bertabrakan aneh.
4. Tulis clue orisinal (jangan menyalin definisi kamus atau clue TTS terbitan lain).
5. Uji main manual sebelum masuk bank puzzle.
6. Keluaran: file puzzle yang disinkronkan Rojo ke ServerStorage.

> Perhatikan **lisensi**: KBBI dan TTS terbitan tertentu dilindungi hak cipta. Periksa sumber daftar kata, dan tulis sendiri seluruh clue.

### 8.3 Tingkat kesulitan (awal, perlu dituning)

| Tingkat | Huruf lingkaran | Kata di grid | Waktu Duel |
|---|---|---|---|
| Mudah | 4 sampai 5 | 5 sampai 7 | 3 menit |
| Sedang | 5 sampai 6 | 8 sampai 11 | 4 menit |
| Sulit | 6 sampai 7 | 11 sampai 15 | 5 menit |

### 8.4 Pemilihan puzzle

- Server memilih puzzle yang belum pernah diselesaikan oleh sebagian besar pemain di meja.
- Jika bank habis, ulangi dengan prioritas puzzle terlama tidak dimainkan.

---

## 9. Progres dan Ekonomi

**Data pemain (DataStore):** koin, statistik (kata ditemukan, menang duel, puzzle selesai), daftar puzzle selesai, kosmetik yang dimiliki.

**Sumber koin:** kata bonus, menyelesaikan puzzle (Team), menang/ikut duel, bintang.

**Pemakaian koin:** v1 hanya hint (buka satu huruf / satu kata). Kosmetik (skin lingkaran huruf, tema grid, emote, skin meja) menyusul setelah v1.

**Monetisasi:** tidak ada di v1. Kosmetik menyusul setelah ada pemain yang bertahan. Tidak ada pay-to-win di Duel.

**Penyimpanan:** ProfileStore atau `DataStoreService` langsung dengan `UpdateAsync`, session lock, dan penanganan gagal-simpan. Simpan saat keluar dan berkala.

---

## 10. Arsitektur Teknis

### 10.1 Struktur proyek (Rojo)

```
proyek/
├─ default.project.json
├─ AGENTS.md                    # aturan kerja untuk agent
├─ docs/
│  ├─ GDD.md
│  ├─ SPEC.md
│  └─ adr/                      # Architecture Decision Records
├─ tools/puzzle_gen/            # generator + validator puzzle (Python)
├─ puzzles/                     # -> ServerStorage
├─ assets/                      # model meja (.rbxm) dari Studio
├─ src/
│  ├─ shared/                   # -> ReplicatedStorage
│  │  ├─ Types.luau
│  │  ├─ Constants.luau
│  │  ├─ Remotes.luau
│  │  └─ WordUtils.luau
│  ├─ server/                   # -> ServerScriptService
│  │  ├─ TableService.luau      # kursi, host, state machine meja
│  │  ├─ MatchService.luau      # aturan mode Team/Duel, skor
│  │  ├─ PuzzleService.luau     # muat + pilih puzzle
│  │  ├─ ValidationService.luau # validasi kata + rate limit
│  │  └─ DataService.luau       # DataStore
│  └─ client/                   # -> StarterPlayerScripts
│     ├─ MatchController.luau
│     ├─ Input/WheelInput.luau
│     ├─ UI/GridView.luau
│     └─ UI/LetterWheel.luau
└─ tests/
```

Catatan: model meja dibuat di Studio, diekspor sebagai `.rbxm`, lalu disinkronkan Rojo agar tetap dapat di-versioning.

### 10.2 Prinsip arsitektur

- **Server-authoritative.** Server menyimpan puzzle lengkap, state, skor, timer. Client hanya merender dan mengirim niat (kata yang diseret).
- **Logika murni dipisah dari Roblox API** (`WordUtils`, validasi multiset, penilaian skor, state machine) agar dapat diuji otomatis di luar Studio.
- **Kontrak remote didefinisikan di `shared/Remotes`** dan bertipe (Luau strict) sehingga client dan server tidak menyimpang.

### 10.3 Kontrak remote

**Client -> Server**

| Remote | Payload | Catatan |
|---|---|---|
| `Table_SetOptions` | `tableId, mode, format, difficulty` | Hanya host, hanya state Waiting. `format` (1v1/FFA/2v2) hanya untuk Duel dan divalidasi terhadap jenis meja |
| `Table_Start` | `tableId` | Hanya host |
| `Match_SubmitWord` | `tableId, word: string` | Divalidasi penuh di server |
| `Match_UseHint` | `tableId, hintType` | Kurangi koin di server |

**Server -> Client**

| Remote | Payload |
|---|---|
| `Match_Snapshot` | state, mode, format, pemain + tim, layout grid, huruf lingkaran, clue, kata terisi, skor, sisa waktu |
| `Match_WordAccepted` | `playerId, wordIndex, letters, score` |
| `Match_BonusFound` | `playerId, coins` |
| `Match_WordRejected` | `reason` (enum) |
| `Match_Result` | peringkat, bintang, koin didapat |

**Enum alasan tolak:** `NotSeated`, `WrongState`, `RateLimited`, `TooShort`, `InvalidLetters`, `AlreadySolved`, `NotAWord`.

### 10.4 Keamanan dan anti-exploit

- Jawaban tidak pernah dikirim sebelum ditemukan.
- Semua remote memvalidasi tipe, panjang string, dan keanggotaan pemain di meja.
- Rate limit per pemain (token bucket, misalnya maksimal beberapa submit per detik).
- Server tidak memercayai skor, waktu, atau koin dari client.
- Perubahan koin/data hanya lewat server.
- Log peristiwa mencurigakan (submit berlebihan, remote dengan payload aneh).

### 10.5 Performa

- Snapshot penuh hanya saat awal dan reconnect. Selanjutnya kirim event kecil (delta).
- Hindari alokasi berlebihan per frame di client (seretan huruf, garis).
- Target: stabil 60 FPS di ponsel kelas menengah dengan match aktif.

---

## 11. Testing dan QA

| Lapisan | Alat/cara | Yang diuji |
|---|---|---|
| Unit (logika murni) | Jest-Lua atau TestEZ, dapat dijalankan dengan Lune | Multiset letters, validasi kata, skor, state machine, pemilihan puzzle |
| Validator puzzle | Skrip Python di CI | Semua puzzle lolos aturan 8.2 |
| Integrasi | Playtest multi-client di Studio (Test > Local Server, 1 sampai 4 pemain, termasuk skenario 2v2) | Duduk/berdiri, sinkron papan, disconnect |
| UI/Input | Emulator perangkat Studio + perangkat asli | Seret huruf sentuh dan mouse, safe area, 70:30 |
| Statis | Selene + StyLua + luau-lsp (strict) | Lint, format, tipe |

**Definition of Done tiap fitur:** ada test untuk logika murninya, lulus lint/format, dimainkan manual di Studio (PC dan emulator mobile), tidak ada error di Output, dan dokumen terkait diperbarui.

---

## 12. Analytics (sederhana)

Catat: jumlah match per mode, waktu penyelesaian per puzzle, puzzle yang sering ditinggalkan, kata bonus yang sering dicoba (untuk memperkaya bank), drop-off saat countdown, rasio Team vs Duel.

---

## 13. Roadmap dan Milestone

| M | Tujuan | Kriteria selesai |
|---|---|---|
| M0 | Setup proyek | Rojo sync jalan, Selene/StyLua terpasang, struktur folder + `AGENTS.md`, test runner berjalan |
| M1 | Prototipe solo lokal | 1 puzzle hardcoded, UI 70:30, seret huruf berfungsi di PC dan emulator mobile |
| M2 | Validasi server | Validasi kata + kata bonus + rate limit di server, unit test lulus |
| M3 | Meja dan kursi | Tiga jenis meja (1/2/4 kursi), deteksi duduk/berdiri, host, kunci kursi, state machine, countdown, reset |
| M4 | Mode Team | Papan bersama, atribusi penemu kata, layar hasil |
| M5 | Duel 1v1 dan FFA | Klaim kata, skor, penentu pemenang, kasus disconnect |
| M5b | Duel 2v2 | Tim berdasarkan warna kursi, skor tim, kasus keluar per tim |
| M6 | Konten | Pipeline generator + 30 sampai 50 puzzle teruji, 3 tingkat kesulitan |
| M7 | Progres | DataStore, koin, hint, statistik |
| M8 | Polish | Suara, animasi, emote avatar, leaderboard, optimasi |
| M9 | Rilis beta | Uji dengan pemain nyata, analytics, perbaikan balancing |

---

## 14. Risiko

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Input sentuh tidak nyaman | Retensi mobile buruk | Uji di emulator dan perangkat asli sejak M1 |
| Kualitas puzzle rendah | Game terasa membosankan | Generator + validator + uji manual, bukan runtime generation |
| Exploit membaca jawaban | Duel tidak adil | Server-authoritative, jawaban hanya di ServerStorage |
| Lisensi daftar kata/clue | Masalah hak cipta | Sumber berlisensi jelas, clue orisinal |
| Kata tidak pantas di bank kata | Melanggar aturan platform | Filter dan tinjau manual |
| Agent menghasilkan API Roblox yang salah | Bug, waktu terbuang | Rujuk dokumentasi resmi Roblox, verifikasi di Studio, code review |
| Bank puzzle cepat habis | Pemain bosan | Pipeline konten berkelanjutan, mode harian |

---

## 15. Keputusan dan Pertanyaan Terbuka

### Keputusan yang sudah diambil

| # | Topik | Keputusan |
|---|---|---|
| 1 | Clue | Hybrid: bebas seret, clue sebagai bantuan |
| 2 | Jenis meja | 1, 2, dan 4 kursi. Meja 1 kursi untuk solo/latihan (Team) |
| 3 | UI saat match | Layar penuh + tombol perkecil UI |
| 4 | Meja 4 kursi | Mulai dengan minimal 2 pemain, kursi terkunci setelah mulai |
| 5 | Format Duel 4 kursi | Host memilih FFA atau 2v2 |
| 6 | Tebakan salah | Tanpa penalti (hanya rate limit) |
| 7 | Tim 2v2 | Berdasarkan warna kursi, dipilih pemain lewat kursi |
| 8 | Monetisasi | Belum ada di v1, kosmetik menyusul |
| 9 | Sumber kata | Daftar kata berlisensi terbuka + saring manual, clue orisinal |

### Asumsi yang perlu dikonfirmasi

1. Meja 2 kursi butuh 2 pemain untuk mulai (untuk bermain sendiri pakai meja 1 kursi).
2. Skor 2v2 dijumlahkan per tim.
3. Hint di Duel: dinonaktifkan atau dikenai penalti (diputuskan saat balancing).

### Masih terbuka

1. Daftar kata spesifik yang akan dipakai dan lisensinya (perlu dicek sebelum M6).
2. Nilai balancing: skor per kata, timer Duel, ambang bintang Team.
3. Tampilan papan status meja dan penanda warna kursi 2v2.

---

## Lampiran A: Draf `AGENTS.md` (aturan kerja agent)

```md
# Aturan proyek TTS Party
- Baca docs/GDD.md dan docs/SPEC.md sebelum mengubah kode.
- Bahasa: Luau strict (`--!strict`). Format dengan StyLua, lint dengan Selene.
- Server-authoritative: jangan pernah mengirim jawaban puzzle ke client.
- Logika murni ditaruh di src/shared dan wajib punya unit test.
- Verifikasi API Roblox dengan dokumentasi resmi (create.roblox.com/docs). Jangan mengarang API.
- Kerjakan per irisan kecil: satu fitur, test, commit. Jangan ubah banyak modul sekaligus.
- Remote baru wajib didefinisikan di src/shared/Remotes dan didokumentasikan di SPEC.md.
- Jangan mengedit file .rbxl/.rbxm secara manual; model dibuat di Studio.
- Keputusan arsitektur dicatat sebagai ADR di docs/adr/.
```
