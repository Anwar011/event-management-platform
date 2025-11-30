-- Create roles enum
CREATE TYPE user_role AS ENUM ('ROLE_USER', 'ROLE_ADMIN');

-- Create users table
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create user_roles table
CREATE TABLE user_roles (
    user_id BIGINT NOT NULL,
    role user_role NOT NULL,
    PRIMARY KEY (user_id, role),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);

-- Insert default admin user (password: admin123)
-- Password hash for 'admin123' using BCrypt
INSERT INTO users (email, password_hash, first_name, last_name, status)
VALUES ('admin@eventplatform.com', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iwy7p8K5O', 'Admin', 'User', 'ACTIVE');

INSERT INTO user_roles (user_id, role)
VALUES (1, 'ROLE_ADMIN');

