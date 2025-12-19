import React from 'react'
import { useQuery } from '@tanstack/react-query'
import { useAuth } from '../contexts/AuthContext'
import apiService from '../services/api'
import LoadingSpinner from '../components/LoadingSpinner'
import { Link } from 'react-router-dom'

const PaymentsPage: React.FC = () => {
  const { user } = useAuth()

  const { data: payments, isLoading: paymentsLoading, error: paymentsError } = useQuery({
    queryKey: ['payments', user?.id],
    queryFn: () => user ? apiService.getUserPayments(user.id) : Promise.resolve([]),
    enabled: !!user?.id,
    onError: (error) => {
      console.error('Error fetching payments:', error)
    },
    onSuccess: (data) => {
      console.log('Payments fetched successfully:', data)
    }
  })

  const { data: paymentIntents, isLoading: intentsLoading, error: intentsError } = useQuery({
    queryKey: ['payment-intents', user?.id],
    queryFn: () => user ? apiService.getUserPaymentIntents(user.id) : Promise.resolve([]),
    enabled: !!user?.id,
    onError: (error) => {
      console.error('Error fetching payment intents:', error)
    },
    onSuccess: (data) => {
      console.log('Payment intents fetched successfully:', data)
    }
  })

  const isLoading = paymentsLoading || intentsLoading

  if (isLoading) return <LoadingSpinner />

  // Debug logging
  console.log('User ID:', user?.id)
  console.log('Payments data:', payments)
  console.log('Payment Intents data:', paymentIntents)
  console.log('Payments error:', paymentsError)
  console.log('Intents error:', intentsError)

  const allTransactions = [
    ...(payments || []).map(p => ({ ...p, type: 'payment' })),
    ...(paymentIntents || []).map(p => ({ ...p, type: 'intent' }))
  ].sort((a, b) => new Date(b.createdAt || b.created_at || 0).getTime() - new Date(a.createdAt || a.created_at || 0).getTime())

  console.log('All transactions:', allTransactions)
  console.log('Completed count:', allTransactions.filter(t => 
    t.status === 'SUCCEEDED' || 
    t.status === 'COMPLETED' || 
    t.status === 'CAPTURED'
  ).length)
  console.log('Pending count:', allTransactions.filter(t => 
    t.status === 'PENDING' || 
    t.status === 'CREATED' || 
    t.status === 'REQUIRES_PAYMENT_METHOD' ||
    t.status === 'PROCESSING'
  ).length)

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold">Payment History</h1>
        <div className="text-sm text-gray-600">
          Total Transactions: {allTransactions.length}
          {user && (
            <span className="ml-2 text-blue-600 font-medium">
              (User ID: {user.id})
            </span>
          )}
        </div>
      </div>
      
      {!user && (
        <div className="card mb-4 bg-red-50 border border-red-200">
          <p className="text-red-800 text-sm">
            ⚠️ No user logged in. Please login to view payment history.
          </p>
        </div>
      )}
      
      {(paymentsError || intentsError) && (
        <div className="card mb-4 bg-yellow-50 border border-yellow-200">
          <p className="text-yellow-800 text-sm">
            ⚠️ Some payment data could not be loaded. Check browser console for details.
          </p>
        </div>
      )}
      
      {allTransactions.length === 0 ? (
        <div className="card text-center">
          <svg className="w-16 h-16 text-gray-400 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
          </svg>
          <h3 className="text-xl font-semibold text-gray-900 mb-2">No Payment History</h3>
          <p className="text-gray-600 mb-4">You haven't made any payments yet.</p>
          <Link to="/events" className="btn btn-primary">
            Browse Events
          </Link>
        </div>
      ) : (
        <div className="space-y-4">
          {allTransactions.map((transaction) => (
            <div key={`${transaction.type}-${transaction.id}`} className="card">
              <div className="flex justify-between items-start">
                <div className="flex-1">
                  <div className="flex items-center justify-between mb-2">
                    <h3 className="text-lg font-semibold text-gray-900">
                      {transaction.type === 'payment' ? 'Payment' : 'Payment Intent'} #{transaction.id}
                    </h3>
                    <span className={`px-3 py-1 text-sm rounded-full ${
                      transaction.status === 'SUCCEEDED' || transaction.status === 'COMPLETED' || transaction.status === 'CAPTURED' ? 'bg-green-100 text-green-800' :
                      transaction.status === 'PENDING' || transaction.status === 'CREATED' || transaction.status === 'REQUIRES_PAYMENT_METHOD' || transaction.status === 'PROCESSING' ? 'bg-yellow-100 text-yellow-800' :
                      transaction.status === 'FAILED' || transaction.status === 'CANCELLED' || transaction.status === 'CANCELED' ? 'bg-red-100 text-red-800' :
                      'bg-gray-100 text-gray-800'
                    }`}>
                      {transaction.status || 'UNKNOWN'}
                    </span>
                  </div>
                  
                  <div className="grid md:grid-cols-3 gap-4 text-sm">
                    <div>
                      <p className="text-gray-600"><span className="font-medium">Amount:</span> ${transaction.amount}</p>
                      <p className="text-gray-600"><span className="font-medium">Currency:</span> {transaction.currency}</p>
                      {transaction.type === 'payment' && (transaction as any).method && (
                        <p className="text-gray-600"><span className="font-medium">Method:</span> {(transaction as any).method}</p>
                      )}
                    </div>
                    <div>
                      <p className="text-gray-600"><span className="font-medium">Reservation ID:</span> {transaction.reservationId}</p>
                      <p className="text-gray-600"><span className="font-medium">Created:</span> {new Date(transaction.createdAt).toLocaleDateString()}</p>
                      {transaction.type === 'payment' && (transaction as any).processedAt && (
                        <p className="text-gray-600"><span className="font-medium">Processed:</span> {new Date((transaction as any).processedAt).toLocaleDateString()}</p>
                      )}
                    </div>
                    <div>
                      {transaction.type === 'intent' && (transaction as any).expiresAt && (
                        <p className="text-gray-600"><span className="font-medium">Expires:</span> {new Date((transaction as any).expiresAt).toLocaleString()}</p>
                      )}
                      {transaction.type === 'payment' && (transaction as any).transactionId && (
                        <p className="text-gray-600"><span className="font-medium">Transaction ID:</span> {(transaction as any).transactionId}</p>
                      )}
                      {(transaction as any).idempotencyKey && (
                        <p className="text-gray-600 text-xs"><span className="font-medium">Idempotency:</span> {(transaction as any).idempotencyKey}</p>
                      )}
                    </div>
                  </div>
                  
                  {(transaction as any).metadata && Object.keys((transaction as any).metadata).length > 0 && (
                    <div className="mt-3 p-3 bg-gray-50 rounded">
                      <p className="text-sm font-medium text-gray-700 mb-1">Additional Details:</p>
                      <pre className="text-xs text-gray-600 whitespace-pre-wrap">
                        {JSON.stringify((transaction as any).metadata, null, 2)}
                      </pre>
                    </div>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Payment Summary Stats - Always show */}
      <div className="mt-8 card">
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-semibold text-gray-900">Payment Summary</h3>
          {user && (
            <span className="text-xs text-gray-500">
              Fetching data for User ID: {user.id}
            </span>
          )}
        </div>
        {(() => {
          // Calculate statistics
          const completedPayments = allTransactions.filter(t => {
            const status = String(t.status || '').toUpperCase()
            return status === 'SUCCEEDED' || status === 'COMPLETED' || status === 'CAPTURED'
          })
          
          const pendingPayments = allTransactions.filter(t => {
            const status = String(t.status || '').toUpperCase()
            return status === 'PENDING' || 
                   status === 'CREATED' || 
                   status === 'REQUIRES_PAYMENT_METHOD' ||
                   status === 'PROCESSING' ||
                   status === 'REQUIRES_ACTION' ||
                   status === 'REQUIRES_CONFIRMATION'
          })
          
          const totalPaid = completedPayments.reduce((sum, t) => {
            const amount = typeof t.amount === 'number' ? t.amount : parseFloat(String(t.amount || 0))
            return sum + (isNaN(amount) ? 0 : amount)
          }, 0)
          
          console.log('Summary calculation:', {
            totalTransactions: allTransactions.length,
            completed: completedPayments.length,
            pending: pendingPayments.length,
            totalPaid,
            allStatuses: allTransactions.map(t => ({ id: t.id, status: t.status, amount: t.amount }))
          })
          
          return (
            <div className="grid md:grid-cols-3 gap-4">
              <div className="text-center">
                <div className="text-2xl font-bold text-green-600">
                  {completedPayments.length}
                </div>
                <div className="text-sm text-gray-600">Completed Payments</div>
                {completedPayments.length > 0 && (
                  <div className="text-xs text-gray-500 mt-1">
                    {completedPayments.map(p => p.status).join(', ')}
                  </div>
                )}
              </div>
              <div className="text-center">
                <div className="text-2xl font-bold text-yellow-600">
                  {pendingPayments.length}
                </div>
                <div className="text-sm text-gray-600">Pending Payments</div>
                {pendingPayments.length > 0 && (
                  <div className="text-xs text-gray-500 mt-1">
                    {pendingPayments.map(p => p.status).join(', ')}
                  </div>
                )}
              </div>
              <div className="text-center">
                <div className="text-2xl font-bold text-blue-600">
                  ${totalPaid.toFixed(2)}
                </div>
                <div className="text-sm text-gray-600">Total Paid</div>
              </div>
            </div>
          )
        })()}
        
        {/* Debug info - remove in production */}
        {process.env.NODE_ENV === 'development' && allTransactions.length > 0 && (
          <div className="mt-4 p-3 bg-gray-50 rounded text-xs">
            <p className="font-medium mb-1">Debug Info:</p>
            <p>Total transactions: {allTransactions.length}</p>
            <p>Payments: {payments?.length || 0}, Intents: {paymentIntents?.length || 0}</p>
            <p>Statuses: {allTransactions.map(t => t.status).join(', ')}</p>
          </div>
        )}
      </div>
    </div>
  )
}

export default PaymentsPage

