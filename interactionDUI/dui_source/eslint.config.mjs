import prettier from 'eslint-plugin-prettier';
import js from '@eslint/js';
import eslintPluginVue from 'eslint-plugin-vue';
import ts from 'typescript-eslint';

export default [
    js.configs.recommended,
    ...ts.configs.recommended,
    ...eslintPluginVue.configs['flat/recommended'],
    {
        files: ['*.vue', '**/*.vue'],
        languageOptions: {
          parserOptions: {
            parser: '@typescript-eslint/parser'
          }
        },
        
        plugins: {
            prettier,
        },

        ignores: [
            'vite.config.dev.js',
            'vite.config.prod.js',
        ],
    },
];
