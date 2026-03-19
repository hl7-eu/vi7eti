/*  Mobile menu toggle script  */

const menuToggle = document.getElementById('menuToggle');
const navLinks   = document.getElementById('navLinks');

    menuToggle.addEventListener('click', () => {
      navLinks.classList.toggle('active');
      menuToggle.classList.toggle('open');
    });

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.style.opacity = 1;
        entry.target.style.transform = "translateY(0)";
        entry.target.style.transition = "opacity 0.8s ease, transform 0.8s ease";
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.2 });

  document.querySelectorAll('[data-animate]').forEach(el => observer.observe(el));
