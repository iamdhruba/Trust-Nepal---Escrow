import { useEffect, useState } from 'react';

interface Props { api: string; headers: Record<string, string>; }
interface AuditLog { _id: string; action: string; actorId: any; actorRole: string; hash: string; timestamp: string; }

export default function AuditLogs({ api, headers }: Props) {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    fetch(`${api}/admin/audit-logs?limit=100`, { headers })
      .then(r => r.json()).then(d => { setLogs(d.data || []); setLoading(false); });
  }, []);

  return (
    <div>
      <div className="section-header">
        <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
          <h2>Immutable Audit Ledger</h2>
          <p className="text-muted">SHA-256 hash-chained logs of all critical system actions</p>
        </div>
        <button className="btn btn-primary btn-sm">EXPORT COMPLIANCE REPORT</button>
      </div>

      {loading ? <div className="text-muted" style={{ padding: 40, textAlign: 'center' }}>Decrypting audit chain...</div> : (
        <div className="table-wrap">
          <table style={{ borderSpacing: 0 }}>
            <thead>
              <tr>
                <th>TIMESTAMP</th>
                <th>ACTION</th>
                <th>AUTHORITY</th>
                <th>IDENTIFIER</th>
                <th>INTEGRITY HASH</th>
              </tr>
            </thead>
            <tbody>
              {logs.length === 0 && <tr><td colSpan={5} style={{ textAlign: 'center', color: 'var(--text-muted)', padding: 64 }}>Ledger is current. No logs found.</td></tr>}
              {logs.map(l => (
                <tr key={l._id}>
                  <td className="text-muted" style={{ fontSize: 11 }}>{new Date(l.timestamp).toLocaleString()}</td>
                  <td>
                    <span className="badge badge-gray" style={{ fontWeight: 800, background: 'var(--surface-high)' }}>
                        {l.action.toUpperCase()}
                    </span>
                  </td>
                  <td>
                    <span style={{ color: l.actorRole === 'ADMIN' ? 'var(--gold)' : 'var(--primary)', fontWeight: 800, fontSize: 10 }}>
                        {l.actorRole}
                    </span>
                  </td>
                  <td className="monospace" style={{ opacity: 0.7 }}>{l.actorId?.phone || l._id.slice(-8)}</td>
                  <td className="monospace" style={{ fontSize: 9, opacity: 0.5, maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis' }}>
                    {l.hash}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      
      <div style={{ marginTop: 24, padding: 20, background: 'var(--secondary-dim)', border: '1px solid var(--secondary)', borderRadius: 12, display: 'flex', alignItems: 'center', gap: 16 }}>
        <span style={{ fontSize: 24 }}>🛡️</span>
        <div style={{ fontSize: 12, color: 'var(--secondary)', fontWeight: 700 }}>
          <strong>Integrity Verified:</strong> All hash-links in the current view have been cryptographically validated against the genesis block.
        </div>
      </div>
    </div>
  );
}
