import React, { useState, useEffect } from 'react';

function App() {
  const [payments, setPayments] = useState([]);
  const [amount, setAmount] = useState('');
  const [currency, setCurrency] = useState('USD');
  const [status, setStatus] = useState('pending');
  const [message, setMessage] = useState('');

  const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:3000';

  useEffect(() => {
    fetchPayments();
  }, []);

  const fetchPayments = async () => {
    try {
      const res = await fetch(`${API_URL}/api/payments`);
      const data = await res.json();
      setPayments(data);
    } catch (err) {
      setMessage('Error fetching payments');
    }
  };

  const createPayment = async (e) => {
    e.preventDefault();
    try {
      const res = await fetch(`${API_URL}/api/payments`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ amount, currency, status }),
      });
      const data = await res.json();
      setMessage(`Payment created: ${data.id}`);
      fetchPayments();
    } catch (err) {
      setMessage('Error creating payment');
    }
  };

  return (
    <div style={styles.container}>

      {/* Header */}
      <h1 style={styles.header}>💳 Dodo Payments</h1>

      {/* Create Payment Form */}
      <div style={styles.card}>
        <h2>Create Payment</h2>
        <form onSubmit={createPayment}>
          <input
            style={styles.input}
            type="number"
            placeholder="Amount"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            required
          />
          <select
            style={styles.input}
            value={currency}
            onChange={(e) => setCurrency(e.target.value)}
          >
            <option value="USD">USD</option>
            <option value="EUR">EUR</option>
            <option value="INR">INR</option>
          </select>
          <select
            style={styles.input}
            value={status}
            onChange={(e) => setStatus(e.target.value)}
          >
            <option value="pending">Pending</option>
            <option value="completed">Completed</option>
            <option value="failed">Failed</option>
          </select>
          <button style={styles.button} type="submit">
            Create Payment
          </button>
        </form>
        {message && <p style={styles.message}>{message}</p>}
      </div>

      {/* Payments List */}
      <div style={styles.card}>
        <h2>All Payments</h2>
        {payments.length === 0 ? (
          <p>No payments found</p>
        ) : (
          <table style={styles.table}>
            <thead>
              <tr>
                <th>ID</th>
                <th>Amount</th>
                <th>Currency</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {payments.map((p) => (
                <tr key={p.id}>
                  <td>{p.id}</td>
                  <td>{p.amount}</td>
                  <td>{p.currency}</td>
                  <td>{p.status}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

    </div>
  );
}

const styles = {
  container: {
    maxWidth: '800px',
    margin: '0 auto',
    padding: '20px',
    fontFamily: 'Arial, sans-serif',
  },
  header: {
    textAlign: 'center',
    color: '#2E75B6',
  },
  card: {
    background: '#f9f9f9',
    borderRadius: '8px',
    padding: '20px',
    marginBottom: '20px',
    boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
  },
  input: {
    display: 'block',
    width: '100%',
    padding: '10px',
    marginBottom: '10px',
    borderRadius: '4px',
    border: '1px solid #ddd',
    fontSize: '14px',
  },
  button: {
    background: '#2E75B6',
    color: 'white',
    padding: '10px 20px',
    border: 'none',
    borderRadius: '4px',
    cursor: 'pointer',
    fontSize: '14px',
  },
  message: {
    color: 'green',
    marginTop: '10px',
  },
  table: {
    width: '100%',
    borderCollapse: 'collapse',
  },
};

export default App;
