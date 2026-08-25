/** @type {import('tailwindcss').Config} */
// PRD section 3.4 — radius + spacing scale mapped to Tailwind tokens.
// All colors come from CSS variables in src/styles/tokens.css (section 3.2).
export default {
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        window: "var(--bg-window)",
        titlebar: "var(--bg-titlebar)",
        card: "var(--bg-card)",
        primary: "var(--text-primary)",
        secondary: "var(--text-secondary)",
        divider: "var(--divider)",
        accent: "var(--accent)",
        safe: "var(--safe)",
        review: "var(--review)",
        locked: "var(--locked)",
      },
      borderRadius: {
        btn: "8px", // buttons, nav pill
        row: "10px", // cards, file rows
        win: "12px", // window, panel
        block: "6px", // treemap blocks
        bar: "3px", // progress bar
      },
      spacing: {
        // 4px base grid (PRD section 3.4)
        "4": "4px",
        "8": "8px",
        "12": "12px",
        "16": "16px",
        "20": "20px",
        "24": "24px",
        "32": "32px",
      },
      fontFamily: {
        sans: ["Inter", "SF Pro Text", "Segoe UI", "system-ui", "sans-serif"],
        mono: ["ui-monospace", "Cascadia Mono", "Consolas", "monospace"],
      },
    },
  },
  plugins: [],
};