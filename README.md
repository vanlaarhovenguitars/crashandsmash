# Crash and Smash

A kids' action game built in **Godot 4**, running from one codebase on the family TV
(NVIDIA Shield / Android TV), tablets, and phones. Placeholder shapes for now, real gameplay.

There are **two modes** in the repo:

- **🕹️ 3D Arena (current default)** — a walk-around 3D shooter (Garden Warfare–style): run
  around an arena, robots chase you, and your hero auto-aims and shoots them. Defeat 3 to
  clear Stage 1. This is what the main scene / phone link launches.
- **🌱 2D Lane Defense** — the original *Plants vs. Zombies*–style game: place toys/creatures
  on lanes to stop advancing robots. Still in the repo at `scenes/Main.tscn`.

> See [`DESIGN.md`](DESIGN.md) for the full design (from the recording with Zane) and roadmap.

## How to play the 3D Arena
- **Move:** WASD / left stick / left-side touch joystick (drag anywhere on the left half).
- **Shooting is automatic** — your hero locks onto the nearest robot and fires. Just steer!
- **Goal:** defeat 3 robots to clear Stage 1 (it gets harder each stage; Stage 3 is endless).
- Win/lose, then **tap / Enter / gamepad A** to continue.

## Play it (on your computer)

1. Download **Godot 4.3 or newer** (the standard, non-.NET build): https://godotengine.org/download
2. Launch Godot → **Import** → pick this folder's `project.godot` → **Open**.
3. Press **Play** (the ▶ button, top-right) or **F5**. (To try the 2D mode instead, open
   `scenes/Main.tscn` and press **Play Current Scene** / F6.)

### How to play the 2D Lane Defense mode

## Play it (on your computer)

1. Download **Godot 4.3 or newer** (the standard, non-.NET build): https://godotengine.org/download
2. Launch Godot → **Import** → pick this folder's `project.godot` → **Open**.
3. Press **Play** (the ▶ button, top-right) or **F5**.

### How to play
- Goal: **defeat 3 robots** (Stage 1) before any robot reaches your **BASE** on the left.
- Win a stage to advance: **Stage 1 → 2 → 3**, getting harder each time (Stage 3 is endless).
  Win/lose, then press **Enter / A** to continue (or restart from Stage 1 after a loss).
- **Pick a unit:** click a button in the top bar, press number keys **1–4**, or use the
  gamepad **shoulder buttons**.
- **Place it:** move the highlighted cursor with **arrow keys / d-pad / left stick**, then
  press **Enter / Space / gamepad A**. Or just **click / tap** a cell directly.
- Units cost **coins**. Start with a **Money Printer** to grow your income, then add
  **Beast Toys** and **Bats** to shoot, and **Creatures** as tough walls.

| Unit | Cost | Role |
|------|------|------|
| Money Printer | 25 | Generates coins over time |
| Beast Toy | 50 | Shoots down its lane |
| Creature | 100 | High-HP wall, short-range hit |
| Bat | 40 | Fast, light shooter |

## Run the logic tests

Two headless suites — pure-logic unit tests and an integration test that drives the real
Stage scene (placing, combat, winning, advancing, losing):

```bash
godot --headless --script res://tests/run_tests.gd          # logic units
godot --headless --script res://tests/integration_test.gd   # full gameplay loop
```

Each prints `PASS:`/`FAIL:` per check and exits non-zero if anything fails.

## Play on your phone (instant, no install)

Every push auto-builds a web version and publishes it to **GitHub Pages**, so the latest
game is always playable in a phone or desktop browser — just open the link and tap to play.

**One-time setup (two clicks in the repo on github.com):**
1. **Settings → General → Danger Zone → Change repository visibility → Public.**
   (GitHub Pages is free only for public repos.)
2. **Settings → Pages → Build and deployment → Source → "GitHub Actions".**

After that, the URL is shown at **Settings → Pages** (and on each successful
"Deploy web build to GitHub Pages" run under the **Actions** tab). Bookmark it on the phone.
Rotate the phone to **landscape** for the best fit.

## Next: get it on the NVIDIA Shield (Android TV)

Once you're happy with the gameplay, export an Android app:

1. In Godot: **Editor → Manage Export Templates → Download and Install**.
2. Install the Android SDK / set the JDK path (Godot's **Editor Settings → Export → Android**
   has a one-click setup, or point it at Android Studio's SDK).
3. **Project → Export → Add… → Android.** Keep orientation **Landscape**; tick the
   **TV** banner option so it shows in the Shield's app list.
4. **Export Project** to an `.apk`, then sideload it onto the Shield:
   ```bash
   adb connect <shield-ip>
   adb install crashandsmash.apk
   ```
5. Test with the Shield controller — the d-pad cursor + A-to-place controls are built for it.

Phone/tablet use the same APK; touch controls already work.

## Project layout

```
project.godot          Godot config (1920x1080, landscape, mobile renderer)
autoload/GameState.gd  Cross-stage progress singleton
core/                  Pure, unit-tested rules (StageRules, Economy, CombatMath)
data/Units.gd          All unit stats — tweak here to balance / reskin
scenes/                Main + Stage1 (the level controller)
units/                 Defender, Robot, Projectile (placeholder visuals in code)
ui/HUD.gd              Coin/defeat counters, unit picker, win/lose banner
tests/run_tests.gd     Headless logic tests
```
