import path from 'path';
import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';

export default defineConfig({
    plugins: [vue()],
    base: './',
    build: {
        rollupOptions: {
            output: {
                manualChunks: false,
                inlineDynamicImports: true,
                entryFileNames: '[name].js',
                assetFileNames: '[name].[ext]',
            },
        },
        outDir: path.join(__dirname, '../dui'),
        minify: true,
    },
});
