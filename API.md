# Realistic Stack Effects for locomotive makers

How a Custom Car Loader locomotive, or another mod, works with Realistic
Stack Effects' chimney smoke and steam. Most locomotives need no code at
all. The public API, `RealisticStackEffects.Api.StackSources`, is for mods
that simulate their own fire, draw their own steam vents, or want to give
chimney dimensions from code.

## With no code

- **The plume is automatic.** Every steam locomotive with the game's own
  chimney smoke gets it, Custom Car Loader steam engines included. It reads
  the engine's stock firebox and exhaust, and measures the chimney from its
  mesh where it can.
- **Chimney size through Realistic Firing.** With Realistic Firing
  installed, a maker-fit file (`realistic-firing.json` in your mod's
  folder) can give the chimney's dimensions in its `stack` section:

  ```json
  {
    "schemaVersion": 1,
    "liveries": ["MyLoco"],
    "stack": {
      "lipHeightM": 0.44,
      "boreRadiusM": 0.22,
      "outsideRadiusM": 0.30
    }
  }
  ```

  The same file sets up Realistic Firing's simulation for those liveries.
  The format is documented in Realistic Firing's
  [MAKER-FIT.md](https://github.com/Specter242/DVRealisticFiring/blob/main/MAKER-FIT.md).
  Without Realistic Firing, nothing reads this file; use
  `RegisterGeometry` below instead.

## When to use the API

| You want to | Call | Since |
| --- | --- | --- |
| Drive the plume from your mod's own fire instead of the stock firebox | `StackSources.Register` | `ApiVersion` 1 (Realistic Stack Effects 1.0.0) |
| Add named steam vents around the engine (a booster's exhaust, an injector's overflow) | `StackSources.EngineSteam` | `ApiVersion` 2 (1.1.0) |
| Give chimney dimensions from code, without needing Realistic Firing | `StackSources.RegisterGeometry` | `ApiVersion` 3 (1.3.0) |

If none of these applies, you need nothing from this guide.

## Setting up a soft dependency

Your mod should load and run whether or not Realistic Stack Effects is
installed.

- **Info.json:** list `"RealisticStackEffects"` in `LoadAfter`, so it has
  loaded before yours. Don't list it in `Requirements`.
- **References:** reference `RealisticStackEffects.dll` from the installed
  mod (`Mods/RealisticStackEffects/`) with `Private="false"`, so it is never
  copied into your mod. The API's types also use `Assembly-CSharp`,
  `DV.Simulation` (`SteamExhaust`), `DV.ThingTypes` (liveries) and
  `UnityEngine.CoreModule`.
- **Keep the API's types out of your main assembly.** A class that
  implements `IStackFireSource`, or has a field of one of the API's types,
  can't load when Realistic Stack Effects isn't installed, and any scan of
  your assembly's types then fails. Put the code that touches the API in a
  small add-on assembly that ships beside your mod's, and load it only when
  Realistic Stack Effects is active. Realistic Firing does it this way.

In your main mod, which names no API type:

```csharp
using System;
using System.IO;
using System.Reflection;
using UnityModManagerNet;

internal static class StackEffectsLoader
{
    // Call from your Load entry method.
    public static void TryStart(UnityModManager.ModEntry mod)
    {
        try
        {
            var stack = UnityModManager.FindMod("RealisticStackEffects");
            if (stack == null || !stack.Active)
                return;
            var path = Path.Combine(mod.Path, "MyLoco.StackEffects.dll");
            if (!File.Exists(path))
                return;
            var start = Assembly.LoadFrom(path)
                .GetType("MyLoco.StackEffects.Link")
                ?.GetMethod("Start", BindingFlags.Public | BindingFlags.Static);
            start?.Invoke(null, new object[] { mod.Info.Id });
        }
        catch (Exception e)
        {
            mod.Logger.LogException("Linking to Realistic Stack Effects failed; the plume reads the stock firebox", e);
        }
    }
}
```

## Checking `ApiVersion`

`StackSources.ApiVersion` is a property, read at run time, and it is
currently `3`. Check it before using anything added after version 1, so
your add-on still runs against an older Realistic Stack Effects:

- Put each reference to a newer member or type in its own method marked
  `[MethodImpl(MethodImplOptions.NoInlining)]`, and call it only behind the
  check. A method is compiled when it first runs, so a missing member then
  fails only in a method that never runs.
- Make a delegate whose type names a newer type with `new Func<...>(...)`,
  not from a method group or a lambda that captures nothing. The compiler
  caches those in a hidden class with a field of the delegate's type, and
  against an older version that class can't load.
- Keep newer types out of field types and base types; a field can be
  typed `object` instead.

The add-on's entry point:

```csharp
using System;
using System.Runtime.CompilerServices;
using RealisticStackEffects.Api;

namespace MyLoco.StackEffects
{
    public static class Link
    {
        public static void Start(string modId)
        {
            // Version 1: in every release.
            StackSources.Register(modId, car => MyFireboxes.TryGet(car, out var firebox) ? new MyFireSource(car, firebox) : null);
            MyBoosterSteam.Enabled = StackSources.ApiVersion >= 2;
            if (StackSources.ApiVersion >= 3)
                RegisterGeometry(modId);
        }

        [MethodImpl(MethodImplOptions.NoInlining)]
        private static void RegisterGeometry(string modId) =>
            StackSources.RegisterGeometry(modId, new Func<TrainCar, StackGeometry?>(Chimney.GeometryFor));
    }
}
```

`MyFireboxes`, `MyFireSource`, `MyBoosterSteam` and `Chimney` stand for
your own code; the sections below sketch them. Register while your mod
loads, before any locomotive spawns.

## Feeding your own fire: `Register` (version 1)

```csharp
public static void Register(string modId, Func<TrainCar, IStackFireSource> provider)
```

- As each steam locomotive's smoke is set up, every registered provider is
  asked, in registration order, for that engine's fire. Answer `null` for
  an engine that isn't yours, and the game's own firebox is read. The
  first provider to answer wins.
- An empty `modId` or a null `provider` throws `ArgumentException`.
- The source's `Read` is called each frame with the frame's time step in
  seconds, the engine's `SteamExhaust` (null where the plume found none),
  and a `StackFireReading` that starts empty, all zeros. `Tended` says
  whether the player is on this engine or its tender.

`StackFireReading`'s fields:

| Field | Meaning |
| --- | --- |
| `FireOn` | Whether the fire is lit. |
| `Heat`, `MostHeat` | The fire's heat and the most it makes, W. |
| `Soot` | Visible smoke leaving the fire, 0 to 1; about 0.5 is the blackest. |
| `FireboxGas`, `FireboxSmokeOut` | The firebox's gas, and a fresh shovelful's thick smoke, reaching the stack, in firebox puffs a second. |
| `ClearStack` | How clear the stack is between beats, 0 to 1: 0 is a clean fire's haze, 1 none (too much air). |
| `AirThrough` | The air drawn through the fire, kg/s. |
| `Cinders` | Whether the fire throws cinders at all; an oil burner throws none. |
| `Fines`, `ShakenCoal` | Cinders bound for the stack this frame, kg: a stoker's lost fines (out with the next beat) and a shaken grate's live coal (out over the next few). |
| `PlugSteam` | A melted fusible plug's steam leaving the stack, kg/s. |
| `ExhaustWetness` | The share of the exhaust still water as it leaves, 0 to 0.3, or `float.NaN` to keep the last value. |
| `StackSteam`, `BlowerSteam` | The steam going up the stack, kg/s (the exhaust's, the blower's, and any air pump's), and the blower's and pump's alone. |
| `NaturalFlow` | The stack's natural draft as a share of the smokebox's stock total flow; `float.NaN` without a draft to read. |

A minimal source, for a fire your mod simulates:

```csharp
using LocoSim.Implementations;
using RealisticStackEffects.Api;
using UnityEngine;

internal sealed class MyFireSource : IStackFireSource
{
    private readonly TrainCar car;
    private readonly MyFirebox firebox;

    public MyFireSource(TrainCar car, MyFirebox firebox)
    {
        this.car = car;
        this.firebox = firebox;
    }

    public bool Tended => PlayerManager.Car == car;

    public void Read(float dt, SteamExhaust exhaust, ref StackFireReading reading)
    {
        reading.FireOn = firebox.Lit;
        reading.Heat = firebox.HeatWatts;
        reading.MostHeat = firebox.MaxHeatWatts;
        reading.Soot = 0.5f * firebox.Smokiness;   // Smokiness 0 to 1
        reading.AirThrough = firebox.AirKgPerSecond;
        reading.ClearStack = firebox.ExcessAir;     // 0 to 1
        reading.Cinders = true;
        reading.ExhaustWetness = float.NaN;
        reading.NaturalFlow = float.NaN;
        if (exhaust != null)
            reading.StackSteam = Mathf.Max(0f, exhaust.exhaustFlow.Value);
    }
}
```

## Steam vents around the engine: `EngineSteam` (version 2)

```csharp
public static IEngineSteam EngineSteam(TrainCar car)

// IEngineSteam
bool Add(string name, string kind, Vector3 at, Vector3 facing, Func<float> strength);
```

- `EngineSteam` returns the steam Realistic Stack Effects draws around
  `car`, or `null` where it draws none (no plume on that engine yet, or the
  player has switched the engine steam off). It is the same object for as
  long as the engine's steam is the same.
- `Add` adds a source: steam of `kind` leaving at `at`, toward `facing`,
  both in the car's own frame (meters from the car's origin), as hard as
  `strength` returns each frame, 0 to 1. A null `name` takes the kind's.
- Kinds: `CylinderCock`, `CylinderCrack`, `BoosterExhaust`, `Overflow`,
  `PumpExhaust`, `Leak`, `Gland`, `Weep`, `FittingWeep`, `Dynamo`,
  `Whistle`, `SafetyValve`, `Blowdown`. Names are case-sensitive.
- `Add` returns false for a kind this version doesn't know, a null
  `strength`, or a zero `facing`.
- A source lasts as long as the `IEngineSteam` it was added to. Ask
  `EngineSteam` again now and then, and add your sources again when it
  answers with a different object.
- `strength` runs every frame, so keep it cheap.

A component on your locomotive, in the add-on:

```csharp
using System;
using System.Runtime.CompilerServices;
using RealisticStackEffects.Api;
using UnityEngine;

internal sealed class MyBoosterSteam : MonoBehaviour
{
    public static bool Enabled;     // set by Link.Start for version 2 and later

    public Func<float> Strength;    // your booster's exhaust, 0 to 1
    private TrainCar car;
    private object steam;           // typed object: no version 2 type in a field
    private float nextLook;

    private void Start() => car = GetComponentInParent<TrainCar>();

    private void Update()
    {
        if (!Enabled || car == null || Strength == null || Time.time < nextLook)
            return;
        nextLook = Time.time + 1f;
        Look();
    }

    [MethodImpl(MethodImplOptions.NoInlining)]
    private void Look()
    {
        var now = StackSources.EngineSteam(car);
        if (now == null || ReferenceEquals(now, steam))
            return;
        steam = now;
        now.Add("Booster exhaust", "BoosterExhaust",
            new Vector3(1.4f, 1.6f, -0.4f), new Vector3(1f, 0.3f, 0f), Strength);
    }
}
```

## Chimney dimensions: `RegisterGeometry` (version 3)

```csharp
public static void RegisterGeometry(string modId, Func<TrainCar, StackGeometry?> provider)
```

`StackGeometry` has three optional fields, in meters:

| Field | Meaning | Range |
| --- | --- | --- |
| `LipHeight` | Height of the stack's lip above the smoke emitter, along the stack's axis | 0 to 3 |
| `BoreRadius` | Inside radius of the chimney at the lip | 0.08 to 0.5 |
| `OutsideRadius` | Outside radius of the chimney at the lip | 0.1 to 0.5 |

```csharp
using System.Runtime.CompilerServices;
using RealisticStackEffects.Api;

internal static class Chimney
{
    [MethodImpl(MethodImplOptions.NoInlining)]
    public static StackGeometry? GeometryFor(TrainCar car)
    {
        if (car.carLivery == null || car.carLivery.id != "MyLoco")
            return null;
        return new StackGeometry { LipHeight = 0.44f, BoreRadius = 0.22f, OutsideRadius = 0.30f };
    }
}
```

- Each provider is asked once as each steam locomotive's plume is set up,
  in registration order. Answer `null` for engines that aren't yours.
- Each answer is cleaned first. A NaN or infinite value, a negative lip
  height, or a radius of zero or less is dropped. Other values are clamped
  to the ranges above, and the bore is cut to the outside radius if it is
  larger.
- The first answer with at least one dimension left wins. An answer of
  `null`, or one with nothing left, passes to the next provider.
- The winning answer overrides what the stack's mesh reads. Each field you
  leave null falls back on its own to the mesh's measurement, or to the
  plume's defaults (0.25 m bore radius, 0.32 m outside radius).
- Realistic Firing registers a provider too, for its built-in profiles and
  maker-fit `stack` sections. If both answer for one livery, the one
  registered first wins, which follows Unity Mod Manager's load order.
- An empty `modId` or a null `provider` throws `ArgumentException`.

## When your code throws

Another mod's fault never stops the plume. Each failure but `Tended`'s is
logged once in Unity Mod Manager's log.

| What throws | What happens |
| --- | --- |
| A fire provider (`Register`) | It is skipped from then on; engines read their stock firebox. |
| A source's `Read` | That engine's stack reads the stock firebox from then on. |
| A source's `Tended` | It reads as false that time. |
| A geometry provider (`RegisterGeometry`) | It is skipped from then on; the mesh or defaults apply. |
| A vent's `strength` | That vent reads as shut from then on. |

## What stays stable

- `ApiVersion` only grows. A version's members keep their signatures and
  meaning.
- `StackFireReading` and `StackGeometry` only grow: fields are added, never
  changed or removed. Set the fields you know; new ones start at zero or
  null.
- New steam kinds may be added. Treat `Add` returning false as "not drawn
  by this version."
- Only `RealisticStackEffects.Api` is the contract. Other public types in
  the assembly can change between any two releases.

The source is at
<https://github.com/Specter242/DVRealisticStackEffects>, in
`src/RealisticStackEffects/Api/StackSources.cs`.
