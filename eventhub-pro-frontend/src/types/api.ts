// User Types
export interface User {
  id: number
  email: string
  firstName: string
  lastName: string
  roles: string[]
}

export interface AuthRequest {
  email: string
  password: string
}

export interface RegisterRequest extends AuthRequest {
  firstName: string
  lastName: string
}

export interface AuthResponse {
  token: string
  type: string
  userId: number
  email: string
  firstName: string
  lastName: string
  roles: string[]
}

// Event Types
export interface Event {
  id: number
  title: string
  description: string
  eventType: string
  venue: string
  address: string
  city: string
  state: string
  country: string
  postalCode: string
  startDate: string
  endDate: string
  capacity: number
  price: number
  organizerId: number
  status: string
  createdAt: string
  updatedAt: string
  availableCapacity?: number
  reservedCapacity?: number
}

export interface CreateEventRequest {
  title: string
  description: string
  eventType: string
  venue: string
  address?: string
  city?: string
  state?: string
  country?: string
  postalCode?: string
  startDate: string
  endDate?: string
  capacity: number
  price: number
  organizerId: number
}

// Reservation Types
export interface Reservation {
  id: number
  reservationId: string
  userId: number
  eventId: number
  quantity: number
  totalPrice: number
  status: string
  idempotencyKey?: string
  createdAt: string
  updatedAt: string
  items: ReservationItem[]
}

export interface ReservationItem {
  id: number
  ticketType: string
  quantity: number
  unitPrice: number
  createdAt: string
}

export interface CreateReservationRequest {
  userId: number
  eventId: number
  quantity: number
  idempotencyKey?: string
}

// Payment Types
export interface PaymentIntent {
  id: number
  intentId: string
  reservationId: string
  userId: number
  amount: number
  currency: string
  status: string
  idempotencyKey?: string
  paymentMethod: string
  description: string
  expiresAt: string
  createdAt: string
  updatedAt: string
}

export interface CreatePaymentIntentRequest {
  reservationId: string
  userId: number
  amount: number
  currency?: string
  paymentMethod?: string
  description?: string
  idempotencyKey?: string
}

export interface Payment {
  id: number
  paymentId: string
  reservationId: string
  userId: number
  amount: number
  currency: string
  status: string
  paymentMethod: string
  providerReference?: string
  failureReason?: string
  capturedAt?: string
  createdAt: string
  updatedAt: string
}

// API Response Types
export interface PaginatedResponse<T> {
  content: T[]
  pageable: {
    pageNumber: number
    pageSize: number
    sort: {
      sorted: boolean
      empty: boolean
      unsorted: boolean
    }
    offset: number
    paged: boolean
    unpaged: boolean
  }
  totalPages: number
  totalElements: number
  last: boolean
  size: number
  number: number
  sort: {
    sorted: boolean
    empty: boolean
    unsorted: boolean
  }
  numberOfElements: number
  first: boolean
  empty: boolean
}

export interface ApiError {
  timestamp: string
  status: number
  error: string
  message: string
  path: string
}