import '@testing-library/jest-dom/vitest';
import { cleanup } from '@testing-library/react';
import { afterEach } from 'vitest';

// Vitest does NOT auto-cleanup like Jest — DOM state leaks between tests
// without this hook. See CLAUDE.md §7 "Known testing pitfalls".
afterEach(() => {
  cleanup();
});
