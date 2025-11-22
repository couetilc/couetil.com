// @ts-check
import { defineConfig } from 'astro/config';
import { bundledLanguages } from 'shiki'

// https://astro.build/config
export default defineConfig({
  markdown: {
    shikiConfig: {
      themes: {
        light: 'aurora-x', // dark theme
        light: 'monokai', // light theme backup
        light: 'andromeeda', // light theme (I like this, but no console highlighting)
        light: 'github-dark-high-contrast', // light theme
      },
      wrap: true,
    },
  },
});
