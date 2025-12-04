import React from 'react'
import { useQuery } from '@tanstack/react-query'
import { useAuth } from '../contexts/AuthContext'
import apiService from '../services/api'
import LoadingSpinner from '../components/LoadingSpinner'
import { Link } from 'react-router-dom'

const PaymentsPage: React.FC = () => {
  const { user } = useAuth()

  const { data: payments, isLoading: paymentsLoading } = useQuery({
    queryKey: ['payments', user?.id],
    queryFn: () => user ? apiService.getUserPayments(user.id) : Promise.resolve([]),
    enabled: !!user?.id,
  })

  const { data: paymentIntents, isLoading: intentsLoading } = useQuery({
    queryKey: ['payment-intents', user?.id],
    queryFn: () => user ? apiService.getUserPaymentIntents(user.id) : Promise.resolve([]),
    enabled: !!user?.id,
  })

  const isLoading = paymentsLoading || intentsLoading

  if (isLoading) return <LoadingSpinner />

  const allTransactions = [
    ...(payments || []).map(p => ({ ...p, type: 'payment' })),
    ...(paymentIntents || []).map(p => ({ ...p, type: 'intent' }))
  ].sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold">Payment History</h1>
        <div className="text-sm text-gray-600">
          Total Transactions: {allTransactions.length}
        </div>
      </div>
      
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
                      transaction.status === 'COMPLETED' || transaction.status === 'CAPTURED' ? 'bg-green-100 text-green-800' :
                      transaction.status === 'PENDING' || transaction.status === 'CREATED' ? 'bg-yellow-100 text-yellow-800' :
                      transaction.status === 'FAILED' || transaction.status === 'CANCELLED' ? 'bg-red-100 text-red-800' :
                      'bg-gray-100 text-gray-800'
                    }`}>
                      {transaction.status}
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

      {/* Payment Summary Stats */}
      {allTransactions.length > 0 && (
        <div className="mt-8 card">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Payment Summary</h3>
          <div className="grid md:grid-cols-3 gap-4">
            <div className="text-center">
              <div className="text-2xl font-bold text-green-600">
                {allTransactions.filter(t => t.status === 'COMPLETED' || t.status === 'CAPTURED').length}
              </div>
              <div className="text-sm text-gray-600">Completed Payments</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-yellow-600">
                {allTransactions.filter(t => t.status === 'PENDING' || t.status === 'CREATED').length}
              </div>
              <div className="text-sm text-gray-600">Pending Payments</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-blue-600">
                $
                {allTransactions
                  .filter(t => t.status === 'COMPLETED' || t.status === 'CAPTURED')
                  .reduce((sum, t) => sum + t.amount, 0)
                  .toFixed(2)}
              </div>
              <div className="text-sm text-gray-600">Total Paid</div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default PaymentsPage
