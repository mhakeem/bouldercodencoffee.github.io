/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{html,md,liquid,erb,serb,rb}",
    "./frontend/javascript/**/*.js",
  ],
  theme: {
    extend: {
      colors: {
        coffee: {
          light: "#D7CCC8",
          DEFAULT: "#795548",
          dark: "#5D4037",
        },
        code: {
          light: "#BBDEFB",
          DEFAULT: "#2196F3",
          dark: "#1976D2",
        },
      },
      fontFamily: {
        sans: ["Inter", "sans-serif"],
        display: ["Montserrat", "sans-serif"],
      },
    },
  },
  plugins: [require("@tailwindcss/typography")],
};
