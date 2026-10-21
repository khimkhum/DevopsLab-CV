import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://khimkum.xyz',
  output: 'static',
  trailingSlash: 'always',
  devToolbar: { enabled: false },
});
