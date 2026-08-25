import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// PRD section 3.1: fixed 1024x768 window; dev server must match Tauri config
export default defineConfig({
  plugins: [react()],
  clearScreen: false,
  server: {
    port: 1420,
    strictPort: true,
  },
  build: {
    outDir: "dist",
    target: "chrome105",
  },
});