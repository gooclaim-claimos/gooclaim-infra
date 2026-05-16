# @gooclaim/shared

Shared React + TypeScript primitives consumed by **gooclaim-console**, **gooclaim-copilot**, and **gooclaim-portal**. Keeps the three frontends from drifting on cross-cutting concerns.

## What lives here (v0.1.0)

| Surface | Path | Why shared |
|---|---|---|
| `useAuth` + `AuthProvider` | `src/hooks/useAuth.ts` | Single login/logout/introspect flow. Bug fixes propagate via one version bump. |
| `DataroomProvider` + `useDataroom` + `fetchWithDataroom` | `src/components/DataroomProvider.tsx` | 6-ID correlation header propagation (see backend memory `reference_dataroom_convention.md`). Every outbound fetch must carry these headers. |
| `tailwindPreset` | `src/lib/tailwind-preset.ts` | Brand colors + radius + font scale locked in one place. |
| `components.json` (shadcn) | `src/lib/components.json` | Same shadcn config across all three apps so `npx shadcn add ...` produces identical component code. |

Future additions (S6+): shared modals (confirm dialog, toast container), shared loading spinners, shared empty-state component, shared L6-policy-gate banner.

## Consumption (per FE app)

While the 3 FE apps live as separate git repos co-located here under `Frontend/`, distribution will go through one of two routes — locked in S6 when Console first consumes:

**Option A — GitHub Packages (preferred for prod)**
Publish `@gooclaim/shared` to GitHub Packages (private npm registry). Each FE app's `package.json`:
```json
{ "dependencies": { "@gooclaim/shared": "^0.1.0" } }
```
With `.npmrc` configured to pull from `https://npm.pkg.github.com` for `@gooclaim` scope.

**Option B — Local path (dev convenience)**
For local dev when iterating on the shared package:
```json
{ "dependencies": { "@gooclaim/shared": "file:../shared" } }
```
**Distribution choice deferred to S6** so we make it once when Console actually integrates, with real consumer feedback.

## Versioning

SemVer. Pin exact version in consumer apps (`"@gooclaim/shared": "0.1.0"`, not `^0.1.0`) per `PROPAGATION-PROTOCOL.md`. Bump signals a coordinated FE update.

- `0.1.0` — initial scaffold (S1)
- `0.2.0` (planned, S6) — adds shared confirm dialog + toast container after Console consumption pattern is validated

## Why not a Storybook here

Storybook adds tooling weight. The consuming FE apps each have their own component playgrounds. This package stays headless logic + Tailwind config + shadcn config only.

## Development

```bash
cd Frontend/shared
# install dev deps when needed
pnpm install
# typecheck
npx tsc --noEmit
```

There is no build step — consumers import directly from `src/`. The `exports` map in `package.json` exposes typed entrypoints.

## References

- Backend Dataroom convention: `~/.claude/.../memory/reference_dataroom_convention.md`
- Frontend audience map: `~/.claude/.../memory/reference_frontends_audience.md`
- S1 task: `tasks/Execution-Stage-Wise/02-stage-S1-foundation-day1.md` T11
- Console FE↔BE adapter pattern: `~/.claude/.../memory/feedback_frontend_backend_schema_adapter.md`
