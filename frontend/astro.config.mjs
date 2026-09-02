import { defineConfig } from 'astro/config';
import node from '@astrojs/node';
import react from '@astrojs/react';

// https://astro.build/config
export default defineConfig({
  output: 'server',
  integrations: [react()],
  adapter: node({
    mode: 'standalone'
  }),
  server: {
    port: 4321,
    host: true
  },
  vite: {
    server: {
      allowedHosts: true,
      proxy: {
        '/api': {
          target: 'http://localhost:3000',
          changeOrigin: true,
          configure: (proxy) => {
            proxy.on('proxyRes', (proxyRes) => {
              console.log('[PROXY] Response from Rails, status:', proxyRes.statusCode);
              console.log('[PROXY] Response headers:', JSON.stringify(proxyRes.headers, null, 2));
              
              // Forward Set-Cookie headers from Rails to the browser
              const cookies = proxyRes.headers['set-cookie'];
              if (cookies) {
                console.log('[PROXY] Set-Cookie header found:', cookies);
                // Remove domain restriction so cookie works on localhost
                const modified = cookies.map(c => c.replace(/;\s*domain=[^;]+/i, ''));
                console.log('[PROXY] Modified Set-Cookie:', modified);
                proxyRes.headers['set-cookie'] = modified;
              } else {
                console.log('[PROXY] No Set-Cookie header in response');
              }
            });
          },
        },
        '/rails/active_storage': {
          target: 'http://localhost:3000',
          changeOrigin: true,
        },
      },
    },
  },
});
