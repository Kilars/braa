/// <reference types="vite/client" />

// Pulls in Vite's ambient types so `import.meta.env` (e.g. `import.meta.env.DEV`)
// is typed. tsconfig sets `"types": []`, which disables auto-loading of @types
// packages — this explicit triple-slash reference re-enables Vite's client types
// without re-enabling every other @types package.
