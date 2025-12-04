import React from 'react'
import { Link } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { useAuth } from '../contexts/AuthContext'
import apiService from '../services/api'

import LoadingSpinner from '../components/LoadingSpinner'

const DashboardPage: React.FC = () => {
  const { user } = useAuth()

  const { data: reservations, isLoading: reservationsLoading } = useQuery({
    queryKey: ['user-reservations', user?.id],
    queryFn: () => apiService.getUserReservations(user!.id),
    enabled: !!user,
  })

  const { data: paymentsData, isLoading: paymentsLoading } = useQuery({
    queryKey: ['user-payments', user?.id],
    queryFn: () => apiService.getUserPayments(user!.id),
    enabled: !!user,
  })

  const { data: eventsData, isLoading: eventsLoading } = useQuery({
    queryKey: ['recent-events'],
    queryFn: () => apiService.getEvents(0, 6),
  })

  const recentEvents = eventsData?.content?.filter(event => event.status === 'PUBLISHED')?.slice(0, 3) || []
  const recentReservations = reservations?.slice(0, 3) || []
  const totalSpent = paymentsData?.reduce((total, payment) => total + payment.amount, 0) || 0

  if (reservationsLoading && paymentsLoading && eventsLoading) {
    return <LoadingSpinner />
  }

  return (
    <div>
      {/* Welcome Section */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">
          Welcome back, {user?.firstName}!
        </h1>
        <p className="text-gray-600">
          Here's what's happening with your events and bookings.
        </p>
      </div>

      {/* Stats Cards */}
      <div className="grid md:grid-cols-4 gap-6 mb-8">
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Total Reservations</p>
              <p className="text-3xl font-bold text-blue-600">{reservations?.length || 0}</p>
            </div>
            <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
              <svg className="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
              </svg>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Total Spent</p>
              <p className="text-3xl font-bold text-green-600">${totalSpent.toFixed(2)}</p>
            </div>
            <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
              <svg className="w-6 h-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1" />
              </svg>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Confirmed Bookings</p>
              <p className="text-3xl font-bold text-purple-600">
                {reservations?.filter(r => r.status === 'CONFIRMED').length || 0}
              </p>
            </div>
            <div className="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center">
              <svg className="w-6 h-6 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Events Available</p>
              <p className="text-3xl font-bold text-orange-600">{eventsData?.totalElements || 0}</p>
            </div>
            <div className="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center">
              <svg className="w-6 h-6 text-orange-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
            </div>
          </div>
        </div>
      </div>

      <div className="grid lg:grid-cols-2 gap-8">
        {/* Recent Reservations */}
        <div className="card">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-semibold">Recent Reservations</h2>
            <Link to="/my-reservations" className="text-blue-600 hover:text-blue-700 text-sm font-medium">
              View all →
            </Link>
          </div>

          {recentReservations.length === 0 ? (
            <div className="text-center py-8">
              <p className="text-gray-500 mb-4">No reservations yet</p>
              <Link to="/events" className="btn btn-primary">
                Browse Events
              </Link>
            </div>
          ) : (
            <div className="space-y-4">
              {recentReservations.map((reservation) => (
                <div key={reservation.id} className="border border-gray-200 rounded-lg p-4">
                  <div className="flex justify-between items-start">
                    <div>
                      <p className="font-medium">Reservation {reservation.reservationId}</p>
                      <p className="text-sm text-gray-600">
                        {reservation.quantity} ticket(s) - ${reservation.totalPrice}
                      </p>
                      <span className={`inline-block px-2 py-1 text-xs rounded-full mt-2 ${
                        reservation.status === 'CONFIRMED' 
                          ? 'bg-green-100 text-green-800'
                          : 'bg-yellow-100 text-yellow-800'
                      }`}>
                        {reservation.status}
                      </span>
                    </div>
                    <p className="text-sm text-gray-500">
                      {new Date(reservation.createdAt).toLocaleDateString()}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Recent Events */}
        <div className="card">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-semibold">Featured Events</h2>
            <Link to="/events" className="text-blue-600 hover:text-blue-700 text-sm font-medium">
              View all →
            </Link>
          </div>

          {recentEvents.length === 0 ? (
            <div className="text-center py-8">
              <p className="text-gray-500">No events available</p>
            </div>
          ) : (
            <div className="space-y-4">
              {recentEvents.map((event) => (
                <div key={event.id} className="border border-gray-200 rounded-lg p-4">
                  <h3 className="font-medium mb-2">
                    <Link to={`/events/${event.id}`} className="hover:text-blue-600">
                      {event.title}
                    </Link>
                  </h3>
                  <p className="text-sm text-gray-600 mb-2">{event.description}</p>
                  <div className="flex justify-between items-center text-sm">
                    <span className="text-gray-500">
                      {new Date(event.startDate).toLocaleDateString()}
                    </span>
                    <span className="font-medium text-blue-600">
                      ${event.price === 0 ? 'Free' : event.price.toFixed(2)}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Quick Actions */}
      <div className="mt-8 grid md:grid-cols-3 gap-4">
        <Link to="/events" className="card hover:shadow-lg transition-shadow">
          <div className="text-center">
            <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center mx-auto mb-4">
              <svg className="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </div>
            <h3 className="font-medium mb-2">Browse Events</h3>
            <p className="text-sm text-gray-600">Discover new events and experiences</p>
          </div>
        </Link>

        <Link to="/create-event" className="card hover:shadow-lg transition-shadow">
          <div className="text-center">
            <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center mx-auto mb-4">
              <svg className="w-6 h-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
              </svg>
            </div>
            <h3 className="font-medium mb-2">Create Event</h3>
            <p className="text-sm text-gray-600">Host your own event</p>
          </div>
        </Link>

        <Link to="/my-payments" className="card hover:shadow-lg transition-shadow">
          <div className="text-center">
            <div className="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center mx-auto mb-4">
              <svg className="w-6 h-6 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
              </svg>
            </div>
            <h3 className="font-medium mb-2">Payment History</h3>
            <p className="text-sm text-gray-600">View your transactions</p>
          </div>
        </Link>
      </div>
    </div>
  )
}

export default DashboardPage