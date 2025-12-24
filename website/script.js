document.addEventListener('DOMContentLoaded', () => {
    // Custom Cursor Glow Effect
    const cursorGlow = document.querySelector('.cursor-glow');

    if (cursorGlow) {
        document.addEventListener('mousemove', (e) => {
            cursorGlow.style.left = e.clientX + 'px';
            cursorGlow.style.top = e.clientY + 'px';
        });
    }

    // Smooth scroll for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            const href = this.getAttribute('href');
            // Skip if href is just "#" (not a valid selector)
            if (href && href.length > 1) {
                e.preventDefault();
                const target = document.querySelector(href);
                if (target) {
                    target.scrollIntoView({
                        behavior: 'smooth'
                    });
                }
            }
        });
    });

    // 3D Tilt Effect for Bento Cards
    const cards = document.querySelectorAll('.feature-card');

    cards.forEach(card => {
        card.addEventListener('mousemove', (e) => {
            const rect = card.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;

            const centerX = rect.width / 2;
            const centerY = rect.height / 2;

            const rotateX = ((y - centerY) / centerY) * -5; // Max 5deg tilt
            const rotateY = ((x - centerX) / centerX) * 5;

            // Update CSS variables for glow effect
            card.style.setProperty('--mouse-x', `${x}px`);
            card.style.setProperty('--mouse-y', `${y}px`);

            // Apply 3D transform
            card.style.transform = `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) scale(1.02)`;
        });

        card.addEventListener('mouseleave', () => {
            card.style.transform = 'perspective(1000px) rotateX(0) rotateY(0) scale(1)';
        });
    });

    // Staggered Text Reveal Animation
    const animatedElements = document.querySelectorAll('.hero-content > *');
    animatedElements.forEach((el, index) => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(30px)';
        setTimeout(() => {
            el.style.transition = 'all 0.8s cubic-bezier(0.2, 0.8, 0.2, 1)';
            el.style.opacity = '1';
            el.style.transform = 'translateY(0)';
        }, 100 * index);
    });

    // Parallax Effect on Scroll
    window.addEventListener('scroll', () => {
        const scrolled = window.pageYOffset;
        const screens = document.querySelectorAll('.app-screenshot');

        if (screens.length >= 2) {
            screens[0].style.transform = `translateY(${scrolled * -0.1}px) rotateY(-15deg) translateX(-60px) scale(0.95)`;
            screens[1].style.transform = `translateY(${scrolled * -0.05}px) rotateY(15deg) translateX(60px) scale(0.9)`;
        }
    });


    // FAQ Accordion
    const faqItems = document.querySelectorAll('.faq-item');

    faqItems.forEach(item => {
        item.querySelector('.faq-question').addEventListener('click', () => {
            // Close other items
            faqItems.forEach(otherItem => {
                if (otherItem !== item) otherItem.classList.remove('active');
            });
            // Toggle current
            item.classList.toggle('active');
        });
    });


    // Stats Counter Animation
    const stats = document.querySelectorAll('.stat-number');
    const statsOptions = { threshold: 0.5 };

    const statsObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const target = +entry.target.getAttribute('data-target');
                const duration = 2000; // 2 seconds
                const increment = target / (duration / 16); // 60fps

                let current = 0;
                const updateCount = () => {
                    current += increment;
                    if (current < target) {
                        entry.target.innerText = Math.ceil(current) + (target > 1000 ? '+' : '%');
                        // Simple suffix logic, customize as needed
                        if (target === 50) entry.target.innerText = Math.ceil(current); // Seconds
                        if (target === 100) entry.target.innerText = Math.ceil(current) + '%';
                        if (target === 10000) entry.target.innerText = Math.ceil(current / 1000) + 'k+';

                        requestAnimationFrame(updateCount);
                    } else {
                        if (target === 50) entry.target.innerText = target;
                        if (target === 100) entry.target.innerText = target + '%';
                        if (target === 10000) entry.target.innerText = '10k+';
                    }
                };
                updateCount();
                observer.unobserve(entry.target);
            }
        });
    }, statsOptions);

    stats.forEach(stat => {
        statsObserver.observe(stat);
    });
});
