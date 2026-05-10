import { useState } from 'react';

const API = import.meta.env.VITE_API_URL || 'http://localhost:3000/api/v1';

interface Props {
  onLogin: (token: string) => void;
}

export default function LoginPage({ onLogin }: Props) {
  const [phone, setPhone] = useState('');
  const [otp, setOtp] = useState('');
  const [step, setStep] = useState<'phone' | 'otp'>('phone');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const sendOtp = async () => {
    if (!phone.match(/^9[78]\d{8}$/)) {
      setError('Enter a valid Nepal phone number (e.g. 9800000000)');
      return;
    }
    setLoading(true);
    setError('');
    try {
      const res = await fetch(`${API}/auth/otp/send`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone }),
      });
      if (!res.ok) throw new Error((await res.json()).message || 'Failed to send OTP');
      setStep('otp');
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };

  const verifyOtp = async () => {
    if (otp.length !== 6) { setError('Enter the 6-digit OTP'); return; }
    setLoading(true);
    setError('');
    try {
      const res = await fetch(`${API}/auth/otp/verify`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
          phone, 
          otp,
          deviceId: 'admin-web-console',
          fingerprint: 'browser-admin-secure-v1'
        }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.message || 'Invalid OTP');

      // Check the user has ADMIN role
      const payload = JSON.parse(atob(data.data.accessToken.split('.')[1]));
      if (!payload.roles?.includes('ADMIN')) {
        throw new Error('Access denied: Admin privileges required');
      }

      localStorage.setItem('nt_admin_token', data.data.accessToken);
      onLogin(data.data.accessToken);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{
      minHeight: '100vh',
      background: '#F8F9FF',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: "'Public Sans', sans-serif",
      padding: 20
    }}>
      <div style={{
        width: '100%', maxWidth: 440,
        padding: '0 20px'
      }}>
        {/* Shield Icon */}
        <div style={{
          width: 56, height: 56, borderRadius: 12,
          background: 'rgba(5, 150, 105, 0.1)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          marginBottom: 32
        }}>
          <span style={{ fontSize: 28 }}>🛡️</span>
        </div>

        {/* Heading */}
        <h1 style={{
          color: '#0F172A', fontSize: 32, fontWeight: 800,
          letterSpacing: '-1px', marginBottom: 12, textAlign: 'left'
        }}>
          {step === 'phone' ? 'Institutional Access' : 'Verification Code'}
        </h1>
        <p style={{
          color: '#45464D', fontSize: 16, lineHeight: 1.5,
          marginBottom: 48, textAlign: 'left'
        }}>
          {step === 'phone' 
            ? "Secure your transactions with Nepal's first institutional escrow platform."
            : `Enter the 6-digit security code sent to +977 ${phone}`}
        </p>

        {error && (
          <div style={{
            background: '#FFF1F2',
            border: '1px solid #FECDD3',
            borderRadius: 12, padding: '14px 20px',
            color: '#BA1A1A', fontSize: 13, marginBottom: 32,
            fontWeight: 600
          }}>⚠️ {error}</div>
        )}

        {step === 'phone' ? (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 32 }}>
            <div>
              <label style={{ 
                color: '#45464D', fontSize: 11, fontWeight: 800, 
                letterSpacing: 1, display: 'block', marginBottom: 10 
              }}>
                REGISTERED PHONE NUMBER
              </label>
              <div style={{
                display: 'flex', alignItems: 'center',
                background: '#FFFFFF', border: '1px solid #C6C6CD',
                borderRadius: 12, overflow: 'hidden',
                transition: 'border-color 0.2s'
              }}>
                <span style={{
                  padding: '0 20px', color: '#0F172A', fontSize: 18, fontWeight: 700,
                  borderRight: '1px solid #E5E7EB', height: '60px', display: 'flex',
                  alignItems: 'center'
                }}>+977</span>
                <input
                  type="tel" maxLength={10} value={phone}
                  onChange={e => setPhone(e.target.value.replace(/\D/g, ''))}
                  onKeyDown={e => e.key === 'Enter' && sendOtp()}
                  placeholder="98XXXXXXXX"
                  style={{
                    flex: 1, background: 'transparent', border: 'none', outline: 'none',
                    color: '#0F172A', fontSize: 18, padding: '0 20px', height: '60px',
                    fontWeight: 600
                  }}
                />
              </div>
            </div>
            <button
              onClick={sendOtp}
              disabled={loading || phone.length !== 10}
              style={{
                width: '100%', height: 60, borderRadius: 12, border: 'none',
                background: loading || phone.length !== 10 ? '#C6C6CD' : '#0F172A',
                color: '#FFFFFF',
                fontSize: 16, fontWeight: 800, cursor: phone.length === 10 ? 'pointer' : 'not-allowed',
                transition: 'all 0.2s',
                boxShadow: phone.length === 10 ? '0 4px 12px rgba(15, 23, 42, 0.2)' : 'none'
              }}
            >
              {loading ? 'Processing…' : 'Get Security Code'}
            </button>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 32 }}>
            <div>
              <label style={{ 
                color: '#45464D', fontSize: 11, fontWeight: 800, 
                letterSpacing: 1, display: 'block', marginBottom: 10 
              }}>
                SECURE OTP
              </label>
              <input
                type="text" maxLength={6} value={otp}
                onChange={e => setOtp(e.target.value.replace(/\D/g, ''))}
                onKeyDown={e => e.key === 'Enter' && verifyOtp()}
                placeholder="● ● ● ● ● ●"
                style={{
                  width: '100%',
                  background: '#FFFFFF', border: '1px solid #C6C6CD', borderRadius: 12,
                  color: '#0F172A', fontSize: 28, fontWeight: 800, textAlign: 'center',
                  padding: '16px', outline: 'none', letterSpacing: 12, boxSizing: 'border-box',
                  height: 72
                }}
                autoFocus
              />
              <button
                onClick={() => { setStep('phone'); setOtp(''); setError(''); }}
                style={{
                  marginTop: 20, background: 'transparent', border: 'none',
                  color: '#059669', cursor: 'pointer', fontSize: 14, fontWeight: 700,
                  width: '100%', textAlign: 'center'
                }}
              >Change phone number</button>
            </div>
            <button
              onClick={verifyOtp}
              disabled={loading || otp.length !== 6}
              style={{
                width: '100%', height: 60, borderRadius: 12, border: 'none',
                background: loading || otp.length !== 6 ? '#C6C6CD' : '#0F172A',
                color: '#FFFFFF',
                fontSize: 16, fontWeight: 800,
                cursor: otp.length === 6 ? 'pointer' : 'not-allowed', transition: 'all 0.2s',
              }}
            >
              {loading ? 'Authenticating…' : 'Authenticate'}
            </button>
          </div>
        )}

        <div style={{
          marginTop: 100, textAlign: 'center'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, marginBottom: 12 }}>
            <span style={{ fontSize: 16 }}>🛡️</span>
            <div style={{ fontWeight: 800, color: '#45464D', fontSize: 11, letterSpacing: 1.5 }}>
              NRB REGULATED ENTITY
            </div>
          </div>
          <div style={{ color: '#94a3b8', fontSize: 12, fontWeight: 500 }}>
            Secured by banking-grade encryption
          </div>
        </div>
      </div>
    </div>
  );
}
