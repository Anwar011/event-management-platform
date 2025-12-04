-- Create payment_intents table
CREATE TABLE payment_intents (
    id BIGSERIAL PRIMARY KEY,
    intent_id VARCHAR(255) NOT NULL UNIQUE,
    reservation_id VARCHAR(255) NOT NULL,
    user_id BIGINT NOT NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(3) DEFAULT 'USD',
    status VARCHAR(20) DEFAULT 'CREATED',
    idempotency_key VARCHAR(255) UNIQUE,
    payment_method VARCHAR(50) DEFAULT 'CARD',
    description TEXT,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create payments table
CREATE TABLE payments (
    id BIGSERIAL PRIMARY KEY,
    payment_id VARCHAR(255) NOT NULL UNIQUE,
    intent_id BIGINT NOT NULL REFERENCES payment_intents(id),
    reservation_id VARCHAR(255) NOT NULL,
    user_id BIGINT NOT NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(3) DEFAULT 'USD',
    status VARCHAR(20) DEFAULT 'PENDING',
    payment_method VARCHAR(50) DEFAULT 'CARD',
    provider_reference VARCHAR(255),
    failure_reason TEXT,
    captured_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_payment_intents_reservation_id ON payment_intents(reservation_id);
CREATE INDEX idx_payment_intents_user_id ON payment_intents(user_id);
CREATE INDEX idx_payment_intents_status ON payment_intents(status);
CREATE INDEX idx_payment_intents_idempotency_key ON payment_intents(idempotency_key);
CREATE INDEX idx_payment_intents_expires_at ON payment_intents(expires_at);

CREATE INDEX idx_payments_intent_id ON payments(intent_id);
CREATE INDEX idx_payments_reservation_id ON payments(reservation_id);
CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_provider_reference ON payments(provider_reference);

-- Insert sample data for testing
INSERT INTO payment_intents (intent_id, reservation_id, user_id, amount, status, payment_method, description, expires_at)
VALUES
    ('PI-001', 'RES-001', 1, 199.98, 'COMPLETED', 'CARD', 'Payment for Spring Boot Workshop', NOW() + INTERVAL '1 hour'),
    ('PI-002', 'RES-002', 2, 299.99, 'PENDING', 'CARD', 'Payment for React Conference', NOW() + INTERVAL '1 hour');

INSERT INTO payments (payment_id, intent_id, reservation_id, user_id, amount, status, payment_method, provider_reference, captured_at)
SELECT
    'PAY-001',
    pi.id,
    pi.reservation_id,
    pi.user_id,
    pi.amount,
    'COMPLETED',
    pi.payment_method,
    'txn_' || pi.intent_id,
    NOW()
FROM payment_intents pi WHERE pi.intent_id = 'PI-001';



