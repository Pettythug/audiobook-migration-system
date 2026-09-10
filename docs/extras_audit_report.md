# FORENSIC AUDIT: Audiobookshelf Manifest Reconciliation & Analysis of 'Extras'

## 1. Executive Summary
- **Total Audiobooks in Master Library:** **2,958**
- **Verified Original (100% Canonical Audiobookshelf Match):** **960 titles** (Organized into `Audiobooks\Author\Series\Title [ASIN]`)
- **Total 'Extras' in `Audiobooks\_Uncataloged`:** **1,998 items** (~599.24 GB)
- **Unique Base Titles in Extras:** **664 unique books/albums**

---

## 2. Why Do We Have 'Extras' That Don't Exist in Audiobookshelf?
Our comprehensive cross-reference identified three distinct reasons for the extras residing in `Audiobooks\_Uncataloged`:

### Reason A: Collision Duplicate Clusters (607 clusters, 1,941 folders, 1,334 redundant copies)
- **What Happened:** When legacy snapshots (pCloud, Drive E, Drive I) were consolidated, multiple versions of the exact same book existed across different folders.
- **Why They Are in Extras:** Because these titles lacked an exact Audiobookshelf ASIN to arbitrate against automatically, our safety engine applied deterministic collision suffixes (`_1`, `_hash`) under our **Zero-Loss Rule** rather than risk overwriting data.
- **Storage Impact:** Approximately **384.09 GB** of storage is consumed by redundant duplicate copies.

### Reason B: Manifest Titles with Modified Names or Missing ASINs (70 base titles)
- **What Happened:** These are legitimate Audiobookshelf titles, but their disk folders had prefixes (e.g. `(Audio Book)`, `[01]`, track numbers) or omitted the Audible ASIN in the folder name.
- **Why They Are in Extras:** Strict ASIN matching isolated them to prevent accidental misfiling into the canonical tree.

### Reason C: Genuine Standalone Extras (594 base titles)
- **What Happened:** These are legitimate audiobooks, dramatizations, web serials, and legacy rips that were **never added to your Audiobookshelf server** in the first place.
- **Examples:** GraphicAudio full-cast productions (e.g. *Venom*, *Wayne of Gotham*, *Wonder Woman*), LitRPG web novel audio rips (e.g. *A Thousand Li*, *Awaken Online*), and old CD/tape rips (e.g. Stephen King's *Cell*).

---

## 3. Top Collision Duplicate Clusters (Ready for Future Deduplication)
| Base Title | Duplicate Copies | Formats | Total Size (MB) | Redundant Waste (MB) |
| :--- | :--- | :--- | :--- | :--- |
| `Book 1 - Foundation` | **20 copies** | .mp3 | 3,061.0 MB | 2,891.0 MB |
| `Book 3 - Second Foundation` | **20 copies** | .mp3 | 3,693.6 MB | 3,488.5 MB |
| `Asimov - R. Daneel Olivaw - Book 01 - Caves O` | **16 copies** | .mp3 | 2,990.9 MB | 2,777.7 MB |
| `Robots & Empire` | **16 copies** | .mp3 | 5,560.5 MB | 5,163.7 MB |
| `Azazel` | **14 copies** | .mp3 | 2,308.0 MB | 2,143.2 MB |
| `F01 - Foundation` | **14 copies** | .mp3 | 2,374.6 MB | 2,205.3 MB |
| `Fantastic Voyage` | **14 copies** | .mp3 | 2,521.0 MB | 2,340.9 MB |
| `The Greeks` | **12 copies** | .mp3 | 3,422.2 MB | 3,137.0 MB |
| `12 The Spine Of The World` | **11 copies** | .mp3 | 2,159.6 MB | 1,899.8 MB |
| `Origins - Neil deGrasse Tyson - Audiobook - U` | **9 copies** | .mp3 | 1,528.0 MB | 1,287.3 MB |
| `Star Wars` | **9 copies** | .mp3 | 1,331.8 MB | 1,113.0 MB |
| `13 Sea Of Swords` | **8 copies** | .mp3 | 2,002.6 MB | 1,752.0 MB |
| `28 Night Of The Hunter` | **8 copies** | .mp3 | 2,579.5 MB | 2,256.7 MB |
| `[01] The Farseer` | **7 copies** | .mp3 | 1,981.5 MB | 1,954.4 MB |
| `02 Exile` | **7 copies** | .mp3 | 1,306.6 MB | 1,151.8 MB |
| `Black Panther [The Young Prince]` | **7 copies** | .mp3 | 717.9 MB | 559.3 MB |
| `02 - Ian Fleming - Live and Let Die` | **6 copies** | .mp3 | 1,071.6 MB | 887.9 MB |
| `101-Tempest[Legacy Of The Force Book 3]` | **6 copies** | .mp3 | 2,077.4 MB | 1,731.2 MB |
| `104-Inferno[Legacy Of The Force Book 6]` | **6 copies** | .mp3 | 2,063.0 MB | 1,719.2 MB |
| `106-Revelation[Legacy Of The Force Book 8]` | **6 copies** | .mp3 | 2,461.3 MB | 2,051.0 MB |
| `10-The Dangerous Games[Jedi Quest Book 3]` | **6 copies** | .mp3 | 796.2 MB | 663.5 MB |
| `11-The Master of Disguise[Jedi Quest Book 4]` | **6 copies** | .mp3 | 784.4 MB | 653.7 MB |
| `12-The Approaching Storm` | **6 copies** | .mp3 | 1,752.1 MB | 1,460.1 MB |
| `13-Attack Of The Clones` | **6 copies** | .mp3 | 1,072.5 MB | 893.8 MB |
| `14-Shatterpoint` | **6 copies** | .mp3 | 795.7 MB | 663.1 MB |
| `15-The Cestus Deception` | **6 copies** | .mp3 | 831.8 MB | 693.2 MB |
| `16-Battle Surgeons[Medstar Book 1]` | **6 copies** | .mp3 | 1,052.8 MB | 877.5 MB |
| `17-Jedi Healer[Medstar Book 2]` | **6 copies** | .mp3 | 933.1 MB | 777.8 MB |
| `19-Dark Rendezvous` | **6 copies** | .mp3 | 1,261.3 MB | 1,051.3 MB |
| `20-Labyrinth Of Evil` | **6 copies** | .mp3 | 1,668.9 MB | 1,390.9 MB |

---

## 4. Probable Audiobookshelf Matches (Fuzzy Name Resolution)
| Uncataloged Folder Name | Probable Audiobookshelf Title | Manifest Author | Manifest ASIN |
| :--- | :--- | :--- | :--- |
| `[01, Dramatized Adaptation] The Highwaym` | The Highwayman [Dramatized Adaptati | R. A. Salvatore | `1648802362` |
| `[01] A Thousand Li` | A Thousand Li: The First War | Tao Wong | `1515933989` |
| `[01] Ahren` | Ahren | Torsten Weitze | `1705200281` |
| `[01] Awaken Online` | Awaken Online: Evolution | Travis Bagwell | `B07DWDD8L9` |
| `[01] Beware of Chicken` | Beware of Chicken: A Xianxia Cultiv | Casualfarmer | `B09Y2D2D5T` |
| `[01-] Disgardium Series` | Disgardium Series # , Disgardium Se | Dan Sugralinov, Andr | `B09GHBG5XP` |
| `[01-] Foodstuffs LitRPG Box Set` | Foodstuffs LitRPG Box Set: Books 1- | Arthur Stone | `B0BGML55KY` |
| `[01] He Who Fights with Monsters` | He Who Fights with Monsters: A LitR | Shirtaloon, Travis D | `1774248182` |
| `[01] I'm Not the Hero` | I'm Not the Hero: An Isekai LitRPG | SourpatchHero, Tommy | `B0CH1L61BG` |
| `[01] NPCs` | NPCs | Drew Hayes | `B00NHY147E` |
| `[01-] Sherlock Holmes` | Sherlock Holmes: The Definitive Col | Arthur Conan Doyle,  | `B06WLMWF2S` |
| `[01-] Steamborn` | Steamborn: The Complete Trilogy Box | Eric Asher | `B0764H1QWG` |
| `[01] Super Powereds` | Super Powereds: Year One (1 of 3) ( | Drew Hayes | `1648816606` |
| `[01] Super Powereds (2)` | Super Powereds: Year One (1 of 3) ( | Drew Hayes | `1648816606` |
| `[01] Super Powereds (3)` | Super Powereds: Year One (1 of 3) ( | Drew Hayes | `1648816606` |
| `[01] System Change` | System Change: A LitRPG Adventure | SunriseCV | `B0BH9FDKP8` |
| `[01] The Demon Awakens` | The Demon Awakens (Dramatized Adapt | R.A. Salvatore | `B0B7XNY87P` |
| `[01-] The Extinction New Zealand Series ` | The Extinction New Zealand Series B | Adrian J. Smith | `1094189286` |
| `[01] The Farseer` | The Farseer: Assassin's Apprentice  | Robin Hobb | `B003AO3P5A` |
| `[01] Viridian Gate Online` | Viridian Gate Online: Inquisitor's  | D.J. Bodden, James H | `1630155985` |
| `[01] We Are Legion` | We Are Legion (We Are Bob) | Dennis E. Taylor | `B01L082HJ2` |
| `[01] Zero G` | Zero G | Dan Wells | `B07K4VYQ5X` |
| `[02, Dramatized Adaptation] The Ancient` | The Ancient [Dramatized Adaptation] | R. A. Salvatore | `1648809936` |
| `[02] A Thousand Li` | A Thousand Li: The First War | Tao Wong | `1515933989` |
| `[02] Awaken Online` | Awaken Online: Evolution | Travis Bagwell | `B07DWDD8L9` |

---

## 5. Sample Genuine Standalone Audiobooks (Never in Audiobookshelf)
| Title | Format | Size (MB) | Sample Disk Path |
| :--- | :--- | :--- | :--- |
| `Exported` | .m4b | 134,586.0 MB | `Audiobooks\_Uncataloged\Exported...` |
| `Stephen Fry` | .mp3 | 8,362.1 MB | `Audiobooks\_Uncataloged\Stephen Fry...` |
| `Black Panther [Who Is The Black Panther]` | .m4b | 5,595.9 MB | `Audiobooks\_Uncataloged\Black Panther [Who Is The ...` |
| `Robots & Empire` | .mp3 | 5,560.5 MB | `Audiobooks\_Uncataloged\Robots & Empire...` |
| `Book 3 - Second Foundation` | .mp3 | 3,693.6 MB | `Audiobooks\_Uncataloged\Book 3 - Second Foundation...` |
| `The Greeks` | .mp3 | 3,422.2 MB | `Audiobooks\_Uncataloged\The Greeks...` |
| `05 - Harry Potter and the Order of the Phoeni` | .mp3 | 3,200.7 MB | `Audiobooks\_Uncataloged\05 - Harry Potter and the ...` |
| `Dreams` | .mp3 | 3,086.7 MB | `Audiobooks\_Uncataloged\Dreams...` |
| `Book 1 - Foundation` | .mp3 | 3,061.0 MB | `Audiobooks\_Uncataloged\Book 1 - Foundation...` |
| `Stephen King - Dark Tower 4 - Wizard and Glas` | .mp3 | 3,039.4 MB | `Audiobooks\_Uncataloged\Stephen King - Dark Tower ...` |
| `Captain Marvel [Liberation Run]` | .mp3 | 3,001.1 MB | `Audiobooks\_Uncataloged\Captain Marvel [Liberation...` |
| `Asimov - R. Daneel Olivaw - Book 01 - Caves O` | .mp3 | 2,990.9 MB | `Audiobooks\_Uncataloged\Asimov - R. Daneel Olivaw ...` |
| `27.2-A New Hope Radio Drama` | .mp3 | 2,934.5 MB | `Audiobooks\_Uncataloged\27.2-A New Hope Radio Dram...` |
| `Marvel - Deadpool 01 - Paws [GraphicAudio-256` | .mp3 | 2,779.9 MB | `Audiobooks\_Uncataloged\Marvel - Deadpool 01 - Paw...` |
| `Marvel - Avengers - Everybody Wants To Rule T` | .mp3 | 2,734.1 MB | `Audiobooks\_Uncataloged\Marvel - Avengers - Everyb...` |
| `Marion Zimmer Bradley - The Mists of Avalon U` | .mp3 | 2,652.2 MB | `Audiobooks\_Uncataloged\Marion Zimmer Bradley - Th...` |
| `28 Night Of The Hunter` | .mp3 | 2,579.5 MB | `Audiobooks\_Uncataloged\28 Night Of The Hunter...` |
| `Fantastic Voyage` | .mp3 | 2,521.0 MB | `Audiobooks\_Uncataloged\Fantastic Voyage...` |
| `106-Revelation[Legacy Of The Force Book 8]` | .mp3 | 2,461.3 MB | `Audiobooks\_Uncataloged\106-Revelation[Legacy Of T...` |
| `F01 - Foundation` | .mp3 | 2,374.6 MB | `Audiobooks\_Uncataloged\F01 - Foundation...` |
| `[02] Iron Will` | .mp3 | 2,328.5 MB | `Audiobooks\_Uncataloged\[02] Iron Will...` |
| `Azazel` | .mp3 | 2,308.0 MB | `Audiobooks\_Uncataloged\Azazel...` |
| `Venom [Lethal Protector]` | .mp3 | 2,305.6 MB | `Audiobooks\_Uncataloged\Venom [Lethal Protector]...` |
| `04 - Harry Potter and the Goblet of Fire` | .mp3 | 2,304.2 MB | `Audiobooks\_Uncataloged\04 - Harry Potter and the ...` |
| `52-The Last Command[The Thrawn Trilogy Book 3` | .mp3 | 2,295.5 MB | `Audiobooks\_Uncataloged\52-The Last Command[The Th...` |

---

## 6. Recommended Next Steps (Future Consolidation)
1. **Proceed with Sync to P:\:** All 2,960 audiobooks are safely self-contained inside `Audiobooks`.
2. **Future TASK-017:** Purge the 1,334 redundant duplicate copies in `Audiobooks\_Uncataloged` to save ~384.09 GB of space.
3. **Audiobookshelf Library Scan:** Once copied to `P:\04_Media\Audiobooks`, run a library scan in Audiobookshelf so it can automatically detect and catalog the genuine extras into its web interface.