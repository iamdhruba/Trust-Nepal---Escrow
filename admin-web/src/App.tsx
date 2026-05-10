import React, { useState } from 'react';
import './index.css';
import KycQueue from './pages/KycQueue';
import Disputes from './pages/Disputes';
import Vaults from './pages/Vaults';
import Users from './pages/Users';
import AuditLogs from './pages/AuditLogs';
import Dashboard from './pages/Dashboard';
import LoginPage from './pages/Login';

const NAV = [
  { id: 'dashboard', icon: '📊', label: 'Dashboard' },
  { id: 'kyc',       icon: '🪪', label: 'KYC Queue' },
  { id: 'vaults',    icon: '🔐', label: 'Vaults' },
  { id: 'disputes',  icon: '⚖️',  label: 'Disputes' },
  { id: 'users',     icon: '👥', label: 'Users' },
  { id: 'audit',     icon: '📋', label: 'Audit Logs' },
];

const API = import.meta.env.VITE_API_URL || 'http://localhost:3000/api/v1';

function App() {
  const [page, setPage] = useState('dashboard');
  const [token, setToken] = useState(() => localStorage.getItem('nt_admin_token') || '');

  if (!token) {
    return <LoginPage onLogin={setToken} />;
  }

  const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

  const pageMap: Record<string, React.ReactElement> = {
    dashboard: <Dashboard api={API} headers={headers} />,
    kyc:       <KycQueue api={API} headers={headers} />,
    vaults:    <Vaults api={API} headers={headers} />,
    disputes:  <Disputes api={API} headers={headers} />,
    users:     <Users api={API} headers={headers} />,
    audit:     <AuditLogs api={API} headers={headers} />,
  };

  const handleLogout = () => {
    localStorage.removeItem('nt_admin_token');
    setToken('');
  };

  return (
    <div className="layout">
      <aside className="sidebar">
        <div className="sidebar-logo">
          Trust Nepal
          <span>SECURITY COMMAND</span>
        </div>
        <nav className="sidebar-nav">
          {NAV.map(n => (
            <div
              key={n.id}
              className={`nav-item ${page === n.id ? 'active' : ''}`}
              onClick={() => setPage(n.id)}
            >
              <span className="nav-icon">{n.icon}</span>
              {n.label}
            </div>
          ))}
        </nav>
        <div className="sidebar-footer">
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
            <span style={{ fontSize: 16 }}>🛡️</span>
            <div style={{ fontWeight: 800, color: 'var(--primary)', fontSize: 10, letterSpacing: 1 }}>NRB REGULATED</div>
          </div>
          <div style={{ opacity: 0.7, lineHeight: 1.4, fontSize: 10 }}>
            System Version 1.2.5-PROD<br/>
            Secured Access Node
          </div>
        </div>
      </aside>

      <main className="main">
        <div className="topbar">
          <span className="topbar-title">{NAV.find(n => n.id === page)?.label}</span>
          <div className="topbar-right">
            <span className="badge badge-green">LIVE PROTOCOL</span>
            <span className="text-muted" style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1 }}>AUTH: ADMIN</span>
            <button 
              onClick={handleLogout}
              className="btn btn-outline btn-sm"
              style={{ color: '#ef4444', borderColor: 'rgba(239, 68, 68, 0.3)' }}
            >
              TERMINATE
            </button>
          </div>
        </div>
        <div className="page" key={page} style={{ animation: 'fadeIn 0.4s ease-out' }}>
          {pageMap[page]}
        </div>
      </main>
    </div>
  );
}

export default App;
