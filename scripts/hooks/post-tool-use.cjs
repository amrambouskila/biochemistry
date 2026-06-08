const { emit, getToolFilePath, readHookPayload, toPosixPath } = require("./hookUtils.cjs");

const RULES = [
  {
    test: (p) => p.includes("/simulation/") || p.endsWith("/constants.py") || p.includes("/models/"),
    context:
      "You just edited a simulation or model file. Verify: (1) type annotations are complete, (2) array dtypes are explicit, (3) no Python for-loops over particles, (4) units are documented, (5) corresponding test exists in tests/. If you changed an engine interface (input/output/timestep/resolution), check that adjacent scale engines still match.",
  },
  {
    test: (p) => p.includes("/types/") || p.includes("/stores/") || p.includes("/context/"),
    context:
      "You just edited a type definition or state store. Verify: (1) the TypeScript interface matches the Pydantic model on the backend, (2) no Three.js objects stored in state, (3) Zustand store shape is consistent with the simulation data format.",
  },
];

async function main() {
  const payload = await readHookPayload();
  const f = toPosixPath(getToolFilePath(payload));
  if (!f) return;
  const m = RULES.find((r) => r.test(f));
  if (m) emit({ hookSpecificOutput: { hookEventName: "PostToolUse", additionalContext: m.context } });
}

main().catch((e) => {
  process.stderr.write(`[hook] post-tool-use failed: ${e.message}\n`);
  process.exitCode = 0;
});
