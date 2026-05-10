import { useEffect, useState } from 'react';

interface Props { api: string; headers: Record<string, string>; }
interface Vault { _id: string; title: string; amount: number; state: string; buyerId: any; sellerId: any; createdAt: string; }

const STATE_BADGE: Record<string, string> = { INITIATED: 'badge-gray', FUNDED: 'badge-blue', SHIPPED: 'badge-yellow', DELIVERED: 'badge-gold', COMPLETED: 'badge-green', REFUNDED: 'badge-red', DISPUTED: 'badge-red', CANCELLED: 'badge-gray', ADMIN_REVIEW: 'badge-gold' };

export default function Vaults({ api, headers }: Props) {
  const [vaults, setVaults] = useState<Vault[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('');
  const [stateFilter, setStateFilter] = useState('');

  useEffect(() => {
    setLoading(true);
    fetch(`${api}/admin/vaults?limit=100${stateFilter ? `&state=${stateFilter}` : ''}`, { headers })
      .then(r => r.json()).then(d => { setVaults(d.data || []); setLoading(false); });
  }, [stateFilter]);

  const filtered = vaults.filter(v =>
    !filter || v.title.toLowerCase().includes(filter.toLowerCase()) ||
    v._id.toLowerCase().includes(filter.toLowerCase())
  );

  const states = ['', 'INITIATED', 'FUNDED', 'SHIPPED', 'DELIVERED', 'COMPLETED', 'REFUNDED', 'DISPUTED', 'CANCELLED'];

  return (
    <div>
      <div className="section-header">
        <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
          <h2>Institutional Asset Ledger</h2>
          <p className="text-muted">Global registry of all secure custodial vaults</p>
        </div>
        <div className="flex-gap">
          <select className="input" style={{ width: 180 }} value={stateFilter} onChange={e => setStateFilter(e.target.value)}>
            {states.map(s => <option key={s} value={s}>{s || 'ALL STATES'}</option>)}
          </select>
          <input className="input" style={{ width: 280 }} placeholder="Search Title, ID, or Protocol..." value={filter} onChange={e => setFilter(e.target.value)} />
        </div>
      </div>

      {loading ? <div className="text-muted" style={{ padding: 40, textAlign: 'center' }}>Querying asset database...</div> : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>PROTOCOL ID</th>
                <th>VAULT DESCRIPTION</th>
                <th>BUYER</th>
                <th>SELLER</th>
                <th>LIQUIDITY (NPR)</th>
                <th>LIFECYCLE STATE</th>
                <th>TIMESTAMP</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 && <tr><td colSpan={7} style={{ textAlign: 'center', color: 'var(--text-muted)', padding: 64 }}>No vaults matched the specified query.</td></tr>}
              {filtered.map(v => (
                <tr key={v._id}>
                  <td className="monospace" style={{ color: 'var(--primary)' }}>{v._id.slice(-10).toUpperCase()}</td>
                  <td style={{ fontWeight: 800 }}>{v.title}</td>
                  <td className="text-muted">{v.buyerId?.phone || '—'}</td>
                  <td className="text-muted">{v.sellerId?.phone || '—'}</td>
                  <td style={{ fontWeight: 700 }}>Rs. {v.amount.toLocaleString()}</td>
                  <td><span className={`badge ${STATE_BADGE[v.state] || 'badge-gray'}`}>{v.state}</span></td>
                  <td className="text-muted" style={{ fontSize: 11 }}>{new Date(v.createdAt).toLocaleDateString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
