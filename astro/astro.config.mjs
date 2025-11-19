// @ts-check
import { defineConfig } from 'astro/config';

// https://astro.build/config
export default defineConfig({
  markdown: {
    shikiConfig: {
      themes: {
        light: 'aurora-x', // dark theme
        light: 'monokai', // light theme backup
        light: 'andromeeda', // light theme
      },
      wrap: true,
    },
  },
});
