// @ts-check

class DarkMode {
  constructor() {
    this.toggleButton = document.getElementById("dark-mode-toggle");
    this.init();
  }

  init() {
    if (!this.toggleButton) return;
    this.toggleButton.addEventListener("click", () => this.toggle());
  }

  toggle() {
    const isDark = document.documentElement.classList.toggle("dark");
    localStorage.setItem("theme", isDark ? "dark" : "light");
  }
}

document.addEventListener("DOMContentLoaded", () => {
  new DarkMode();
});

export default DarkMode;
