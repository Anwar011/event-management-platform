// EventHub Frontend Application
// Main application logic and initialization

class EventHubApp {
    constructor() {
        this.API_BASE = 'http://localhost:8080';
        this.currentUser = null;
        this.currentToken = null;

        this.init();
    }

    init() {
        this.loadUserFromStorage();
        this.updateNavigation();
        this.checkAPIStatus();
        this.showPage('home');

        // Handle form submissions
        document.getElementById('loginForm').addEventListener('submit', (e) => {
            e.preventDefault();
            this.handleLogin();
        });

        document.getElementById('registerForm').addEventListener('submit', (e) => {
            e.preventDefault();
            this.handleRegister();
        });

        // Load initial data
        if (this.currentToken) {
            this.loadDashboardData();
        }
    }

    loadUserFromStorage() {
        const token = localStorage.getItem('token');
        const user = localStorage.getItem('user');

        if (token && user) {
            this.currentToken = token;
            this.currentUser = JSON.parse(user);
        }
    }

    updateNavigation() {
        const isAuthenticated = !!this.currentToken;

        document.getElementById('login-nav').style.display = isAuthenticated ? 'none' : 'block';
        document.getElementById('logout-nav').style.display = isAuthenticated ? 'block' : 'none';
        document.getElementById('dashboard-nav').style.display = isAuthenticated ? 'block' : 'none';
        document.getElementById('reservations-nav').style.display = isAuthenticated ? 'block' : 'none';

        if (isAuthenticated && this.currentUser) {
            document.getElementById('user-info').textContent = `Welcome, ${this.currentUser.firstName || 'User'}`;
        }
    }

    showPage(pageId) {
        // Hide all pages
        const pages = document.querySelectorAll('.page');
        pages.forEach(page => page.style.display = 'none');

        // Show selected page
        document.getElementById(pageId + '-page').style.display = 'block';

        // Update URL hash
        window.location.hash = pageId;

        // Load page-specific data
        switch(pageId) {
            case 'events':
                loadEvents();
                break;
            case 'dashboard':
                if (this.currentToken) {
                    this.loadDashboardData();
                } else {
                    this.showPage('login');
                }
                break;
            case 'reservations':
                if (this.currentToken) {
                    loadUserReservations();
                } else {
                    this.showPage('login');
                }
                break;
        }
    }

    async handleLogin() {
        const email = document.getElementById('loginEmail').value;
        const password = document.getElementById('loginPassword').value;

        if (!email || !password) {
            this.showMessage('loginMessage', 'Please fill in all fields', 'danger');
            return;
        }

        this.setLoading('loginBtnText', 'loginSpinner', true);

        try {
            const response = await fetch(`${this.API_BASE}/v1/auth/login`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ email, password })
            });

            const data = await response.json();

            if (response.ok) {
                this.currentToken = data.token;
                this.currentUser = {
                    id: data.userId,
                    email: data.email,
                    firstName: data.firstName || 'User',
                    lastName: data.lastName || '',
                    roles: data.roles
                };

                localStorage.setItem('token', this.currentToken);
                localStorage.setItem('user', JSON.stringify(this.currentUser));

                this.updateNavigation();
                this.showMessage('loginMessage', 'Login successful!', 'success');
                setTimeout(() => this.showPage('dashboard'), 1000);
            } else {
                this.showMessage('loginMessage', data.message || 'Login failed', 'danger');
            }
        } catch (error) {
            this.showMessage('loginMessage', 'Network error. Please try again.', 'danger');
        }

        this.setLoading('loginBtnText', 'loginSpinner', false);
    }

    async handleRegister() {
        const firstName = document.getElementById('firstName').value;
        const lastName = document.getElementById('lastName').value;
        const email = document.getElementById('registerEmail').value;
        const password = document.getElementById('registerPassword').value;

        if (!firstName || !lastName || !email || !password) {
            this.showMessage('registerMessage', 'Please fill in all fields', 'danger');
            return;
        }

        this.setLoading('registerBtnText', 'registerSpinner', true);

        try {
            const response = await fetch(`${this.API_BASE}/v1/auth/register`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ email, password, firstName, lastName })
            });

            const data = await response.json();

            if (response.ok) {
                this.showMessage('registerMessage', 'Registration successful! Please login.', 'success');
                setTimeout(() => showAuthTab('login'), 2000);
            } else {
                this.showMessage('registerMessage', data.message || 'Registration failed', 'danger');
            }
        } catch (error) {
            this.showMessage('registerMessage', 'Network error. Please try again.', 'danger');
        }

        this.setLoading('registerBtnText', 'registerSpinner', false);
    }

    loadDashboardData() {
        if (this.currentUser) {
            document.getElementById('userProfile').innerHTML = `
                <div class="card">
                    <div class="card-body">
                        <h5 class="card-title">${this.currentUser.firstName} ${this.currentUser.lastName}</h5>
                        <p class="card-text">${this.currentUser.email}</p>
                        <span class="badge bg-primary">${this.currentUser.roles.join(', ')}</span>
                    </div>
                </div>
            `;
        }

        loadUserReservations();
    }

    logout() {
        this.currentToken = null;
        this.currentUser = null;
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        this.updateNavigation();
        this.showPage('home');
    }

    showMessage(elementId, message, type) {
        const element = document.getElementById(elementId);
        element.innerHTML = `<div class="alert alert-${type}">${message}</div>`;
        element.style.display = 'block';

        setTimeout(() => {
            element.style.display = 'none';
        }, 5000);
    }

    setLoading(textElementId, spinnerElementId, isLoading) {
        document.getElementById(textElementId).style.display = isLoading ? 'none' : 'inline';
        document.getElementById(spinnerElementId).style.display = isLoading ? 'inline-block' : 'none';
    }

    async checkAPIStatus() {
        try {
            const response = await fetch(`${this.API_BASE}/actuator/health`);
            if (response.ok) {
                document.getElementById('apiStatus').innerHTML = '<span class="text-success">✅ All Systems Operational</span>';
            } else {
                document.getElementById('apiStatus').innerHTML = '<span class="text-warning">⚠️ Partial Service</span>';
            }
        } catch (error) {
            document.getElementById('apiStatus').innerHTML = '<span class="text-danger">❌ API Unavailable</span>';
        }
    }
}

// Global functions for HTML onclick handlers
function showPage(pageId) {
    window.app.showPage(pageId);
}

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

function logout() {
    window.app.logout();
}

function toggleMenu() {
    const navbarNav = document.getElementById('navbarNav');
    navbarNav.classList.toggle('show');
}

// Initialize the application when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.app = new EventHubApp();

    // Handle browser back/forward buttons
    window.addEventListener('hashchange', () => {
        const hash = window.location.hash.substring(1);
        if (hash) {
            window.app.showPage(hash);
        }
    });
});


