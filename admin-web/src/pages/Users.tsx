import { useEffect, useState } from 'react';

interface Props { api: string; headers: Record<string, string>; }
interface User { _id: string; phone: string; name: string; kycStatus: string; createdAt: string; }

export default function Users({ api, headers }: Props) {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    setLoading(true);
    fetch(`${api}/admin/users?limit=100`, { headers })
      .then(r => r.json()).then(d => { setUsers(d.data || []); setLoading(false); });
  }, []);

  const filtered = users.filter(u => 
    !search || u.phone.includes(search) || (u.name && u.name.toLowerCase().includes(search.toLowerCase()))
  );

  const kycBadge = (s: string) => {
    const map: Record<string, string> = { APPROVED: 'badge-green', PENDING: 'badge-yellow', REJECTED: 'badge-red', NOT_SUBMITTED: 'badge-gray' };
    return map[s] || 'badge-gray';
  };

  return (
    <div>
      <div className="section-header">
        <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
          <h2>Authorized Clients</h2>
          <p className="text-muted">Database of all platform participants and their compliance status</p>
        </div>
        <div style={{ width: 300 }}>
          <input className="input" placeholder="Search by name or phone..." value={search} onChange={e => setSearch(e.target.value)} />
        </div>
      </div>

      {loading ? <div className="text-muted" style={{ padding: 40, textAlign: 'center' }}>Accessing user records...</div> : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>CLIENT NAME</th>
                <th>PHONE NUMBER</th>
                <th>KYC PROTOCOL</th>
                <th>JOINED</th>
                <th>SYSTEM ID</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 && <tr><td colSpan={5} style={{ textAlign: 'center', color: 'var(--text-muted)', padding: 64 }}>No clients found matching the query.</td></tr>}
              {filtered.map(u => (
                <tr key={u._id}>
                  <td style={{ fontWeight: 800, color: 'var(--primary)' }}>{u.name || 'ANONYMOUS'}</td>
                  <td>{u.phone}</td>
                  <td><span className={`badge ${kycBadge(u.kycStatus)}`}>{u.kycStatus}</span></td>
                  <td className="text-muted">{new Date(u.createdAt).toLocaleDateString()}</td>
                  <td className="monospace">{u._id.slice(-8).toUpperCase()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
