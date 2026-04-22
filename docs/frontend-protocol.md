# Frontend Protocol — Three.js / React Three Fiber

**Apply BEFORE writing any Phase-2 Three.js component.** This is the canonical, version-controlled copy of the rules. A mirror lives in `.claude/skills/frontend-protocol/SKILL.md` as an auto-applied agent skill, but `.claude/` is gitignored — this file is what travels with the repo and governs what merges into `main`.

Three.js memory leaks and draw-call bloat are the #1 cause of frontend degradation in WebGL apps. Every rule below exists because an unchecked default produces leaks, stutter, or unusable frame rates at the scales this project targets (Phase 2: 10k atoms; Phase 5: 100k cells; Phase 7: seamless zoom across scales).

---

## 1. Disposal (memory leaks)

Every `THREE.Geometry`/`BufferGeometry`, `Material`, and `Texture` you construct **must** have a corresponding `.dispose()` call in a cleanup function. GPU resources are not garbage collected — they leak until the tab closes.

```tsx
useEffect(() => {
  const geometry = new THREE.BufferGeometry();
  const material = new THREE.MeshStandardMaterial();
  return () => {
    geometry.dispose();
    material.dispose();
  };
}, []);
```

**Test for it**: rapidly switch the selected molecule/cell/organ 20 times in a row. Open Chrome DevTools → Memory → take a heap snapshot before and after. `WebGLBuffer`/`WebGLTexture` counts must be flat, not monotonically increasing.

## 2. Instancing (draw calls)

- **> 100 identical objects** → `THREE.InstancedMesh`. Never render 1,000 atoms as 1,000 `<mesh>` elements.
- **> 10,000 visible objects** → add `THREE.LOD` (switch to lower-poly geometry past a camera-distance threshold).
- **> 100,000 objects** → `THREE.Points` with custom shaders (point sprites), not individual meshes.

## 3. Geometry

- Use `THREE.BufferGeometry` + `THREE.BufferAttribute`. Never use the legacy `Geometry` class (it's removed in Three.js r125+; if you see it in example code, that code is stale).
- `useMemo` any geometry/material that doesn't change per frame. Recreating on every render is the most common perf bug in R3F.

## 4. State ownership — Three.js objects are NOT React state

- Simulation state (atom positions, concentrations, vital signs) → **Zustand** stores.
- UI state (panel open/closed, selected tab) → React component state.
- Three.js objects (meshes, geometries, materials, cameras, scenes) → **`useRef`**. Never in state, never in Zustand.

Putting a `THREE.Mesh` in React state triggers a re-render storm and doesn't give you anything useful — you already have the reference.

## 5. Frame updates

- Use `useFrame` from `@react-three/fiber` for per-frame logic.
- Never call `requestAnimationFrame` directly — R3F manages the frame loop, and a rogue RAF loop fights it.

## 6. Shaders

- Custom GLSL lives in `frontend/src/shaders/` as separate `.vert`/`.frag` files (import as raw strings via `?raw` or a Vite GLSL plugin).
- Never inline shader source as template literals in component files — they escape every code-review tool and have no syntax highlighting.
- Naming: `camelCase.vert`, `camelCase.frag`.

## 7. WebSocket payloads (simulation streams)

- Socket.IO client for connections.
- Decode MessagePack binary payloads in a **Web Worker**, not on the main thread. Main-thread decoding blocks rendering.
- Implement a frame buffer: accumulate 3–5 incoming frames and interpolate, so rendering stays smooth even if the backend emits at irregular intervals.

## 8. Declarative vs. imperative

Default to declarative R3F (`<mesh>`, `<instancedMesh>`, `<primitive object={...}/>`). Drop into imperative Three.js (`new THREE.Mesh(...)` inside a ref) only when R3F can't express what you need — usually for custom attribute updates on instanced meshes or manual buffer writes from decoded WebSocket frames.

---

## Before you ship any R3F component

1. Every `new THREE.*` has a matching `.dispose()` in a cleanup path.
2. Rapid switching test: no growth in `WebGLBuffer`/`WebGLTexture` heap counts.
3. Chrome DevTools Performance tab shows ≥ 55 fps sustained for the target object count of the current phase.
4. No Three.js objects stored in state or Zustand — grep the diff for `useState<THREE` or `create<.*THREE` and reject.
5. No inline shader strings — grep for `ShaderMaterial({[^})]*vertexShader:\s*\`` and reject.
