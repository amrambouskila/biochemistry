/// <reference types="vitest" />
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5175,
  },
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./tests/setup.ts'],
    include: ['src/**/*.test.{ts,tsx}', 'tests/**/*.test.{ts,tsx}'],
    // Both reporters live here, not on the CLI: piping `--reporter=junit
    // --outputFile.junit=...` through `pnpm run <script> -- <args>` is mangled
    // on POSIX shells (pnpm 9 forwards a literal `--` and escapes `=` to `\=`),
    // so the junit reporter never activates and no report file is written.
    reporters: ['default', 'junit'],
    outputFile: { junit: 'junit-frontend.xml' },
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html'],
      include: ['src/**/*.{ts,tsx}'],
      exclude: ['src/**/*.test.{ts,tsx}', 'src/main.tsx'],
      thresholds: {
        lines: 100,
        functions: 100,
        branches: 100,
        statements: 100,
      },
    },
  },
});
