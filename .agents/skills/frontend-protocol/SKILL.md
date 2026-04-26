---
name: frontend-protocol
description: Proactively applied when creating or modifying frontend Three.js/React components
---

# Frontend Protocol

When working on any frontend code, follow these rules from AGENTS.md. Three.js memory leaks and performance issues are the #1 cause of frontend degradation.

## React Three Fiber rules

- Use declarative R3F components over imperative Three.js code
- Use `useFrame` for per-frame updates, never `requestAnimationFrame`
- Use `useMemo` for geometries, materials, and textures — never recreate on every render
- Use `useRef` for mutable Three.js objects — never store them in React state or Zustand stores
- Dispose of geometries, materials, and textures in cleanup functions:
  ```tsx
  useEffect(() => {
    return () => {
      geometry.dispose();
      material.dispose();
    };
  }, []);
  ```

## Performance rules

- More than 100 identical objects → use `THREE.InstancedMesh`
- More than 10,000 visible objects → implement LOD (`THREE.LOD`)
- More than 100,000 objects → use `THREE.Points` with custom shaders
- Custom shaders go in `frontend/src/shaders/` as separate `.vert`/`.frag` files, never inline strings
- Use `THREE.BufferGeometry` with `THREE.BufferAttribute` for custom geometry

## State management rules

- Simulation state (atom positions, concentrations, vital signs) → Zustand stores
- UI-only state (panel open/closed, selected tab) → React component state
- Three.js objects (meshes, geometries, materials) → `useRef`, NEVER in state or stores

## WebSocket rules

- Use Socket.IO client for connections
- Decode binary payloads (MessagePack) in a Web Worker — never on the main thread
- Implement a frame buffer: accumulate 3-5 incoming frames and interpolate between them for smooth rendering

## TypeScript rules

- `const` by default, `let` only for reassignment, never `var`
- Prefer `interface` over `type` for object shapes
- No `any` — use proper types
- Components: `PascalCase.tsx`, hooks: `useCamelCase.ts`, stores: `camelCaseStore.ts`

## Before finishing

- Check for memory leaks: every `new THREE.Geometry/Material/Texture` must have a corresponding `.dispose()` in a cleanup function
- Test rapid switching (selecting many elements/molecules quickly) — geometries from the previous selection must be disposed
- Verify rendering at 60fps in Chrome DevTools Performance tab