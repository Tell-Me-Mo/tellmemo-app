// Documentation JavaScript

document.addEventListener('DOMContentLoaded', () => {
    // Smooth scroll for anchor links
    const navLinks = document.querySelectorAll('.docs-nav-section a[href^="#"]');
    
    navLinks.forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            const targetId = link.getAttribute('href').substring(1);
            const targetElement = document.getElementById(targetId);
            
            if (targetElement) {
                const offset = 100; // Account for sticky header
                const elementPosition = targetElement.getBoundingClientRect().top;
                const offsetPosition = elementPosition + window.pageYOffset - offset;
                
                window.scrollTo({
                    top: offsetPosition,
                    behavior: 'smooth'
                });
                
                // Update active state
                navLinks.forEach(l => l.classList.remove('active'));
                link.classList.add('active');
            }
        });
    });
    
    // Highlight active section on scroll
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const id = entry.target.getAttribute('id');
                navLinks.forEach(link => {
                    link.classList.remove('active');
                    if (link.getAttribute('href') === `#${id}`) {
                        link.classList.add('active');
                    }
                });
            }
        });
    }, {
        rootMargin: '-100px 0px -80% 0px'
    });
    
    // Observe all article sections
    document.querySelectorAll('.docs-article').forEach(article => {
        observer.observe(article);
    });
    
    // Add copy button to code blocks
    document.querySelectorAll('.code-block').forEach(block => {
        const button = document.createElement('button');
        button.className = 'copy-code-btn';
        button.innerHTML = '📋 Copy';
        button.style.cssText = `
            position: absolute;
            top: 12px;
            right: 12px;
            padding: 6px 12px;
            background: var(--bg-secondary);
            border: 1px solid var(--border-color);
            border-radius: 4px;
            color: var(--text-secondary);
            font-size: 12px;
            cursor: pointer;
            transition: var(--transition);
        `;
        
        block.style.position = 'relative';
        block.appendChild(button);
        
        button.addEventListener('click', () => {
            const code = block.querySelector('code').textContent;
            navigator.clipboard.writeText(code).then(() => {
                button.innerHTML = '✅ Copied!';
                button.style.color = '#10b981';
                setTimeout(() => {
                    button.innerHTML = '📋 Copy';
                    button.style.color = 'var(--text-secondary)';
                }, 2000);
            });
        });
        
        button.addEventListener('mouseenter', () => {
            button.style.background = 'var(--bg-tertiary)';
            button.style.color = 'var(--text-primary)';
        });
        
        button.addEventListener('mouseleave', () => {
            if (button.innerHTML !== '✅ Copied!') {
                button.style.background = 'var(--bg-secondary)';
                button.style.color = 'var(--text-secondary)';
            }
        });
    });
});
