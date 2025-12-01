// Events management functions
// Handle event listing, searching, and booking

const API_BASE = 'http://localhost:8080';

async function loadEvents() {
    const container = document.getElementById('eventsContainer');
    container.innerHTML = `
        <div class="loading">
            <div class="spinner"></div>
            <p>Loading events...</p>
        </div>
    `;

    try {
        // Try to load events from the API
        const response = await fetch(`${API_BASE}/v1/events`);

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        const data = await response.json();

        // Handle different response formats
        let events = [];
        if (data.content && Array.isArray(data.content)) {
            events = data.content;
        } else if (Array.isArray(data)) {
            events = data;
        } else if (data && typeof data === 'object') {
            events = [data]; // Single event
        }

        displayEvents(events);
    } catch (error) {
        console.error('Error loading events:', error);
        // Show demo events if API fails
        displayDemoEvents();
    }
}

function displayEvents(events) {
    const container = document.getElementById('eventsContainer');

    if (!events || events.length === 0) {
        container.innerHTML = `
            <div class="text-center py-5">
                <i class="fas fa-calendar-times fa-3x text-muted mb-3"></i>
                <h4>No events found</h4>
                <p class="text-muted">Check back later for upcoming events</p>
            </div>
        `;
        return;
    }

    container.innerHTML = `
        <div class="row" id="eventsGrid">
            ${events.map(event => createEventCard(event)).join('')}
        </div>
    `;
}

function createEventCard(event) {
    const eventDate = event.startDate ? new Date(event.startDate).toLocaleDateString() : 'TBD';
    const eventType = event.eventType || 'EVENT';
    const eventTitle = event.title || 'Untitled Event';
    const eventDescription = event.description || 'No description available';
    const eventId = event.id || Math.random();

    return `
        <div class="col-lg-4 col-md-6 mb-4">
            <div class="event-card">
                <div style="height: 200px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); display: flex; align-items: center; justify-content: center; color: white;">
                    <div class="text-center">
                        <i class="fas fa-calendar-alt fa-3x mb-2"></i>
                        <h5>${eventType}</h5>
                    </div>
                </div>
                <div class="event-card-body">
                    <h5 class="event-card-title">${eventTitle}</h5>
                    <p class="event-card-text">${eventDescription.substring(0, 100)}...</p>
                    <div class="d-flex justify-content-between align-items-center">
                        <small class="text-muted">
                            <i class="fas fa-calendar"></i> ${eventDate}
                        </small>
                        <span class="badge bg-primary">${eventType}</span>
                    </div>
                    <div class="mt-3">
                        <button class="btn btn-primary btn-sm me-2" onclick="viewEventDetails(${eventId})">
                            <i class="fas fa-eye"></i> View Details
                        </button>
                        <button class="btn btn-success btn-sm" onclick="bookEvent(${eventId})">
                            <i class="fas fa-ticket-alt"></i> Book Now
                        </button>
                    </div>
                </div>
            </div>
        </div>
    `;
}

function displayDemoEvents() {
    const demoEvents = [
        {
            id: 1,
            title: "Spring Boot Conference 2025",
            description: "Join us for the ultimate Spring Boot conference featuring expert speakers, hands-on workshops, and networking opportunities.",
            eventType: "CONFERENCE",
            startDate: "2025-12-25T10:00:00",
            capacity: 500,
            price: 299.99
        },
        {
            id: 2,
            title: "React Advanced Workshop",
            description: "Master advanced React concepts including hooks, context, performance optimization, and modern development practices.",
            eventType: "WORKSHOP",
            startDate: "2025-11-15T09:00:00",
            capacity: 50,
            price: 149.99
        },
        {
            id: 3,
            title: "DevOps Summit 2025",
            description: "Explore the latest in DevOps practices, CI/CD pipelines, container orchestration, and cloud-native architectures.",
            eventType: "CONFERENCE",
            startDate: "2025-10-20T08:30:00",
            capacity: 300,
            price: 199.99
        }
    ];

    displayEvents(demoEvents);
}

function filterEvents() {
    const searchTerm = document.getElementById('searchInput').value.toLowerCase();
    const categoryFilter = document.getElementById('categoryFilter').value;

    const eventCards = document.querySelectorAll('.event-card');

    eventCards.forEach(card => {
        const title = card.querySelector('.event-card-title').textContent.toLowerCase();
        const description = card.querySelector('.event-card-text').textContent.toLowerCase();
        const type = card.querySelector('.badge').textContent;

        const matchesSearch = title.includes(searchTerm) || description.includes(searchTerm);
        const matchesCategory = !categoryFilter || type === categoryFilter;

        card.parentElement.style.display = (matchesSearch && matchesCategory) ? 'block' : 'none';
    });
}

async function viewEventDetails(eventId) {
    try {
        const response = await fetch(`${API_BASE}/v1/events/${eventId}`);
        if (response.ok) {
            const event = await response.json();
            showEventModal(event);
        } else {
            // Try demo event
            const demoEvent = getDemoEvent(eventId);
            if (demoEvent) {
                showEventModal(demoEvent);
            } else {
                alert('Event not found');
            }
        }
    } catch (error) {
        console.error('Error loading event details:', error);
        const demoEvent = getDemoEvent(eventId);
        if (demoEvent) {
            showEventModal(demoEvent);
        } else {
            alert('Error loading event details');
        }
    }
}

function getDemoEvent(eventId) {
    const demoEvents = [
        {
            id: 1,
            title: "Spring Boot Conference 2025",
            description: "Join us for the ultimate Spring Boot conference featuring expert speakers, hands-on workshops, and networking opportunities. This comprehensive event covers all aspects of Spring Boot development from basics to advanced topics.",
            eventType: "CONFERENCE",
            startDate: "2025-12-25T10:00:00",
            capacity: 500,
            price: 299.99,
            venue: "Convention Center",
            address: "123 Main St, Tech City",
            organizerId: 1
        },
        {
            id: 2,
            title: "React Advanced Workshop",
            description: "Master advanced React concepts including hooks, context, performance optimization, and modern development practices. Perfect for developers looking to take their React skills to the next level.",
            eventType: "WORKSHOP",
            startDate: "2025-11-15T09:00:00",
            capacity: 50,
            price: 149.99,
            venue: "Tech Hub",
            address: "456 Innovation Ave, Dev Town",
            organizerId: 1
        },
        {
            id: 3,
            title: "DevOps Summit 2025",
            description: "Explore the latest in DevOps practices, CI/CD pipelines, container orchestration, and cloud-native architectures. Learn from industry experts about modern deployment strategies.",
            eventType: "CONFERENCE",
            startDate: "2025-10-20T08:30:00",
            capacity: 300,
            price: 199.99,
            venue: "Tech Arena",
            address: "789 Progress Blvd, Cloud City",
            organizerId: 1
        }
    ];

    return demoEvents.find(event => event.id === eventId);
}

function showEventModal(event) {
    const modal = document.getElementById('eventModal');
    const eventDetails = document.getElementById('eventDetails');

    const eventDate = event.startDate ? new Date(event.startDate).toLocaleDateString('en-US', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    }) : 'Date TBD';

    const eventTime = event.startDate ? new Date(event.startDate).toLocaleTimeString('en-US', {
        hour: '2-digit',
        minute: '2-digit'
    }) : 'Time TBD';

    eventDetails.innerHTML = `
        <div class="row">
            <div class="col-md-8">
                <h2>${event.title}</h2>
                <div class="mb-3">
                    <span class="badge bg-primary me-2">${event.eventType}</span>
                    <small class="text-muted">
                        <i class="fas fa-calendar"></i> ${eventDate} at ${eventTime}
                    </small>
                </div>
                <p class="lead">${event.description}</p>

                <div class="row mt-4">
                    <div class="col-sm-6">
                        <h5><i class="fas fa-map-marker-alt"></i> Venue</h5>
                        <p>${event.venue || 'TBD'}</p>
                        <p class="text-muted">${event.address || 'Address TBD'}</p>
                    </div>
                    <div class="col-sm-6">
                        <h5><i class="fas fa-users"></i> Capacity</h5>
                        <p>${event.capacity || 'TBD'} attendees</p>
                        <h5 class="mt-3"><i class="fas fa-dollar-sign"></i> Price</h5>
                        <p class="text-success fw-bold">$${event.price || 'TBD'}</p>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card">
                    <div class="card-body text-center">
                        <h4>Ready to Book?</h4>
                        <p>Get your tickets now!</p>
                        <button class="btn btn-success btn-lg w-100" onclick="bookEvent(${event.id})">
                            <i class="fas fa-ticket-alt"></i> Book Now
                        </button>
                    </div>
                </div>
            </div>
        </div>
    `;

    modal.style.display = 'block';
}

function closeModal() {
    document.getElementById('eventModal').style.display = 'none';
}

async function bookEvent(eventId) {
    if (!window.app || !window.app.currentToken) {
        alert('Please login to book tickets');
        window.app.showPage('login');
        return;
    }

    const quantity = prompt('How many tickets would you like to book?', '1');
    if (!quantity || quantity < 1) return;

    try {
        const response = await fetch(`${API_BASE}/v1/reservations`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${window.app.currentToken}`
            },
            body: JSON.stringify({
                userId: window.app.currentUser.id,
                eventId: eventId,
                quantity: parseInt(quantity),
                idempotencyKey: `book-${eventId}-${Date.now()}`
            })
        });

        if (response.ok) {
            const result = await response.json();
            alert(`✅ Booking successful! Reservation ID: ${result.reservationId || result.id}`);
            closeModal();
            window.app.showPage('dashboard');
        } else {
            const error = await response.json();
            alert(`❌ Booking failed: ${error.message || 'Please try again'}`);
        }
    } catch (error) {
        console.error('Booking error:', error);
        alert('❌ Network error. Please try again.');
    }
}

// Close modal when clicking outside
window.onclick = function(event) {
    const modal = document.getElementById('eventModal');
    if (event.target === modal) {
        modal.style.display = 'none';
    }
};


