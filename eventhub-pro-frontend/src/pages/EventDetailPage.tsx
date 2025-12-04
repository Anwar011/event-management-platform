import React, { useState } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'
import { useQuery, useMutation } from '@tanstack/react-query'
import { useAuth } from '../contexts/AuthContext'
import apiService, { createReservationFallback } from '../services/api'
import LoadingSpinner from '../components/LoadingSpinner'

const EventDetailPage: React.FC = () => {
  const { id } = useParams()
  const navigate = useNavigate()
  const { user, isAuthenticated } = useAuth()
  const [attendeeCount, setAttendeeCount] = useState(1)
  const [specialRequests, setSpecialRequests] = useState('')
  const [isBooking, setIsBooking] = useState(false)

  const eventId = parseInt(id || '0')

  const { data: event, isLoading, error } = useQuery({
    queryKey: ['event', eventId],
    queryFn: () => apiService.getEvent(eventId),
    enabled: !!eventId,
  })

  const { data: availability } = useQuery({
    queryKey: ['event-availability', eventId],
    queryFn: () => apiService.getEventAvailability(eventId),
    enabled: !!eventId,
    refetchInterval: 30000, // Refresh every 30 seconds
  })

  const createReservationMutation = useMutation({
    mutationFn: async (reservationData: any) => {
      try {
        console.log('Trying main API service...')
        return await apiService.createReservation(reservationData)
      } catch (error) {
        console.log('Main API failed, trying fallback...', error)
        return await createReservationFallback(reservationData)
      }
    },
    onSuccess: (reservation) => {
      alert(`Reservation created successfully! Reservation ID: ${reservation.id}`)
      navigate('/reservations')
      setIsBooking(false)
    },
    onError: (error: any) => {
      console.error('All reservation methods failed:', error)
      alert(`Failed to create reservation: ${error.response?.data?.message || error.message}`)
      setIsBooking(false)
    }
  })

  const handleBookEvent = async () => {
    if (!isAuthenticated) {
      alert('Please log in to book events')
      navigate('/login')
      return
    }

    if (!user) {
      alert('User information not available')
      return
    }

    setIsBooking(true)
    
    try {
      // First check API health
      const isHealthy = await apiService.healthCheck()
      if (!isHealthy) {
        throw new Error('API service is not responding')
      }

      const reservationData = {
        eventId,
        userId: user.id,
        attendeeCount, // This will be transformed to 'quantity' in the API service
      }
      
      console.log('Submitting reservation:', reservationData)
      createReservationMutation.mutate(reservationData)
    } catch (error) {
      console.error('Booking error:', error)
      alert(`Failed to book event: ${error instanceof Error ? error.message : 'Unknown error'}`)
      setIsBooking(false)
    }
  }

  if (isLoading) return <LoadingSpinner />

  if (error || !event) {
    return (
      <div className="min-h-screen bg-gray-50 p-8">
        <div className="max-w-4xl mx-auto">
          <div className="card">
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
              {error ? 'Error loading event details. Please try again.' : 'Event not found.'}
            </div>
            <Link to="/events" className="btn btn-primary mt-4">
              Back to Events
            </Link>
          </div>
        </div>
      </div>
    )
  }

  const totalPrice = event.price * attendeeCount
  const availableSpots = availability?.availableCapacity || event.availableCapacity || 0
  const isAvailable = availableSpots > 0 && event.status === 'PUBLISHED'
  const canBook = isAvailable && attendeeCount <= availableSpots

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Navigation */}
      <nav className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <div className="flex items-center">
              <Link to="/" className="text-2xl font-bold text-blue-600">EventHub Pro</Link>
            </div>
            <div className="flex space-x-4">
              <Link to="/events" className="text-gray-600 hover:text-blue-600">
                Back to Events
              </Link>
              {isAuthenticated && (
                <Link to="/dashboard" className="btn btn-primary">
                  Dashboard
                </Link>
              )}
            </div>
          </div>
        </div>
      </nav>

      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid md:grid-cols-3 gap-8">
          {/* Event Details */}
          <div className="md:col-span-2">
            <div className="card">
              <div className="flex items-center justify-between mb-4">
                <span className={`px-3 py-1 text-sm rounded-full ${
                  event.status === 'PUBLISHED' ? 'bg-green-100 text-green-800' :
                  event.status === 'DRAFT' ? 'bg-yellow-100 text-yellow-800' :
                  'bg-gray-100 text-gray-800'
                }`}>
                  {event.status}
                </span>
                <span className="text-sm text-gray-600">{event.eventType}</span>
              </div>
              
              <h1 className="text-3xl font-bold text-gray-900 mb-4">{event.title}</h1>
              
              <div className="prose max-w-none mb-6">
                <p className="text-gray-700 text-lg leading-relaxed">
                  {event.description}
                </p>
              </div>

              <div className="grid md:grid-cols-2 gap-6 mb-6">
                <div>
                  <h3 className="text-lg font-semibold text-gray-900 mb-3">Event Details</h3>
                  <div className="space-y-2">
                    <div className="flex items-center text-gray-600">
                      <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                      </svg>
                      {new Date(event.startDate).toLocaleDateString('en-US', {
                        weekday: 'long',
                        year: 'numeric',
                        month: 'long',
                        day: 'numeric'
                      })}
                    </div>
                    <div className="flex items-center text-gray-600">
                      <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                      {new Date(event.startDate).toLocaleTimeString('en-US', {
                        hour: 'numeric',
                        minute: '2-digit'
                      })}
                    </div>
                    <div className="flex items-center text-gray-600">
                      <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                      </svg>
                      {event.venue}
                    </div>
                  </div>
                </div>

                <div>
                  <h3 className="text-lg font-semibold text-gray-900 mb-3">Capacity & Pricing</h3>
                  <div className="space-y-2">
                    <div className="flex items-center text-gray-600">
                      <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                      </svg>
                      {availableSpots} / {event.capacity} spots available
                    </div>
                    <div className="flex items-center text-gray-600">
                      <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1" />
                      </svg>
                      ${event.price} per ticket
                    </div>
                  </div>
                </div>
              </div>

              {/* Availability Status */}
              {!isAvailable && (
                <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded mb-6">
                  {availableSpots === 0 ? 'This event is sold out.' : 'This event is not currently available for booking.'}
                </div>
              )}
            </div>
          </div>

          {/* Booking Panel */}
          <div>
            <div className="card sticky top-8">
              <h3 className="text-xl font-semibold text-gray-900 mb-4">Book This Event</h3>
              
              {!isAuthenticated ? (
                <div className="text-center">
                  <p className="text-gray-600 mb-4">Please log in to book this event</p>
                  <Link to="/login" className="btn btn-primary w-full">
                    Login to Book
                  </Link>
                </div>
              ) : (
                <div className="space-y-4">
                  <div>
                    <label htmlFor="attendees" className="block text-sm font-medium text-gray-700 mb-2">
                      Number of Attendees
                    </label>
                    <select
                      id="attendees"
                      value={attendeeCount}
                      onChange={(e) => setAttendeeCount(parseInt(e.target.value))}
                      className="input"
                      disabled={!isAvailable}
                    >
                      {Array.from({ length: Math.min(10, availableSpots) }, (_, i) => i + 1).map(num => (
                        <option key={num} value={num}>{num}</option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label htmlFor="requests" className="block text-sm font-medium text-gray-700 mb-2">
                      Special Requests (Optional)
                    </label>
                    <textarea
                      id="requests"
                      value={specialRequests}
                      onChange={(e) => setSpecialRequests(e.target.value)}
                      placeholder="Any dietary restrictions, accessibility needs, etc."
                      rows={3}
                      className="input"
                      disabled={!isAvailable}
                    />
                  </div>

                  <div className="border-t pt-4">
                    <div className="flex justify-between items-center mb-4">
                      <span className="text-lg font-medium">Total:</span>
                      <span className="text-2xl font-bold text-blue-600">${totalPrice.toFixed(2)}</span>
                    </div>
                    
                    <button
                      onClick={handleBookEvent}
                      disabled={!canBook || isBooking}
                      className={`w-full btn ${
                        canBook ? 'btn-primary' : 'bg-gray-300 text-gray-500 cursor-not-allowed'
                      }`}
                    >
                      {isBooking ? (
                        <>
                          <div className="spinner mr-2"></div>
                          Booking...
                        </>
                      ) : canBook ? (
                        'Book Now'
                      ) : (
                        'Not Available'
                      )}
                    </button>

                    {canBook && (
                      <p className="text-xs text-gray-500 mt-2 text-center">
                        You'll be able to confirm your booking in the next step
                      </p>
                    )}
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default EventDetailPage
