import axios, { AxiosInstance, AxiosResponse } from 'axios'
import {
  AuthRequest,
  RegisterRequest,
  AuthResponse,
  User,
  Event,
  CreateEventRequest,
  PaginatedResponse,
  Reservation,
  CreateReservationRequest,
  PaymentIntent,
  CreatePaymentIntentRequest,
  Payment,
} from '../types/api'

class ApiService {
  private api: AxiosInstance

  constructor() {
    try {
      this.api = axios.create({
        baseURL: 'http://localhost:8080/v1',
        timeout: 10000,
        headers: {
          'Content-Type': 'application/json',
        },
      })

      // Request interceptor to add auth token
      this.api.interceptors.request.use(
        (config) => {
          const token = localStorage.getItem('token')
          if (token) {
            config.headers.Authorization = `Bearer ${token}`
          }
          return config
        },
        (error) => {
          console.error('Request interceptor error:', error)
          return Promise.reject(error)
        }
      )

      // Response interceptor for error handling
      this.api.interceptors.response.use(
        (response) => response,
        (error) => {
          console.error('Response interceptor error:', error)
          if (error.response?.status === 401) {
            localStorage.removeItem('token')
            localStorage.removeItem('user')
            window.location.href = '/login'
          }
          return Promise.reject(error)
        }
      )
      
      console.log('API Service initialized successfully')
    } catch (error) {
      console.error('Failed to initialize API Service:', error)
      throw error
    }
  }

  // Ensure API instance is available
  private ensureApi(): AxiosInstance {
    if (!this.api) {
      throw new Error('API service not properly initialized')
    }
    return this.api
  }

  // Health check
  async healthCheck(): Promise<boolean> {
    try {
      const api = this.ensureApi()
      const response = await api.get('/events?page=0&size=1')
      console.log('Health check successful:', response.status)
      return response.status === 200
    } catch (error) {
      console.error('Health check failed:', error)
      return false
    }
  }

  // Authentication APIs
  async login(credentials: AuthRequest): Promise<AuthResponse> {
    const api = this.ensureApi()
    const response: AxiosResponse<AuthResponse> = await api.post('/auth/login', credentials)
    return response.data
  }

  async register(userData: RegisterRequest): Promise<AuthResponse> {
    const response: AxiosResponse<AuthResponse> = await this.api.post('/auth/register', userData)
    return response.data
  }

  async getCurrentUser(): Promise<User> {
    const response: AxiosResponse<User> = await this.api.get('/users/me')
    return response.data
  }

  // Event APIs
  async getEvents(page = 0, size = 20): Promise<PaginatedResponse<Event>> {
    const response: AxiosResponse<PaginatedResponse<Event>> = await this.api.get('/events', {
      params: { page, size }
    })
    return response.data
  }

  async getEvent(id: number): Promise<Event> {
    const response: AxiosResponse<Event> = await this.api.get(`/events/${id}`)
    return response.data
  }

  async createEvent(eventData: CreateEventRequest): Promise<Event> {
    const response: AxiosResponse<Event> = await this.api.post('/events', eventData)
    return response.data
  }

  async updateEvent(id: number, eventData: Partial<CreateEventRequest>): Promise<Event> {
    const response: AxiosResponse<Event> = await this.api.put(`/events/${id}`, eventData)
    return response.data
  }

  async publishEvent(id: number): Promise<Event> {
    const response: AxiosResponse<Event> = await this.api.post(`/events/${id}/publish`)
    return response.data
  }

  async getEventAvailability(id: number): Promise<{ eventId: number; availableCapacity: number }> {
    const response = await this.api.get(`/events/${id}/availability`)
    return response.data
  }

  async searchEvents(searchTerm?: string, city?: string, eventType?: string): Promise<PaginatedResponse<Event>> {
    const params: any = {}
    if (searchTerm) params.searchTerm = searchTerm
    if (city) params.city = city
    if (eventType) params.eventType = eventType

    const response: AxiosResponse<PaginatedResponse<Event>> = await this.api.get('/events', { params })
    return response.data
  }

  // Reservation APIs
  async createReservation(reservationData: CreateReservationRequest): Promise<Reservation> {
    console.log('Creating reservation with original data:', reservationData)
    
    // Transform the data to match backend expectations
    const backendRequest = {
      userId: reservationData.userId,
      eventId: reservationData.eventId,
      quantity: reservationData.attendeeCount, // Transform attendeeCount to quantity
      idempotencyKey: `frontend-${Date.now()}-${Math.random().toString(36).substr(2, 9)}` // Generate unique key
    }
    
    console.log('Transformed request for backend:', backendRequest)
    
    try {
      const api = this.ensureApi()
      console.log('API instance confirmed, making request to:', api.defaults.baseURL + '/reservations')
      
      const response: AxiosResponse<Reservation> = await api.post('/reservations', backendRequest)
      console.log('✅ Reservation created successfully:', response.data)
      return response.data
    } catch (error) {
      console.error('❌ Reservation creation failed:', error)
      if (axios.isAxiosError(error) && error.response) {
        console.error('Error response data:', error.response.data)
        throw new Error(`Failed to create reservation: ${error.response.data.message || error.response.status}`)
      }
      if (error instanceof Error) {
        throw new Error(`Failed to create reservation: ${error.message}`)
      }
      throw new Error('Failed to create reservation: Unknown error')
    }
  }

  async getReservation(reservationId: string): Promise<Reservation> {
    const response: AxiosResponse<Reservation> = await this.api.get(`/reservations/${reservationId}`)
    return response.data
  }

  async getUserReservations(userId: number): Promise<Reservation[]> {
    const response: AxiosResponse<Reservation[]> = await this.api.get(`/reservations/user/${userId}`)
    return response.data
  }

  async confirmReservation(reservationId: string): Promise<Reservation> {
    const response: AxiosResponse<Reservation> = await this.api.post(`/reservations/${reservationId}/confirm`)
    return response.data
  }

  async cancelReservation(reservationId: string): Promise<Reservation> {
    const response: AxiosResponse<Reservation> = await this.api.post(`/reservations/${reservationId}/cancel`)
    return response.data
  }

  // Payment APIs
  async createPaymentIntent(paymentData: CreatePaymentIntentRequest): Promise<PaymentIntent> {
    const response: AxiosResponse<PaymentIntent> = await this.api.post('/payments/intents', paymentData)
    return response.data
  }

  async getPaymentIntent(intentId: string): Promise<PaymentIntent> {
    const response: AxiosResponse<PaymentIntent> = await this.api.get(`/payments/intents/${intentId}`)
    return response.data
  }

  async capturePayment(intentId: string, idempotencyKey?: string): Promise<Payment> {
    const params = idempotencyKey ? { idempotencyKey } : {}
    const response: AxiosResponse<Payment> = await this.api.post(`/payments/intents/${intentId}/capture`, {}, { params })
    return response.data
  }

  async getUserPayments(userId: number): Promise<Payment[]> {
    const response: AxiosResponse<Payment[]> = await this.api.get(`/payments/user/${userId}`)
    return response.data
  }

  async getUserPaymentIntents(userId: number): Promise<PaymentIntent[]> {
    const response: AxiosResponse<PaymentIntent[]> = await this.api.get(`/payments/intents/user/${userId}`)
    return response.data
  }
}

// Create API service instance
let apiServiceInstance: ApiService | null = null

try {
  apiServiceInstance = new ApiService()
  console.log('✅ API Service instance created successfully')
} catch (error) {
  console.error('❌ Failed to create API Service instance:', error)
}

// Fallback API functions using direct axios calls
export const createReservationFallback = async (reservationData: CreateReservationRequest): Promise<any> => {
  console.log('Using fallback reservation creation with data:', reservationData)
  
  // Transform the data to match backend expectations
  const backendRequest = {
    userId: reservationData.userId,
    eventId: reservationData.eventId,
    quantity: reservationData.attendeeCount, // Transform attendeeCount to quantity
    idempotencyKey: `frontend-${Date.now()}-${Math.random().toString(36).substr(2, 9)}` // Generate unique key
  }
  
  console.log('Transformed request for backend:', backendRequest)
  
  const token = localStorage.getItem('token')
  const headers: any = {
    'Content-Type': 'application/json',
  }
  
  if (token) {
    headers.Authorization = `Bearer ${token}`
  }
  
  try {
    const response = await axios.post(
      'http://localhost:8080/v1/reservations',
      backendRequest,
      { headers }
    )
    console.log('✅ Reservation created successfully:', response.data)
    return response.data
  } catch (error) {
    console.error('❌ Fallback reservation creation failed:', error)
    if (axios.isAxiosError(error) && error.response) {
      console.error('Error response:', error.response.data)
    }
    throw error
  }
}

export const apiService = apiServiceInstance!
export default apiService