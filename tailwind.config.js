/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{vue,js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        paper: "#F5F5F0",
        "paper-dark": "#EBEBE0",
        "ink-black": "#1a1a1a",
        "ink-subtle": "#4a4a4a",
        highlighter: "#FFFF00",
        "stamp-red": "#CC3333",
        "stamp-blue": "#0033CC",
        "brutalist-black": "#000000",
        "brutalist-white": "#FFFFFF",
        "brutalist-yellow": "#FACC15",
        "brutalist-green": "#4ADE80",
        "brutalist-red": "#F87171",
      },
      fontFamily: {
        mono: ["JetBrains Mono", "Space Mono", "monospace"],
        serif: ["Courier Prime", "Courier New", "serif"],
        sans: ["Inter", "sans-serif"],
      },
      borderWidth: {
        3: "3px",
      },
    },
  },
  plugins: [],
};
