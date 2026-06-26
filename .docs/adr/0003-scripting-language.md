# ADR-0003: Scripting language

- **Status:** Accepted
- **Date:** 2026-06-26
- **Deciders:** Lars (owner), Claude

## Context

ADR-0001 commits to Godot 4 with a **web/WASM export** as the distribution target,
and spec X-7 requires the game to run **fully offline after first load**. Godot
supports GDScript, C#, and Rust (via the gdext GDExtension binding). The workload
is light — a single-dog timing game — so raw language performance is not a factor;
the binding constraint is the web-export story.

## Decision

**Use GDScript.** It is Godot's first-class language with **zero web-export
friction** (interpreted by the engine — web "just works"), which is the only option
that cleanly satisfies the web + offline requirement.

Rust (gdext) and C# were rejected for this project:

- **Rust (gdext):** web/WASM export is **experimental and actively breaking on Rust
  nightly** (as of June 2026: removed `-Zemscripten-wasm-eh`; workarounds are pinning
  old nightly or `-Cpanic=immediate-abort`, which crashes on any error), needs an
  elaborate flag setup kept in sync with Godot, and can't load multiple Rust
  GDExtensions on WASM. A real toolchain-maintenance risk for **no functional gain**
  on this workload.
- **C#:** Godot's .NET web export carries its own caveats/limitations — more risk
  than GDScript for no benefit here.

## Consequences

- **Good:** simplest, most reliable web/offline path; no extra build toolchain; fast
  enough for the timing loop; easiest Godot tutorials/community fit.
- **Cost:** GDScript is dynamically typed and weaker than C#/Rust for very large
  codebases — acceptable at this scope; use **typed GDScript** (type hints) for
  safety. Revisit only if a genuine perf hotspot appears (could isolate it behind a
  GDExtension later without changing this decision wholesale).
