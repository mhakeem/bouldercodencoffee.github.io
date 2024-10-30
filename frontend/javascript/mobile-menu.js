// @ts-check

class MobileMenu {
  constructor() {
    this.menuButton = document.getElementById("menu-toggle");
    this.menu = document.getElementById("main-menu");
    this.isAnimating = false;
    this.animationDuration = 300;

    this.init();
  }

  init() {
    this.bindEvents();
  }

  bindEvents() {
    this.menuButton.addEventListener("click", () => this.toggleMenu());
    document.addEventListener("click", (event) =>
      this.handleClickOutside(event)
    );
  }

  toggleMenu() {
    if (this.isAnimating) return;

    this.isAnimating = true;
    this.menuButton.classList.toggle("menu-open");

    if (this.menu.classList.contains("hidden")) {
      this.openMenu();
    } else {
      this.closeMenu();
    }
  }

  openMenu() {
    this.menu.classList.remove("hidden");
    // Trigger reflow to ensure animation works
    this.menu.offsetHeight;
    this.menu.classList.add("show");

    setTimeout(() => {
      this.isAnimating = false;
    }, this.animationDuration);
  }

  closeMenu() {
    this.menu.classList.remove("show");

    setTimeout(() => {
      this.menu.classList.add("hidden");
      this.isAnimating = false;
    }, this.animationDuration);
  }

  /**
   * Handles clicks outside the menu to close it
   * @param {Event} event - The click event object
   */
  handleClickOutside(event) {
    const target = /** @type {Node} */ (event.target);
    if (
      !this.menu.classList.contains("hidden") &&
      !this.menu.contains(target) &&
      !this.menuButton.contains(target)
    ) {
      this.toggleMenu();
    }
  }
}

document.addEventListener("DOMContentLoaded", () => {
  const mobileMenu = new MobileMenu();
});

export default MobileMenu;
