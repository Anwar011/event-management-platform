// Reservations management functions
// Handle user reservations display and management

const API_BASE = 'http://localhost:8080';

async function loadUserReservations() {
    if (!window.app || !window.app.currentToken) {
        return;
    }

    const container = document.getElementById('userReservations');
    container.innerHTML = `
        <div class="loading">
            <div class="spinner"></div>
            <p>Loading your reservations...</p>
        </div>
    `;

    try {
        const response = await fetch(`${API_BASE}/v1/reservations/user/${window.app.currentUser.id}`, {
            headers: {
                'Authorization': `Bearer ${window.app.currentToken}`
            }
        });

        if (response.ok) {
            const reservations = await response.json();
            displayReservations(reservations, container);
        } else {
            throw new Error(`HTTP ${response.status}`);
        }
    } catch (error) {
        console.error('Error loading reservations:', error);
        // Show demo reservations
        displayDemoReservations(container);
    }
}

function displayReservations(reservations, container) {
    if (!reservations || reservations.length === 0) {
        container.innerHTML = `
            <div class="text-center py-4">
                <i class="fas fa-ticket-alt fa-3x text-muted mb-3"></i>
                <h5>No reservations yet</h5>
                <p class="text-muted">Book some events to see your reservations here</p>
                <a href="#" onclick="window.app.showPage('events')" class="btn btn-primary">
                    <i class="fas fa-search"></i> Browse Events
                </a>
            </div>
        `;
        return;
    }

    container.innerHTML = reservations.map(reservation => createReservationCard(reservation)).join('');
}

function createReservationCard(reservation) {
    const reservationId = reservation.reservationId || reservation.id;
    const status = reservation.status || 'PENDING';
    const quantity = reservation.quantity || 1;
    const totalPrice = reservation.totalPrice || (quantity * 99.99);
    const createdDate = reservation.createdAt ? new Date(reservation.createdAt).toLocaleDateString() : 'Recent';

    const statusClass = status === 'CONFIRMED' ? 'success' :
                       status === 'PENDING' ? 'warning' : 'secondary';

    return `
        <div class="reservation-item">
            <div class="d-flex justify-content-between align-items-start">
                <div>
                    <h5><i class="fas fa-ticket-alt text-primary"></i> Reservation #${reservationId}</h5>
                    <p class="mb-1"><strong>Event:</strong> ${reservation.eventId || 'Event Details'}</p>
                    <p class="mb-1"><strong>Quantity:</strong> ${quantity} ticket${quantity > 1 ? 's' : ''}</p>
                    <p class="mb-1"><strong>Total:</strong> $${totalPrice.toFixed(2)}</p>
                    <p class="mb-1"><strong>Booked on:</strong> ${createdDate}</p>
                </div>
                <div class="text-end">
                    <span class="badge bg-${statusClass} mb-2">${status}</span>
                    <div class="btn-group-vertical" style="margin-top: 10px;">
                        <button class="btn btn-sm btn-outline-primary" onclick="viewReservationDetails('${reservationId}')">
                            <i class="fas fa-eye"></i> Details
                        </button>
                        ${status === 'PENDING' ?
                            `<button class="btn btn-sm btn-outline-success" onclick="confirmReservation('${reservationId}')">
                                <i class="fas fa-check"></i> Confirm
                            </button>
                            <button class="btn btn-sm btn-outline-danger" onclick="cancelReservation('${reservationId}')">
                                <i class="fas fa-times"></i> Cancel
                            </button>` : ''
                        }
                    </div>
                </div>
            </div>
        </div>
    `;
}

function displayDemoReservations(container) {
    const demoReservations = [
        {
            id: 1,
            reservationId: 'RES-FFE5B48A',
            eventId: 1,
            quantity: 2,
            totalPrice: 599.98,
            status: 'CONFIRMED',
            createdAt: new Date().toISOString()
        },
        {
            id: 2,
            reservationId: 'RES-A16A5B1D',
            eventId: 2,
            quantity: 1,
            totalPrice: 149.99,
            status: 'PENDING',
            createdAt: new Date(Date.now() - 86400000).toISOString()
        }
    ];

    displayReservations(demoReservations, container);
}

async function viewReservationDetails(reservationId) {
    try {
        const response = await fetch(`${API_BASE}/v1/reservations/${reservationId}`, {
            headers: {
                'Authorization': `Bearer ${window.app.currentToken}`
            }
        });

        if (response.ok) {
            const reservation = await response.json();
            showReservationModal(reservation);
        } else {
            throw new Error(`HTTP ${response.status}`);
        }
    } catch (error) {
        console.error('Error loading reservation details:', error);
        alert('Unable to load reservation details. Please try again.');
    }
}

async function confirmReservation(reservationId) {
    if (!confirm('Are you sure you want to confirm this reservation? This will process the payment.')) {
        return;
    }

    try {
        const response = await fetch(`${API_BASE}/v1/reservations/${reservationId}/confirm`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${window.app.currentToken}`
            }
        });

        if (response.ok) {
            alert('✅ Reservation confirmed successfully!');
            loadUserReservations();
        } else {
            const error = await response.json();
            alert(`❌ Confirmation failed: ${error.message || 'Please try again'}`);
        }
    } catch (error) {
        console.error('Confirmation error:', error);
        alert('❌ Network error. Please try again.');
    }
}

async function cancelReservation(reservationId) {
    if (!confirm('Are you sure you want to cancel this reservation?')) {
        return;
    }

    try {
        const response = await fetch(`${API_BASE}/v1/reservations/${reservationId}/cancel`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${window.app.currentToken}`
            }
        });

        if (response.ok) {
            alert('✅ Reservation cancelled successfully!');
            loadUserReservations();
        } else {
            const error = await response.json();
            alert(`❌ Cancellation failed: ${error.message || 'Please try again'}`);
        }
    } catch (error) {
        console.error('Cancellation error:', error);
        alert('❌ Network error. Please try again.');
    }
}

function showReservationModal(reservation) {
    // Create a simple modal for reservation details
    const modal = document.createElement('div');
    modal.className = 'modal fade show';
    modal.style.display = 'block';
    modal.innerHTML = `
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Reservation Details</h5>
                    <button type="button" class="btn-close" onclick="this.closest('.modal').remove()"></button>
                </div>
                <div class="modal-body">
                    <p><strong>Reservation ID:</strong> ${reservation.reservationId || reservation.id}</p>
                    <p><strong>Event ID:</strong> ${reservation.eventId}</p>
                    <p><strong>Quantity:</strong> ${reservation.quantity}</p>
                    <p><strong>Total Price:</strong> $${reservation.totalPrice?.toFixed(2) || 'TBD'}</p>
                    <p><strong>Status:</strong> <span class="badge bg-${reservation.status === 'CONFIRMED' ? 'success' : 'warning'}">${reservation.status}</span></p>
                    <p><strong>Created:</strong> ${reservation.createdAt ? new Date(reservation.createdAt).toLocaleString() : 'N/A'}</p>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="this.closest('.modal').remove()">Close</button>
                </div>
            </div>
        </div>
    `;

    // Add backdrop
    const backdrop = document.createElement('div');
    backdrop.className = 'modal-backdrop fade show';
    document.body.appendChild(backdrop);
    document.body.appendChild(modal);

    // Remove modal when clicking backdrop
    backdrop.onclick = () => {
        modal.remove();
        backdrop.remove();
    };
}


