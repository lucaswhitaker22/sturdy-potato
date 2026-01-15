/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{vue,js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        "brutalist-black": "#000000",
        "brutalist-white": "#FFFFFF",
        "brutalist-yellow": "#FACC15",
        "brutalist-green": "#4ADE80",
        "brutalist-red": "#F87171",
      },
      fontFamily: {
        mono: ["JetBrains Mono", "Space Mono", "monospace"],
      },
      borderWidth: {
        3: "3px",
      },
    },
  },
  plugins: [],
};
