import path from "path"
import react from "@vitejs/plugin-react"
//import eslint from 'vite-plugin-eslint';
import { defineConfig } from "vite"
import tailwindcss from '@tailwindcss/vite'
// @ts-expect-error vite-plugin-eslint does not have TypeScript type definitions
import eslint from "vite-plugin-eslint"

 
export default defineConfig({
  plugins: [react(),eslint(), tailwindcss()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
})
