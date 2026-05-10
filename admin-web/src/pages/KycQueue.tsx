import { useEffect, useState } from 'react';

interface Props { api: string; headers: Record<string, string>; }
interface KycUser { _id: string; phone: string; kyc: { status: string; submittedAt: string; idType?: string; fullName?: string; idNumber?: string; }; }

export default function KycQueue({ api, headers }: Props) {
  const [users, setUsers] = useState<KycUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<KycUser | null>(null);
  const [reason, setReason] = useState('');

  useEffect(() => { fetchQueue(); }, []);

  const fetchQueue = async () => {
    setLoading(true);
    try {
      const r = await fetch(`${api}/admin/kyc/queue`, { headers });
      const d = await r.json();
      setUsers(d.data || []);
    } catch { setUsers([]); }
    setLoading(false);
  };

  const decide = async (userId: string, status: 'APPROVED' | 'REJECTED') => {
    if (status === 'REJECTED' && !reason) {
      alert('Please provide a reason for rejection.');
      return;
    }
    await fetch(`${api}/admin/kyc/${userId}`, {
      method: 'PUT', headers,
      body: JSON.stringify({ status, reason: reason || undefined }),
    });
    setSelected(null); setReason('');
    fetchQueue();
  };

  return (
    <div>
      <div className="section-header">
        <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
          <h2>Identity Audit Queue</h2>
          <p className="text-muted">High-priority KYC verifications pending review</p>
        </div>
        <button className="btn btn-outline btn-sm" onClick={fetchQueue}>🔄 RE-SYNC QUEUE</button>
      </div>

      {loading ? <div className="text-muted" style={{ padding: 40, textAlign: 'center' }}>Synchronizing queue...</div> : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>APPLICANT PHONE</th>
                <th>CREDENTIAL TYPE</th>
                <th>SUBMITTED AT</th>
                <th>RISK STATUS</th>
                <th>ACTION</th>
              </tr>
            </thead>
            <tbody>
              {users.length === 0 && <tr><td colSpan={5} style={{ textAlign: 'center', color: 'var(--text-muted)', padding: 64 }}>Queue is clean. All identities verified. ✅</td></tr>}
              {users.map(u => (
                <tr key={u._id}>
                  <td style={{ fontWeight: 800, color: 'var(--primary)' }}>{u.phone}</td>
                  <td><span className="badge badge-gray">{u.kyc?.idType || 'UNSPECIFIED'}</span></td>
                  <td className="text-muted">{new Date(u.kyc?.submittedAt).toLocaleString()}</td>
                  <td><span className="badge badge-yellow">PENDING REVIEW</span></td>
                  <td>
                    <button className="btn btn-primary btn-sm" onClick={() => setSelected(u)}>AUDIT CREDENTIALS</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {selected && (
        <div className="modal-backdrop" onClick={() => setSelected(null)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <div className="modal-title">Identity Verification Audit</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
               <div className="card" style={{ background: 'var(--surface-high)', padding: 20, borderRadius: 16 }}>
                  <div className="card-title" style={{ marginBottom: 12 }}>Candidate Details</div>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                    <div>
                      <div className="text-muted" style={{ fontSize: 10 }}>FULL NAME</div>
                      <div style={{ fontWeight: 700 }}>{selected.kyc?.fullName || 'NOT PROVIDED'}</div>
                    </div>
                    <div>
                      <div className="text-muted" style={{ fontSize: 10 }}>PHONE NUMBER</div>
                      <div style={{ fontWeight: 700 }}>{selected.phone}</div>
                    </div>
                    <div>
                      <div className="text-muted" style={{ fontSize: 10 }}>DOCUMENT TYPE</div>
                      <div style={{ fontWeight: 700 }}>{selected.kyc?.idType}</div>
                    </div>
                    <div>
                      <div className="text-muted" style={{ fontSize: 10 }}>ID NUMBER</div>
                      <div className="monospace">{selected.kyc?.idNumber || 'PND-XXX-XXX'}</div>
                    </div>
                  </div>
               </div>

              <div style={{ background: 'var(--bg)', borderRadius: 16, padding: 32, minHeight: 200, border: '2px dashed var(--border)', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 12 }}>
                <span style={{ fontSize: 32 }}>📄</span>
                <span className="text-muted">High-resolution document scan would appear here</span>
                <button className="btn btn-outline btn-sm">VIEW ORIGINAL SIZE</button>
              </div>

              <textarea 
                className="input" 
                rows={3} 
                placeholder="Audit notes or rejection reason (required for rejection)" 
                value={reason} 
                onChange={e => setReason(e.target.value)} 
                style={{ resize: 'none' }}
              />

              <div style={{ display: 'flex', gap: 16 }}>
                <button className="btn btn-primary" style={{ flex: 1 }} onClick={() => decide(selected._id, 'APPROVED')}>APPROVE IDENTITY</button>
                <button className="btn btn-danger" style={{ flex: 1 }} onClick={() => decide(selected._id, 'REJECTED')}>REJECT APPLICATION</button>
              </div>
              <button className="btn btn-outline" style={{ width: '100%' }} onClick={() => setSelected(null)}>CANCEL AUDIT</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
