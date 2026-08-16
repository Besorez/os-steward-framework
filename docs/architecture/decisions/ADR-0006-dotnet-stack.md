# ADR-0006 — C# / .NET Stack for Collectors and MCP Server

**Status:** Accepted (2026-08-15, owner decision)

## Context

Candidates: TypeScript (most mature MCP SDK, weak native Windows access),
Python (fast development, psutil/pywin32 cover V0.1, ctypes gymnastics
later), C#/.NET (native Windows APIs, compile-time schemas, heavier
ceremony). The framework's long-term needs — WMI, WinVerifyTrust,
performance counters, later ETW/EVTX/handles — are Windows-native.

## Decision

C# on .NET 10 LTS for the framework core, collectors, and MCP server
(`ModelContextProtocol` NuGet SDK, stdio transport). PowerShell only for
deterministic guard scripts (guaranteed present on Windows; hooks must not
require a build step). Collectors call Windows APIs directly — no parsing
of shelled-out console text (tool-output contract).

## Consequences

- Deep telemetry (ETW, handles, Authenticode) has a first-class path;
  `WinVerifyTrust` and `GlobalMemoryStatusEx` are already P/Invoked.
- Contributors need the .NET SDK; future plugin distribution can ship a
  self-contained single-file exe instead.
- `TreatWarningsAsErrors` keeps the API-obsolescence pressure visible
  (e.g. the documented SYSLIB0057 suppression in `SignatureInspector`).
