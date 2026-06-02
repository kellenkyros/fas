import { defineConfig } from 'vite';
import { resolve } from 'path';
import fs from 'fs';

// Automatically find all .html files in the root directory
const root = resolve('./');
const input = Object.fromEntries(
  fs.readdirSync(root)
    .filter(file => file.endsWith('.html'))
    .map(file => [file.replace(/\.html$/, ''), resolve(root, file)])
);

export default defineConfig({
  build: {
    rollupOptions: {
      input,
    },
  },
});