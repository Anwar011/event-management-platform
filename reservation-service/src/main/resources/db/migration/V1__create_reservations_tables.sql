-- Create reservations table
CREATE TABLE reservations (
    id BIGSERIAL PRIMARY KEY,
    reservation_id VARCHAR(255) NOT NULL UNIQUE, -- For idempotency
    user_id BIGINT NOT NULL,
    event_id BIGINT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    total_price DECIMAL(10,2) NOT NULL CHECK (total_price >= 0),
    status VARCHAR(20) DEFAULT 'PENDING',
    idempotency_key VARCHAR(255) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create reservation_items table (for future extensibility)
CREATE TABLE reservation_items (
    id BIGSERIAL PRIMARY KEY,
    reservation_id BIGINT NOT NULL REFERENCES reservations(id) ON DELETE CASCADE,
    ticket_type VARCHAR(50) DEFAULT 'STANDARD',
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_reservations_user_id ON reservations(user_id);
CREATE INDEX idx_reservations_event_id ON reservations(event_id);
CREATE INDEX idx_reservations_status ON reservations(status);
CREATE INDEX idx_reservations_idempotency_key ON reservations(idempotency_key);
CREATE INDEX idx_reservations_reservation_id ON reservations(reservation_id);
CREATE INDEX idx_reservation_items_reservation_id ON reservation_items(reservation_id);

-- Insert sample reservation for testing
INSERT INTO reservations (reservation_id, user_id, event_id, quantity, total_price, status, idempotency_key)
VALUES
    ('RES-001', 1, 1, 2, 199.98, 'CONFIRMED', 'idempotent-key-1'),
    ('RES-002', 2, 2, 1, 299.99, 'PENDING', 'idempotent-key-2');

-- Insert corresponding reservation items
INSERT INTO reservation_items (reservation_id, ticket_type, quantity, unit_price)
SELECT r.id, 'STANDARD', r.quantity, r.total_price/r.quantity
FROM reservations r;





