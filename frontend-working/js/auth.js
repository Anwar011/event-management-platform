// Authentication related functions
// JWT token management and user session handling

class AuthManager {
    constructor() {
        this.API_BASE = 'http://localhost:8080';
        this.token = localStorage.getItem('token');
        this.user = JSON.parse(localStorage.getItem('user') || 'null');
    }

    async login(email, password) {
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
                this.token = data.token;
                this.user = {
                    id: data.userId,
                    email: data.email,
                    firstName: data.firstName || 'User',
                    lastName: data.lastName || '',
                    roles: data.roles
                };

                localStorage.setItem('token', this.token);
                localStorage.setItem('user', JSON.stringify(this.user));

                return { success: true, data: this.user };
            } else {
                return { success: false, error: data.message || 'Login failed' };
            }
        } catch (error) {
            return { success: false, error: 'Network error' };
        }
    }

    async register(userData) {
        try {
            const response = await fetch(`${this.API_BASE}/v1/auth/register`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(userData)
            });

            const data = await response.json();

            if (response.ok) {
                return { success: true, data: data };
            } else {
                return { success: false, error: data.message || 'Registration failed' };
            }
        } catch (error) {
            return { success: false, error: 'Network error' };
        }
    }

    logout() {
        this.token = null;
        this.user = null;
        localStorage.removeItem('token');
        localStorage.removeItem('user');
    }

    isAuthenticated() {
        return !!this.token;
    }

    getToken() {
        return this.token;
    }

    getUser() {
        return this.user;
    }

    hasRole(role) {
        return this.user && this.user.roles && this.user.roles.includes(role);
    }
}

// Create global auth manager instance
window.authManager = new AuthManager();


