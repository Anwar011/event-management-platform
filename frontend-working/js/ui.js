// UI management functions
// Handle page navigation, menus, and general UI interactions

function toggleMenu() {
    const navbarNav = document.getElementById('navbarNav');
    navbarNav.classList.toggle('show');
}

// Page navigation
function showPage(pageId) {
    if (window.app) {
        window.app.showPage(pageId);
    }
}

// Auth tab switching
function showAuthTab(tab) {
    const loginForm = document.getElementById('loginForm');
    const registerForm = document.getElementById('registerForm');
    const loginTab = document.querySelector('.tab-btn:nth-child(1)');
    const registerTab = document.querySelector('.tab-btn:nth-child(2)');

    if (tab === 'login') {
        loginForm.style.display = 'block';
        registerForm.style.display = 'none';
        loginTab.classList.add('active');
        registerTab.classList.remove('active');
    } else {
        loginForm.style.display = 'none';
        registerForm.style.display = 'block';
        loginTab.classList.remove('active');
        registerTab.classList.add('active');
    }
}

// Logout function
function logout() {
    if (window.app) {
        window.app.logout();
    }
}

// Utility functions for showing/hiding elements
function showElement(elementId) {
    const element = document.getElementById(elementId);
    if (element) {
        element.style.display = 'block';
    }
}

function hideElement(elementId) {
    const element = document.getElementById(elementId);
    if (element) {
        element.style.display = 'none';
    }
}

// Loading spinner functions
function showLoading(elementId, message = 'Loading...') {
    const element = document.getElementById(elementId);
    if (element) {
        element.innerHTML = `
            <div class="loading">
                <div class="spinner"></div>
                <p>${message}</p>
            </div>
        `;
    }
}

function hideLoading(elementId) {
    const element = document.getElementById(elementId);
    if (element) {
        element.innerHTML = '';
    }
}

// Message display functions
function showSuccessMessage(elementId, message) {
    const element = document.getElementById(elementId);
    if (element) {
        element.innerHTML = `<div class="alert alert-success">${message}</div>`;
        element.style.display = 'block';
        setTimeout(() => {
            element.style.display = 'none';
        }, 5000);
    }
}

function showErrorMessage(elementId, message) {
    const element = document.getElementById(elementId);
    if (element) {
        element.innerHTML = `<div class="alert alert-danger">${message}</div>`;
        element.style.display = 'block';
        setTimeout(() => {
            element.style.display = 'none';
        }, 5000);
    }
}

// Modal functions
function openModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.style.display = 'block';
        document.body.style.overflow = 'hidden';
    }
}

function closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.style.display = 'none';
        document.body.style.overflow = 'auto';
    }
}

// Event delegation for dynamic elements
document.addEventListener('click', function(event) {
    // Handle navbar collapse on mobile
    if (!event.target.closest('#navbarNav') && !event.target.closest('.navbar-toggler')) {
        const navbarNav = document.getElementById('navbarNav');
        if (navbarNav && navbarNav.classList.contains('show')) {
            navbarNav.classList.remove('show');
        }
    }
});

// Handle window resize for responsive design
window.addEventListener('resize', function() {
    const navbarNav = document.getElementById('navbarNav');
    if (window.innerWidth > 768 && navbarNav) {
        navbarNav.classList.remove('show');
    }
});

// Handle browser back/forward buttons
window.addEventListener('hashchange', function() {
    const hash = window.location.hash.substring(1);
    if (hash && window.app) {
        window.app.showPage(hash);
    }
});

// Keyboard shortcuts
document.addEventListener('keydown', function(event) {
    // ESC key closes modals
    if (event.key === 'Escape') {
        const modals = document.querySelectorAll('.modal');
        modals.forEach(modal => {
            if (modal.style.display === 'block') {
                modal.style.display = 'none';
                document.body.style.overflow = 'auto';
            }
        });
    }

    // Ctrl/Cmd + K for search (when on events page)
    if ((event.ctrlKey || event.metaKey) && event.key === 'k') {
        event.preventDefault();
        if (window.location.hash === '#events') {
            document.getElementById('searchInput').focus();
        }
    }
});

// Initialize UI when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    console.log('🎨 EventHub Frontend Loaded');

    // Initialize tooltips if Bootstrap is available
    if (typeof bootstrap !== 'undefined' && bootstrap.Tooltip) {
        const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
        tooltipTriggerList.map(function (tooltipTriggerEl) {
            return new bootstrap.Tooltip(tooltipTriggerEl);
        });
    }

    // Handle initial page based on URL hash
    const hash = window.location.hash.substring(1);
    if (hash && window.app) {
        setTimeout(() => {
            window.app.showPage(hash);
        }, 100);
    }
});


