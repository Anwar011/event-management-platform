-- Create events table
CREATE TABLE events (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    event_type VARCHAR(50) NOT NULL,
    venue VARCHAR(255),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP,
    capacity INTEGER NOT NULL CHECK (capacity > 0),
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    organizer_id BIGINT NOT NULL,
    status VARCHAR(20) DEFAULT 'DRAFT',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create event capacity tracking table
CREATE TABLE event_capacity (
    event_id BIGINT PRIMARY KEY REFERENCES events(id) ON DELETE CASCADE,
    total_capacity INTEGER NOT NULL,
    reserved_capacity INTEGER DEFAULT 0,
    available_capacity INTEGER GENERATED ALWAYS AS (total_capacity - reserved_capacity) STORED
);

-- Create indexes for performance
CREATE INDEX idx_events_organizer_id ON events(organizer_id);
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_events_start_date ON events(start_date);
CREATE INDEX idx_events_event_type ON events(event_type);
CREATE INDEX idx_events_city ON events(city);

-- Insert sample events for testing
INSERT INTO events (title, description, event_type, venue, address, city, state, country, start_date, capacity, price, organizer_id, status)
VALUES
    ('Spring Boot Workshop', 'Learn Spring Boot from basics to advanced topics', 'WORKSHOP', 'Tech Hub', '123 Tech Street', 'San Francisco', 'CA', 'USA', '2024-12-01 10:00:00', 50, 99.99, 1, 'PUBLISHED'),
    ('React Conference 2024', 'Annual React developer conference', 'CONFERENCE', 'Convention Center', '456 Main St', 'New York', 'NY', 'USA', '2024-11-15 09:00:00', 500, 299.99, 1, 'PUBLISHED'),
    ('Docker & Kubernetes Meetup', 'Monthly meetup for container enthusiasts', 'MEETUP', 'Co-working Space', '789 Startup Ave', 'Austin', 'TX', 'USA', '2024-10-20 18:30:00', 100, 0.00, 2, 'PUBLISHED');

-- Initialize capacity tracking for the sample events
INSERT INTO event_capacity (event_id, total_capacity, reserved_capacity)
SELECT id, capacity, 0 FROM events;


