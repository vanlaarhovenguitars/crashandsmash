# Crash and Smash — Design

The source of truth for game mechanics, captured from a design conversation between Owen
and his son **Zane**, plus the build roadmap.

## Concept

A lane-defense game in the style of *Plants vs. Zombies*, reskinned for kids:

- Instead of plants vs. zombies, it's **Mr. Beast toys & creatures** defending against
  advancing **robots**.
- The player places defenders on a lane grid; defenders auto-attack robots that march in
  from the right. If a robot reaches the **base** (left edge), the player loses.
- The player can field a mix of characters: a **toy**, a **creature**, and a **bat**.

## Stages

| Stage | Objective | Notes |
|-------|-----------|-------|
| 1 | Defeat **3** robots | Introduces placing units and the economy. |
| 2 | Defeat **4** enemies | Adds more enemy variety. |
| 3 | **Endless** — defeat as many as you can | Player freely picks toy / creature / bat. |

These numbers live in code at [`core/StageRules.gd`](core/StageRules.gd) and are covered by
tests, so they're easy to tune.

## Characters (current prototype)

Defenders and the enemy are defined in [`data/Units.gd`](data/Units.gd):

- **Money Printer** (toy) — generates coins over time (the economy engine).
- **Beast Toy** — medium-cost shooter.
- **Creature** — expensive, high-HP wall with a short-range hit.
- **Bat** — fast, cheap, light shooter (Zane specifically wanted a bat).
- **Robot** — the enemy: marches left, attacks defenders, ends the game if it reaches base.

All art is currently placeholder colored shapes + labels, so swapping in real sprites later
is a small, isolated change.

## Platform priority

From the recording, in order:

1. **TV first** — the family's **NVIDIA Shield**, which is **Android TV**. Controls are
   designed for a gamepad (d-pad cursor + A to place).
2. **Tablet**
3. **Phone**
4. ~~Nintendo Switch~~ — out of scope; it isn't open to sideloading.

Godot exports a single Android `.apk` that covers TV + tablet + phone. See the README for
the export steps.

## Roadmap (beyond this prototype)

- [x] Stage 1 playable prototype (2D lane defense)
- [x] Stage progression 1 → 2 → 3 with scaling difficulty (win advances; lose resets)
- [x] 3D Arena mode — walk-around shooter (Garden Warfare–style) with auto-aim, touch
      joystick, robots, health, and the same stage rules. Now the default scene.
- [x] 3D: enemies styled after MrBeast Lab "Swarms" mini-monsters — blobby, big-eyed beasts
      in random colours with random features (horns/antennae/spikes/fins): fast "swarmlings"
      and big "brutes", each with walk/hop, attack lunge, hit-flash, and death-burst animations
- [x] 3D: rounder characters (capsule limbs, spherical heads/bodies), a bigger arena, and
      terrain — trees, rocks, bushes, and gentle mounds — plus sky + checkerboard floor
- [ ] 3D: real rigged character models + mocap animations (free from Mixamo/Quaternius/Kenney)
- [ ] 3D: manual aim option (twin-stick / gamepad right stick) for older players
- [ ] 3D: more enemy types, obstacles, pickups, and bigger levels
- [ ] Main menu + character-select screen
- [ ] Per-stage enemy variety (more than just the Robot)
- [ ] Real art & sound to replace placeholders
- [ ] Persist progress so closing the app remembers your stage
- [ ] Produce and sign the Android APK; test on the Shield with a controller

### How progression works now
Winning a finite stage advances `GameState.current_stage`; the next load of the stage
scene reads it and scales spawn rate + robot HP/speed, and reads the new kill target from
`StageRules`. Stage 3 is endless (play until a robot reaches the base). Losing resets to
Stage 1. All of this is covered by `tests/integration_test.gd`.

## A note on the "Mr. Beast" theme

This is a personal, non-commercial project for the family. If it's ever shared publicly,
the character names/art should be changed to original ones to avoid using someone else's
brand — the code reads all names and art from `data/Units.gd`, so a reskin is trivial.
