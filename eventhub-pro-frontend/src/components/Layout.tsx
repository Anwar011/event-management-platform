import React from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'

interface LayoutProps {
  children: React.ReactNode
}

const Layout: React.FC<LayoutProps> = ({ children }) => {
  const { user, logout } = useAuth()
  const location = useLocation()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate('/')
  }

  const isActive = (path: string) => {
    return location.pathname === path ? 'bg-blue-700 text-white' : 'text-gray-300 hover:bg-blue-700 hover:text-white'
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Navigation */}
      <nav className="bg-blue-600 shadow-lg">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex items-center">
              <Link to="/" className="flex-shrink-0">
                <h1 className="text-2xl font-bold text-white">EventHub Pro</h1>
              </Link>
              
              <div className="hidden md:block">
                <div className="ml-10 flex items-baseline space-x-4">
                  <Link
                    to="/dashboard"
                    className={`px-3 py-2 rounded-md text-sm font-medium ${isActive('/dashboard')}`}
                  >
                    Dashboard
                  </Link>
                  <Link
                    to="/events"
                    className={`px-3 py-2 rounded-md text-sm font-medium ${isActive('/events')}`}
                  >
                    Events
                  </Link>
                  <Link
                    to="/create-event"
                    className={`px-3 py-2 rounded-md text-sm font-medium ${isActive('/create-event')}`}
                  >
                    Create Event
                  </Link>
                  <Link
                    to="/my-reservations"
                    className={`px-3 py-2 rounded-md text-sm font-medium ${isActive('/my-reservations')}`}
                  >
                    My Reservations
                  </Link>
                  <Link
                    to="/my-payments"
                    className={`px-3 py-2 rounded-md text-sm font-medium ${isActive('/my-payments')}`}
                  >
                    Payments
                  </Link>
                </div>
              </div>
            </div>

            <div className="flex items-center space-x-4">
              <span className="text-white text-sm">
                Welcome, {user?.firstName} {user?.lastName}
              </span>
              <button
                onClick={handleLogout}
                className="bg-blue-700 hover:bg-blue-800 text-white px-3 py-2 rounded-md text-sm font-medium"
              >
                Logout
              </button>
            </div>
          </div>
        </div>
      </nav>

      {/* Main content */}
      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="px-4 py-6 sm:px-0">
          {children}
        </div>
      </main>
    </div>
  )
}

export default Layout