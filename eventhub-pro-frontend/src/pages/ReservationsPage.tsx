import React, { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useAuth } from '../contexts/AuthContext'
import apiService from '../services/api'
import LoadingSpinner from '../components/LoadingSpinner'
import { Link } from 'react-router-dom'

const ReservationsPage: React.FC = () => {
  const { user } = useAuth()
  const queryClient = useQueryClient()
  const [processingPayment, setProcessingPayment] = useState<string | null>(null)

  const { data: reservations, isLoading, error } = useQuery({
    queryKey: ['reservations', user?.id],
    queryFn: () => user ? apiService.getUserReservations(user.id) : Promise.resolve([]),
    enabled: !!user?.id,
  })

  const handleCancelReservation = async (reservationId: string) => {
    if (window.confirm('Are you sure you want to cancel this reservation?')) {
      try {
        await apiService.cancelReservation(reservationId)
        queryClient.invalidateQueries({ queryKey: ['reservations', user?.id] })
      } catch (error) {
        alert('Failed to cancel reservation. Please try again.')
      }
    }
  }

  const handlePayReservation = async (reservation: any) => {
    if (!user) {
      alert('User information not available')
      return
    }

    if (!window.confirm(`Pay $${reservation.totalPrice || reservation.totalAmount} for this reservation?`)) {
      return
    }

    setProcessingPayment(reservation.reservationId)

    try {
      // Step 1: Create payment intent
      const paymentIntent = await apiService.createPaymentIntent({
        reservationId: reservation.reservationId,
        userId: user.id,
        amount: reservation.totalPrice || reservation.totalAmount,
        currency: 'USD',
        paymentMethod: 'CARD',
        description: `Payment for reservation ${reservation.reservationId}`,
        idempotencyKey: `pay-${reservation.reservationId}-${Date.now()}`
      })

      // Step 2: Capture payment (process it)
      const payment = await apiService.capturePayment(paymentIntent.intentId)

      if (payment.status === 'SUCCEEDED') {
        alert(`Payment successful! Payment ID: ${payment.paymentId}`)
        // Refresh reservations and payments
        queryClient.invalidateQueries({ queryKey: ['reservations', user.id] })
        queryClient.invalidateQueries({ queryKey: ['payments', user.id] })
        queryClient.invalidateQueries({ queryKey: ['payment-intents', user.id] })
      } else {
        alert(`Payment failed: ${payment.failureReason || 'Unknown error'}`)
      }
    } catch (error: any) {
      console.error('Payment error:', error)
      alert(`Payment failed: ${error.response?.data?.message || error.message || 'Unknown error'}`)
    } finally {
      setProcessingPayment(null)
    }
  }

  if (isLoading) return <LoadingSpinner />

  if (error) {
    return (
      <div>
        <h1 className="text-3xl font-bold mb-6">My Reservations</h1>
        <div className="card">
          <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
            Error loading reservations. Please try again.
          </div>
        </div>
      </div>
    )
  }

  return (
    <div>
      <h1 className="text-3xl font-bold mb-6">My Reservations</h1>
      
      {!reservations || reservations.length === 0 ? (
        <div className="card text-center">
          <svg className="w-16 h-16 text-gray-400 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
          </svg>
          <h3 className="text-xl font-semibold text-gray-900 mb-2">No Reservations Yet</h3>
          <p className="text-gray-600 mb-4">You haven't made any event reservations yet.</p>
          <Link to="/events" className="btn btn-primary">
            Browse Events
          </Link>
        </div>
      ) : (
        <div className="space-y-4">
          {reservations.map((reservation) => (
            <div key={reservation.id} className="card">
              <div className="flex justify-between items-start mb-4">
                <div className="flex-1">
                  <h3 className="text-lg font-semibold text-gray-900 mb-2">
                    Reservation #{reservation.id}
                  </h3>
                  <div className="grid md:grid-cols-2 gap-4 text-sm">
                    <div>
                      <p className="text-gray-600"><span className="font-medium">Event ID:</span> {reservation.eventId}</p>
                      <p className="text-gray-600"><span className="font-medium">Attendees:</span> {reservation.quantity || reservation.attendeeCount || 1}</p>
                      <p className="text-gray-600"><span className="font-medium">Total Amount:</span> ${(reservation.totalPrice || reservation.totalAmount || 0).toFixed(2)}</p>
                      <p className="text-gray-600"><span className="font-medium">Reservation ID:</span> {reservation.reservationId}</p>
                    </div>
                    <div>
                      <p className="text-gray-600"><span className="font-medium">Status:</span> 
                        <span className={`ml-2 px-2 py-1 text-xs rounded-full ${
                          reservation.status === 'CONFIRMED' ? 'bg-green-100 text-green-800' :
                          reservation.status === 'PENDING' ? 'bg-yellow-100 text-yellow-800' :
                          reservation.status === 'CANCELLED' ? 'bg-red-100 text-red-800' :
                          'bg-gray-100 text-gray-800'
                        }`}>
                          {reservation.status}
                        </span>
                      </p>
                      <p className="text-gray-600"><span className="font-medium">Created:</span> {new Date(reservation.createdAt).toLocaleDateString()}</p>
                      {reservation.expiresAt && (
                        <p className="text-gray-600"><span className="font-medium">Expires:</span> {new Date(reservation.expiresAt).toLocaleString()}</p>
                      )}
                    </div>
                  </div>
                  {reservation.specialRequests && (
                    <div className="mt-3">
                      <p className="text-gray-600"><span className="font-medium">Special Requests:</span> {reservation.specialRequests}</p>
                    </div>
                  )}
                </div>
                <div className="flex flex-col space-y-2 ml-4">
                  <Link 
                    to={`/events/${reservation.eventId}`} 
                    className="btn btn-secondary text-sm"
                  >
                    View Event
                  </Link>
                  {reservation.status === 'PENDING' && (
                    <>
                      <button
                        onClick={() => handlePayReservation(reservation)}
                        disabled={processingPayment === reservation.reservationId}
                        className={`btn text-sm ${
                          processingPayment === reservation.reservationId
                            ? 'bg-gray-400 cursor-not-allowed'
                            : 'bg-green-600 text-white hover:bg-green-700'
                        }`}
                      >
                        {processingPayment === reservation.reservationId ? (
                          <>
                            <div className="spinner mr-2"></div>
                            Processing...
                          </>
                        ) : (
                          <>
                            <svg className="w-4 h-4 mr-1 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
                            </svg>
                            Pay Now
                          </>
                        )}
                      </button>
                      <button
                        onClick={() => handleCancelReservation(reservation.reservationId)}
                        className="btn bg-red-600 text-white hover:bg-red-700 text-sm"
                      >
                        Cancel
                      </button>
                    </>
                  )}
                  {reservation.status === 'CONFIRMED' && (
                    <span className="text-sm text-green-600 font-medium">
                      ✓ Paid
                    </span>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

export default ReservationsPage
