// @ts-check
import { defineConfig } from 'astro/config';
import { bundledLanguages } from 'shiki'
import rehypeMermaid from 'rehype-mermaid'

// https://astro.build/config
export default defineConfig({
  markdown: {
    shikiConfig: {
      themes: {
        light: 'aurora-x', // dark theme
        light: 'monokai', // light theme backup
        light: 'github-dark-high-contrast', // light theme
      },
      wrap: true,
    },
    syntaxHighlight: {
      type: 'shiki',
      excludeLangs: ['mermaid', 'math'],
    },
    rehypePlugins: [rehypeMermaid],
  },
});
