# Changelog

## 1.2.1 (2026-11-13)

- Fixed: steam around the engine follows its valve. A blowdown cracked open
  blows a little and one wide open blows hard, whatever you opened first;
  the same for the whistle, safety valves, dynamo, and a cracked cylinder.

## 1.2.0 (2026-11-13)

- **The chimney's exhaust looks more like the real thing.** Each beat's
  steam leaves as a burst that dies away, where it left all at once: at
  slow, hard beats the plume starts at the stack's rim, not some metres
  over it. In damp air its steam is white from the rim up, and a smoky
  start no longer comes out of the stack in two colors.
- **New: Auto smoke quality.** Smoke quality has a fourth choice. Auto
  draws the smoke at High and lowers it only while the game runs under 45
  frames a second with smoke in the air and the lower quality helps, then
  raises it again when the game runs well. High is still the default.
- The steam around the engine is drawn behind the chimney's smoke where
  it is behind it, where it showed in front of the smoke from every side.

## 1.1.0 (2026-11-11)

- **New: steam around the engine.** The dynamo, cylinder cocks, safety
  valves, whistle, glands, and small leaks now steam like the chimney's
  plume, by the weather: long white trails on a frosty day, little or
  nothing on a hot one. It needs Custom smoke effects; turn it off with
  Steam around the engine in the settings (restart required). With
  Realistic Firing 1.18.0, its booster and injector-overflow steam are
  drawn too.
- **Better frame rates.** The chimney smoke now costs about half as much
  for the engine you are on and far less for engines out of view or far
  away, and no longer gets heavier when the frame rate falls under 60.
- Smoke and steam no longer stay lit by the sun after it has set.

## 1.0.3 (2026-11-01)

- Faint smoke and steam fade out instead of disappearing at the cutoff.

## 1.0.2

- **Fixed:** the white steam faded away on a warm day, most of all with the
  regulator eased. A summer afternoon now keeps a short white at the stack,
  and easing the regulator no longer takes it away.
- **Fixed:** an engine could pile up duplicate chimney effects over time,
  thickening the smoke and slowing the game down.
- **Heat shimmer:** now drawn before the smoke, so it no longer roughens the
  plume's edges, and it shares TurboTurbo's: with both mods installed, the
  plumes no longer get holes.

## 1.0.1

- **Mod list:** Unity Mod Manager's home page link now opens the Nexus page.
- **Fixed:** when the train slowed or stopped, the smoke it had left behind
  drew back in and hung in the air along the line, and smoke left below the
  stack, past a crest, was carried along with the train.
- **Smoke quality:** Medium and Low now also drop the faintest smoke at the
  plume's far end, the biggest cost on a slower graphics card.

## 1.0.0

- **First release:** Realistic Firing's chimney smoke and steam on every
  steam locomotive, on its own. A puff on every exhaust beat, a buoyant
  plume that spreads and drifts with the wind, smoke colored by the fire,
  white steam that follows the weather and DV Seasons, heat shimmer,
  cinders, and smoke held under tunnel roofs.
- **A fresh shovelful smokes out** on the game's own firebox: dark for a
  few seconds, then clearing, sooner on a hard-worked fire.
- **Works with Realistic Firing 1.16.0 or newer**, which feeds it the
  realistic fire.
