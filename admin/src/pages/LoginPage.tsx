import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { api, setSession } from '../api';

export default function LoginPage() {
  const nav = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setBusy(true);
    try {
      const res = await api<{ token: string; user: any }>('/auth/login', {
        method: 'POST',
        body: { email, password },
      });
      if (res.user.role !== 'admin') {
        setError('Akun ini bukan admin. Gunakan akun dengan role admin.');
        setBusy(false);
        return;
      }
      setSession(res.token, res.user);
      nav('/');
    } catch (err: any) {
      setError(err.message || 'Login gagal');
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="login-page">
      <form className="login-card" onSubmit={submit}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <span className="brand-logo" style={{ background: 'rgba(255,255,255,0.2)' }}>
            M
          </span>
          <span style={{ color: '#fff', fontWeight: 800, fontSize: 18, letterSpacing: '-0.5px' }}>
            MAMO
          </span>
        </div>
        <h2 className="login-title">Admin Panel</h2>
        <p className="login-sub">Masuk untuk mengelola marketplace MAMO</p>

        {error && <div className="login-error">{error}</div>}

        <div className="field">
          <label>Email</label>
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="admin@mamo.id"
            required
          />
        </div>
        <div className="field">
          <label>Password</label>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="••••••••"
            required
          />
        </div>

        <button className="login-btn" disabled={busy}>
          {busy ? 'Memproses...' : 'Masuk'}
        </button>

        <p style={{ color: 'rgba(255,255,255,0.6)', fontSize: 11.5, marginTop: 16, textAlign: 'center' }}>
          Hanya akun dengan role admin yang dapat mengakses panel ini.
        </p>
      </form>
    </div>
  );
}
