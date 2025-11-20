// Header scroll effect
const header = document.getElementById("site-header");

function handleScroll() {
  if (window.scrollY > 20) {
    header.classList.add("header-scrolled");
  } else {
    header.classList.remove("header-scrolled");
  }
}

window.addEventListener("scroll", handleScroll);
handleScroll();

// Smooth scroll with offset (for fixed header)
function scrollToSection(id) {
  const element = document.getElementById(id);
  if (!element) return;

  const headerOffset = header.offsetHeight || 80;
  const rect = element.getBoundingClientRect();
  const offset = rect.top + window.scrollY - headerOffset;

  window.scrollTo({
    top: offset,
    behavior: "smooth",
  });
}

// Attach listeners to nav buttons
function setupScrollButtons(selector) {
  document.querySelectorAll(selector).forEach((btn) => {
    btn.addEventListener("click", () => {
      const id = btn.getAttribute("data-scroll-target");
      if (id) {
        scrollToSection(id);
        closeMobileMenu();
      }
    });
  });
}

setupScrollButtons(".nav-link");
setupScrollButtons(".mobile-nav-link");

// Logo scroll to top
const logoTop = document.getElementById("logo-top");
if (logoTop) {
  logoTop.addEventListener("click", () => {
    window.scrollTo({ top: 0, behavior: "smooth" });
  });
}

// Mobile menu logic
const menuToggle = document.getElementById("menu-toggle");
const menuClose = document.getElementById("menu-close");
const mobileMenu = document.getElementById("mobile-menu");

function openMobileMenu() {
  mobileMenu.classList.add("open");
}

function closeMobileMenu() {
  mobileMenu.classList.remove("open");
}

if (menuToggle) {
  menuToggle.addEventListener("click", openMobileMenu);
}
if (menuClose) {
  menuClose.addEventListener("click", closeMobileMenu);
}

// Close mobile menu when clicking outside the drawer area
mobileMenu.addEventListener("click", (e) => {
  if (e.target === mobileMenu) {
    closeMobileMenu();
  }
});

// Footer year
const yearSpan = document.getElementById("year");
if (yearSpan) {
  yearSpan.textContent = new Date().getFullYear();
}
