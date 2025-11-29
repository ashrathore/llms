-- Create logs schema
CREATE SCHEMA IF NOT EXISTS logs;

-- Set default search path for admin user to include logs schema
ALTER USER admin SET search_path TO logs, public;

-- Create logs table with correlation_id as primary key
CREATE TABLE logs.api_logs (
    correlation_id UUID PRIMARY KEY,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    service_name VARCHAR(100) NOT NULL,
    endpoint VARCHAR(255) NOT NULL,
    method VARCHAR(10) NOT NULL,
    status_code INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('SUCCESS', 'ERROR', 'WARNING')),
    request_payload JSONB,
    response_payload JSONB,
    error_message TEXT,
    duration_ms INTEGER,
    user_id VARCHAR(100),
    ip_address INET,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX idx_logs_timestamp ON logs.api_logs(timestamp);
CREATE INDEX idx_logs_status ON logs.api_logs(status);
CREATE INDEX idx_logs_service ON logs.api_logs(service_name);

-- Insert sample SUCCESS calls
INSERT INTO logs.api_logs (correlation_id, service_name, endpoint, method, status_code, status, request_payload, response_payload, duration_ms, user_id, ip_address) VALUES
('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'user-service', '/api/v1/users/123', 'GET', 200, 'SUCCESS', 
 '{"user_id": "123"}', '{"id": "123", "name": "John Doe", "email": "john@example.com"}', 45, 'user_001', '192.168.1.100'),

('b2c3d4e5-f6a7-8901-bcde-f12345678901', 'order-service', '/api/v1/orders', 'POST', 201, 'SUCCESS',
 '{"product_id": "PRD-001", "quantity": 2, "user_id": "123"}', '{"order_id": "ORD-12345", "status": "created", "total": 99.99}', 120, 'user_001', '192.168.1.100'),

('c3d4e5f6-a7b8-9012-cdef-123456789012', 'payment-service', '/api/v1/payments/process', 'POST', 200, 'SUCCESS',
 '{"order_id": "ORD-12345", "amount": 99.99, "method": "credit_card"}', '{"transaction_id": "TXN-98765", "status": "completed"}', 350, 'user_001', '192.168.1.100'),

('d4e5f6a7-b8c9-0123-defa-234567890123', 'notification-service', '/api/v1/notifications/send', 'POST', 200, 'SUCCESS',
 '{"user_id": "123", "type": "email", "template": "order_confirmation"}', '{"notification_id": "NOT-11111", "delivered": true}', 80, 'system', '10.0.0.1'),

('e5f6a7b8-c9d0-1234-efab-345678901234', 'inventory-service', '/api/v1/inventory/check', 'GET', 200, 'SUCCESS',
 '{"product_id": "PRD-001"}', '{"product_id": "PRD-001", "available": 150, "reserved": 10}', 25, 'user_002', '192.168.1.101');

-- Insert sample ERROR calls
INSERT INTO logs.api_logs (correlation_id, service_name, endpoint, method, status_code, status, request_payload, response_payload, error_message, duration_ms, user_id, ip_address) VALUES
('f6a7b8c9-d0e1-2345-fabc-456789012345', 'user-service', '/api/v1/users/999', 'GET', 404, 'ERROR',
 '{"user_id": "999"}', '{"error": "Not Found"}', 'User with ID 999 not found in database', 15, 'user_003', '192.168.1.102'),

('a7b8c9d0-e1f2-3456-abcd-567890123456', 'order-service', '/api/v1/orders', 'POST', 400, 'ERROR',
 '{"product_id": "PRD-999", "quantity": -5}', '{"error": "Bad Request"}', 'Invalid quantity: must be a positive integer', 8, 'user_001', '192.168.1.100'),

('b8c9d0e1-f2a3-4567-bcde-678901234567', 'payment-service', '/api/v1/payments/process', 'POST', 402, 'ERROR',
 '{"order_id": "ORD-99999", "amount": 5000.00, "method": "credit_card"}', '{"error": "Payment Required"}', 'Insufficient funds on card ending in 4242', 500, 'user_004', '192.168.1.103'),

('c9d0e1f2-a3b4-5678-cdef-789012345678', 'auth-service', '/api/v1/auth/login', 'POST', 401, 'ERROR',
 '{"email": "hacker@evil.com", "password": "***"}', '{"error": "Unauthorized"}', 'Invalid credentials - account locked after 5 failed attempts', 200, NULL, '203.0.113.50'),

('d0e1f2a3-b4c5-6789-defa-890123456789', 'inventory-service', '/api/v1/inventory/update', 'PUT', 500, 'ERROR',
 '{"product_id": "PRD-001", "quantity": 100}', '{"error": "Internal Server Error"}', 'Database connection timeout after 30000ms', 30000, 'system', '10.0.0.1');

-- Insert sample WARNING calls
INSERT INTO logs.api_logs (correlation_id, service_name, endpoint, method, status_code, status, request_payload, response_payload, error_message, duration_ms, user_id, ip_address) VALUES
('e1f2a3b4-c5d6-7890-efab-901234567890', 'rate-limiter', '/api/v1/users/123', 'GET', 429, 'WARNING',
 '{"user_id": "123"}', '{"error": "Too Many Requests", "retry_after": 60}', 'Rate limit exceeded: 100 requests per minute', 5, 'user_001', '192.168.1.100'),

('f2a3b4c5-d6e7-8901-fabc-012345678901', 'cache-service', '/api/v1/products/list', 'GET', 200, 'WARNING',
 '{"category": "electronics"}', '{"products": [...], "cache_status": "stale"}', 'Cache miss - data fetched from primary database, response time degraded', 2500, 'user_005', '192.168.1.104');

-- Verify data
SELECT status, COUNT(*) as count FROM logs.api_logs GROUP BY status ORDER BY status;

