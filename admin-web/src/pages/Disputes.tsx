import { useEffect, useState } from 'react';

interface Props { api: string; headers: Record<string, string>; }
interface Dispute { _id: string; vaultId: any; reason: string; status: string; createdAt: string; createdBy: any; }

export default function Disputes({ api, headers }: Props) {
  const [disputes, setDisputes] = useState<Dispute[]>([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<Dispute | null>(null);
  const [resolution, setResolution] = useState('');

  useEffect(() => { fetchDisputes(); }, []);

  const fetchDisputes = async () => {
    setLoading(true);
    try {
      const r = await fetch(`${api}/admin/disputes`, { headers });
      const d = await r.json();
      setDisputes(d.data || []);
    } catch { setDisputes([]); }
    setLoading(false);
  };

  const resolve = async (disputeId: string, action: 'resolve_buyer' | 'resolve_seller') => {
    if (!resolution) {
        alert('Internal resolution justification is required.');
        return;
    }
    await fetch(`${api}/admin/disputes/${disputeId}/resolve`, {
      method: 'POST', headers,
      body: JSON.stringify({ action, resolution }),
    });
    setSelected(null); setResolution('');
    fetchDisputes();
  };

  return (
    <div>
      <div className="section-header">
        <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
          <h2>Dispute Arbitration Protocol</h2>
          <p className="text-muted">Legal mediation of failed asset transfers</p>
        </div>
        <button className="btn btn-outline btn-sm" onClick={fetchDisputes}>🔄 REFRESH LEDGER</button>
      </div>

      {loading ? <div className="text-muted" style={{ padding: 40, textAlign: 'center' }}>Loading arbitration records...</div> : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>CASE ID</th>
                <th>VAULT ID</th>
                <th>CLAIM REASON</th>
                <th>STATUS</th>
                <th>INITIATED</th>
                <th>ACTION</th>
              </tr>
            </thead>
            <tbody>
              {disputes.length === 0 && <tr><td colSpan={6} style={{ textAlign: 'center', color: 'var(--text-muted)', padding: 64 }}>System is clear. Zero active disputes. ⚖️</td></tr>}
              {disputes.map(d => (
                <tr key={d._id}>
                  <td className="monospace" style={{ color: 'var(--primary)' }}>{d._id.slice(-8).toUpperCase()}</td>
                  <td className="monospace">{d.vaultId?._id?.slice(-8).toUpperCase() || 'UNKNOWN'}</td>
                  <td style={{ fontWeight: 600 }}>{d.reason}</td>
                  <td><span className={`badge ${d.status === 'OPEN' ? 'badge-red' : 'badge-green'}`}>{d.status}</span></td>
                  <td className="text-muted">{new Date(d.createdAt).toLocaleDateString()}</td>
                  <td>
                    <button className="btn btn-danger btn-sm" onClick={() => setSelected(d)}>ARBITRATE</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {selected && (
        <div className="modal-backdrop" onClick={() => setSelected(null)}>
          <div className="modal" onClick={e => e.stopPropagation()} style={{ width: 600 }}>
            <div className="modal-title">Dispute Resolution Protocol</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
               <div className="card" style={{ background: 'var(--surface-high)', padding: 24, borderRadius: 16 }}>
                  <div className="card-title">Case Evidence</div>
                  <div style={{ marginBottom: 16 }}>
                    <div className="text-muted" style={{ fontSize: 10, marginBottom: 4 }}>CLAIMANT REASON</div>
                    <div style={{ fontSize: 14, lineHeight: 1.5, background: 'var(--bg)', padding: 12, borderRadius: 8 }}>{selected.reason}</div>
                  </div>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                    <div>
                      <div className="text-muted" style={{ fontSize: 10 }}>VAULT VALUE</div>
                      <div style={{ fontWeight: 800, color: 'var(--gold)' }}>Rs. {selected.vaultId?.amount?.toLocaleString() || '0'}</div>
                    </div>
                    <div>
                      <div className="text-muted" style={{ fontSize: 10 }}>INITIATED BY</div>
                      <div style={{ fontWeight: 700 }}>{selected.createdBy?.phone || 'CLIENT'}</div>
                    </div>
                  </div>
               </div>

              <div style={{ padding: '0 8px' }}>
                <div className="card-title" style={{ marginBottom: 12 }}>Arbitration Ruling</div>
                <textarea 
                  className="input" 
                  rows={4} 
                  placeholder="Provide internal justification for this ruling. This will be recorded in the immutable audit ledger." 
                  value={resolution} 
                  onChange={e => setResolution(e.target.value)} 
                  style={{ resize: 'none' }}
                />
              </div>

              <div style={{ display: 'flex', gap: 16 }}>
                <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 8 }}>
                  <button className="btn btn-primary" onClick={() => resolve(selected._id, 'resolve_buyer')}>RULING: REFUND BUYER</button>
                  <div style={{ fontSize: 9, textAlign: 'center', opacity: 0.5 }}>Full liquidity return to origin account</div>
                </div>
                <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 8 }}>
                  <button className="btn btn-danger" onClick={() => resolve(selected._id, 'resolve_seller')}>RULING: PAY SELLER</button>
                  <div style={{ fontSize: 9, textAlign: 'center', opacity: 0.5 }}>Immediate transfer to beneficiary</div>
                </div>
              </div>
              
              <div style={{ borderTop: '1px solid var(--border)', paddingTop: 16 }}>
                <button className="btn btn-outline" style={{ width: '100%' }} onClick={() => setSelected(null)}>DEFER CASE REVIEW</button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
