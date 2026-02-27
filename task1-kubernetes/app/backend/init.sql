-- Create payments table
CREATE TABLE IF NOT EXISTS payments (
  id        SERIAL PRIMARY KEY,
  amount    DECIMAL(10,2) NOT NULL,
  currency  VARCHAR(10)   NOT NULL,
  status    VARCHAR(20)   NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO payments (amount, currency, status) VALUES
  (100.00, 'USD', 'completed'),
  (250.50, 'EUR', 'pending'),
  (75.00,  'INR', 'completed');