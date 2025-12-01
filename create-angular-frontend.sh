#!/bin/bash

# Event Management Platform - Angular Frontend Setup Script

echo "🎨 Creating Angular Frontend for Event Management Platform"
echo "========================================================"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check prerequisites
echo -e "${BLUE}🔍 Checking prerequisites...${NC}"

if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js not found. Please install Node.js 18+ first.${NC}"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm not found. Please install npm.${NC}"
    exit 1
fi

if ! command -v ng &> /dev/null; then
    echo -e "${RED}❌ Angular CLI not found. Please install with: npm install -g @angular/cli${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites found!${NC}"

# Create Angular application (non-interactive)
echo -e "${BLUE}🚀 Creating Angular application...${NC}"
echo "n" | ng new eventhub-frontend --routing=true --style=scss --skip-git=true --package-manager=npm --ssr=false

cd eventhub-frontend

# Install additional dependencies
echo -e "${BLUE}📦 Installing additional dependencies...${NC}"
npm install @angular/material @angular/cdk @angular/platform-browser-dynamic
npm install @angular/forms @angular/common @angular/router
npm install axios jwt-decode @angular/animations
npm install @angular/material-moment-adapter moment

# Create project structure
echo -e "${BLUE}🏗️  Creating project structure...${NC}"

# Create directories
mkdir -p src/app/{core,shared,features}/{components,services,guards,interceptors}
mkdir -p src/app/features/{auth,events,reservations,payments,dashboard}
mkdir -p src/app/shared/{models,interfaces,constants}

# Create core files
echo -e "${BLUE}📝 Creating core files...${NC}"

# Environment files created above

# Core services
cat > src/app/core/services/auth.service.ts << 'EOF'
import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { BehaviorSubject, Observable, tap } from 'rxjs';
import { Router } from '@angular/router';
import { environment } from '../../../environments/environment';

export interface User {
  id: number;
  email: string;
  firstName: string;
  lastName: string;
  roles: string[];
}

export interface AuthResponse {
  token: string;
  type: string;
  userId: number;
  email: string;
  roles: string[];
}

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private currentUserSubject = new BehaviorSubject<User | null>(null);
  public currentUser$ = this.currentUserSubject.asObservable();

  constructor(
    private http: HttpClient,
    private router: Router
  ) {
    this.loadUserFromStorage();
  }

  private loadUserFromStorage(): void {
    const token = localStorage.getItem('token');
    const user = localStorage.getItem('user');
    if (token && user) {
      this.currentUserSubject.next(JSON.parse(user));
    }
  }

  register(userData: { email: string; password: string; firstName: string; lastName: string }): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${environment.apiUrl}${environment.endpoints.auth}/register`, userData)
      .pipe(
        tap(response => this.handleAuthResponse(response))
      );
  }

  login(credentials: { email: string; password: string }): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${environment.apiUrl}${environment.endpoints.auth}/login`, credentials)
      .pipe(
        tap(response => this.handleAuthResponse(response))
      );
  }

  private handleAuthResponse(response: AuthResponse): void {
    localStorage.setItem('token', response.token);
    const user: User = {
      id: response.userId,
      email: response.email,
      firstName: response.firstName || '',
      lastName: response.lastName || '',
      roles: response.roles
    };
    localStorage.setItem('user', JSON.stringify(user));
    this.currentUserSubject.next(user);
  }

  logout(): void {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    this.currentUserSubject.next(null);
    this.router.navigate(['/auth/login']);
  }

  getToken(): string | null {
    return localStorage.getItem('token');
  }

  isAuthenticated(): boolean {
    return !!this.getToken();
  }

  getCurrentUser(): User | null {
    return this.currentUserSubject.value;
  }

  hasRole(role: string): boolean {
    const user = this.getCurrentUser();
    return user ? user.roles.includes(role) : false;
  }
}
EOF

cat > src/app/core/services/api.service.ts << 'EOF'
import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { AuthService } from './auth.service';

@Injectable({
  providedIn: 'root'
})
export class ApiService {

  constructor(
    private http: HttpClient,
    private authService: AuthService
  ) { }

  private getHeaders(includeAuth: boolean = true): HttpHeaders {
    let headers = new HttpHeaders({
      'Content-Type': 'application/json'
    });

    if (includeAuth) {
      const token = this.authService.getToken();
      if (token) {
        headers = headers.set('Authorization', `Bearer ${token}`);
      }
    }

    return headers;
  }

  get<T>(endpoint: string, params?: any): Observable<T> {
    const httpParams = params ? new HttpParams({ fromObject: params }) : new HttpParams();
    return this.http.get<T>(`${environment.apiUrl}${endpoint}`, {
      headers: this.getHeaders(),
      params: httpParams
    });
  }

  post<T>(endpoint: string, data: any, includeAuth: boolean = true): Observable<T> {
    return this.http.post<T>(`${environment.apiUrl}${endpoint}`, data, {
      headers: this.getHeaders(includeAuth)
    });
  }

  put<T>(endpoint: string, data: any): Observable<T> {
    return this.http.put<T>(`${environment.apiUrl}${endpoint}`, data, {
      headers: this.getHeaders()
    });
  }

  delete<T>(endpoint: string): Observable<T> {
    return this.http.delete<T>(`${environment.apiUrl}${endpoint}`, {
      headers: this.getHeaders()
    });
  }
}
EOF

# Generate components
echo -e "${BLUE}🧩 Generating Angular components...${NC}"

ng generate component features/auth/login --skip-tests
ng generate component features/auth/register --skip-tests
ng generate component features/events/event-list --skip-tests
ng generate component features/events/event-detail --skip-tests
ng generate component features/reservations/reservation-list --skip-tests
ng generate component features/dashboard/user-dashboard --skip-tests
ng generate component shared/components/navbar --skip-tests
ng generate component shared/components/footer --skip-tests
ng generate guard core/guards/auth --skip-tests
ng generate interceptor core/interceptors/auth --skip-tests

# Update app.component.html
cat > src/app/app.component.html << 'EOF'
<app-navbar></app-navbar>
<main class="main-content">
  <router-outlet></router-outlet>
</main>
<app-footer></app-footer>
EOF

# Update app.component.scss
cat > src/app/app.component.scss << 'EOF'
.main-content {
  min-height: calc(100vh - 160px);
  background-color: #f8f9fa;
}

:host {
  display: block;
  min-height: 100vh;
}
EOF

# Create environment files
mkdir -p src/environments

# Update app.module.ts
cat > src/app/app.module.ts << 'EOF'
import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { HttpClientModule, HTTP_INTERCEPTORS } from '@angular/common/http';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';

import { MatToolbarModule } from '@angular/material/toolbar';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSnackBarModule } from '@angular/material/snack-bar';
import { MatTabsModule } from '@angular/material/tabs';
import { MatListModule } from '@angular/material/list';
import { MatChipsModule } from '@angular/material/chips';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { NavbarComponent } from './shared/components/navbar/navbar.component';
import { FooterComponent } from './shared/components/footer/footer.component';
import { LoginComponent } from './features/auth/login/login.component';
import { RegisterComponent } from './features/auth/register/register.component';
import { EventListComponent } from './features/events/event-list/event-list.component';
import { EventDetailComponent } from './features/events/event-detail/event-detail.component';
import { ReservationListComponent } from './features/reservations/reservation-list/reservation-list.component';
import { UserDashboardComponent } from './features/dashboard/user-dashboard/user-dashboard.component';

import { AuthGuard } from './core/guards/auth.guard';
import { AuthInterceptor } from './core/interceptors/auth.interceptor';

@NgModule({
  declarations: [
    AppComponent,
    NavbarComponent,
    FooterComponent,
    LoginComponent,
    RegisterComponent,
    EventListComponent,
    EventDetailComponent,
    ReservationListComponent,
    UserDashboardComponent
  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    BrowserAnimationsModule,
    HttpClientModule,
    ReactiveFormsModule,
    FormsModule,
    MatToolbarModule,
    MatButtonModule,
    MatIconModule,
    MatCardModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatDatepickerModule,
    MatNativeDateModule,
    MatProgressSpinnerModule,
    MatSnackBarModule,
    MatTabsModule,
    MatListModule,
    MatChipsModule
  ],
  providers: [
    AuthGuard,
    {
      provide: HTTP_INTERCEPTORS,
      useClass: AuthInterceptor,
      multi: true
    }
  ],
  bootstrap: [AppComponent]
})
export class AppModule { }
EOF

# Update app-routing.module.ts
cat > src/app/app-routing.module.ts << 'EOF'
import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { AuthGuard } from './core/guards/auth.guard';

const routes: Routes = [
  { path: '', redirectTo: '/events', pathMatch: 'full' },
  { path: 'auth/login', component: LoginComponent },
  { path: 'auth/register', component: RegisterComponent },
  { path: 'events', component: EventListComponent },
  { path: 'events/:id', component: EventDetailComponent },
  { path: 'dashboard', component: UserDashboardComponent, canActivate: [AuthGuard] },
  { path: 'reservations', component: ReservationListComponent, canActivate: [AuthGuard] },
  { path: '**', redirectTo: '/events' }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
EOF

# Create component files
echo -e "${BLUE}📝 Creating component implementations...${NC}"

# Navbar Component
cat > src/app/shared/components/navbar/navbar.component.html << 'EOF'
<mat-toolbar color="primary" class="navbar">
  <div class="nav-brand">
    <mat-icon>event</mat-icon>
    <span>EventHub</span>
  </div>

  <div class="nav-links">
    <a mat-button routerLink="/events" routerLinkActive="active">Events</a>
    <a mat-button routerLink="/dashboard" routerLinkActive="active" *ngIf="isAuthenticated">Dashboard</a>
    <a mat-button routerLink="/reservations" routerLinkActive="active" *ngIf="isAuthenticated">Reservations</a>
    <a mat-button (click)="logout()" *ngIf="isAuthenticated">Logout</a>
    <a mat-button routerLink="/auth/login" *ngIf="!isAuthenticated">Login</a>
  </div>

  <div class="user-info" *ngIf="isAuthenticated">
    <span>Welcome, {{ currentUser?.firstName }}</span>
  </div>
</mat-toolbar>
EOF

cat > src/app/shared/components/navbar/navbar.component.scss << 'EOF'
.navbar {
  position: sticky;
  top: 0;
  z-index: 1000;

  .nav-brand {
    display: flex;
    align-items: center;
    gap: 8px;
    font-size: 1.5rem;
    font-weight: 600;

    mat-icon {
      color: #fff;
    }
  }

  .nav-links {
    display: flex;
    gap: 16px;
    margin-left: auto;

    a {
      color: rgba(255, 255, 255, 0.9);
      transition: color 0.3s ease;

      &:hover {
        color: #fff;
      }

      &.active {
        color: #fff;
        font-weight: 600;
      }
    }
  }

  .user-info {
    margin-left: 16px;
    color: rgba(255, 255, 255, 0.9);
  }
}

@media (max-width: 768px) {
  .nav-links {
    display: none;
  }
}
EOF

cat > src/app/shared/components/navbar/navbar.component.ts << 'EOF'
import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService, User } from '../../core/services/auth.service';

@Component({
  selector: 'app-navbar',
  templateUrl: './navbar.component.html',
  styleUrls: ['./navbar.component.scss']
})
export class NavbarComponent implements OnInit {
  isAuthenticated = false;
  currentUser: User | null = null;

  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.authService.currentUser$.subscribe(user => {
      this.isAuthenticated = this.authService.isAuthenticated();
      this.currentUser = user;
    });
  }

  logout(): void {
    this.authService.logout();
  }
}
EOF

# Login Component
cat > src/app/features/auth/login/login.component.html << 'EOF'
<div class="auth-container">
  <mat-card class="auth-card">
    <mat-card-header>
      <mat-card-title>Welcome Back</mat-card-title>
      <mat-card-subtitle>Sign in to your EventHub account</mat-card-subtitle>
    </mat-card-header>

    <mat-card-content>
      <form [formGroup]="loginForm" (ngSubmit)="onSubmit()" class="auth-form">
        <mat-form-field appearance="outline" class="full-width">
          <mat-label>Email</mat-label>
          <input matInput type="email" formControlName="email" required>
          <mat-error *ngIf="loginForm.get('email')?.invalid && loginForm.get('email')?.touched">
            Please enter a valid email address
          </mat-error>
        </mat-form-field>

        <mat-form-field appearance="outline" class="full-width">
          <mat-label>Password</mat-label>
          <input matInput type="password" formControlName="password" required>
          <mat-error *ngIf="loginForm.get('password')?.invalid && loginForm.get('password')?.touched">
            Password is required
          </mat-error>
        </mat-form-field>

        <button mat-raised-button color="primary" type="submit"
                class="full-width" [disabled]="loginForm.invalid || isLoading">
          <mat-spinner diameter="20" *ngIf="isLoading"></mat-spinner>
          {{ isLoading ? 'Signing In...' : 'Sign In' }}
        </button>
      </form>
    </mat-card-content>

    <mat-card-actions align="center">
      <p>Don't have an account?
        <a mat-button color="accent" routerLink="/auth/register">Sign Up</a>
      </p>
    </mat-card-actions>
  </mat-card>

  <mat-card *ngIf="errorMessage" class="error-card">
    <mat-card-content>
      <mat-icon color="warn">error</mat-icon>
      <span>{{ errorMessage }}</span>
    </mat-card-content>
  </mat-card>
</div>
EOF

cat > src/app/features/auth/login/login.component.scss << 'EOF'
.auth-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 70vh;
  padding: 20px;
}

.auth-card {
  max-width: 400px;
  width: 100%;

  .auth-form {
    display: flex;
    flex-direction: column;
    gap: 16px;
  }

  .full-width {
    width: 100%;
  }
}

.error-card {
  max-width: 400px;
  width: 100%;
  margin-top: 16px;

  mat-card-content {
    display: flex;
    align-items: center;
    gap: 8px;
    color: #f44336;
  }
}
EOF

cat > src/app/features/auth/login/login.component.ts << 'EOF'
import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { MatSnackBar } from '@angular/material/snack-bar';
import { AuthService } from '../../../core/services/auth.service';

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.scss']
})
export class LoginComponent implements OnInit {
  loginForm: FormGroup;
  isLoading = false;
  errorMessage = '';

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router,
    private snackBar: MatSnackBar
  ) {
    this.loginForm = this.fb.group({
      email: ['', [Validators.required, Validators.email]],
      password: ['', Validators.required]
    });
  }

  ngOnInit(): void {
    if (this.authService.isAuthenticated()) {
      this.router.navigate(['/dashboard']);
    }
  }

  onSubmit(): void {
    if (this.loginForm.valid) {
      this.isLoading = true;
      this.errorMessage = '';

      this.authService.login(this.loginForm.value).subscribe({
        next: (response) => {
          this.isLoading = false;
          this.snackBar.open('Login successful!', 'Close', { duration: 3000 });
          this.router.navigate(['/dashboard']);
        },
        error: (error) => {
          this.isLoading = false;
          this.errorMessage = error.error?.message || 'Login failed. Please try again.';
          this.snackBar.open(this.errorMessage, 'Close', { duration: 5000 });
        }
      });
    }
  }
}
EOF

echo -e "${GREEN}✅ Angular frontend created successfully!${NC}"
echo ""
echo -e "${BLUE}🎯 Next steps:${NC}"
echo "1. cd eventhub-frontend"
echo "2. ng serve --open"
echo "3. Frontend will be available at http://localhost:4200"
echo ""
echo -e "${YELLOW}📋 Available commands:${NC}"
echo "• ng serve          - Start development server"
echo "• ng build          - Build for production"
echo "• ng generate       - Generate components/services"
echo ""
echo -e "${GREEN}🚀 Ready to start developing!${NC}"
