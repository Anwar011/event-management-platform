-- Create users table with VARCHAR role column (simpler and more flexible)
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    role VARCHAR(50) NOT NULL DEFAULT 'ROLE_USER',
    status VARCHAR(20) DEFAULT 'ACTIVE'
);

-- Create indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);

-- Insert default admin user
INSERT INTO users (email, password_hash, first_name, last_name, role, status)
VALUES ('admin@eventplatform.com', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iwy7p8K5O', 'Admin', 'User', 'ROLE_ADMIN', 'ACTIVE');