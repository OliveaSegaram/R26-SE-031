import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Users, LogOut, Copy, Check, Activity } from 'lucide-react';
import { fetchMe, fetchStudents } from '../utils/api';

export default function Dashboard() {
  const navigate = useNavigate();
  const [profile, setProfile] = useState(null);
  const [students, setStudents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    async function loadData() {
      try {
        const [meData, studentsData] = await Promise.all([fetchMe(), fetchStudents()]);
        setProfile(meData);
        setStudents(studentsData);
      } catch (err) {
        console.error(err);
        navigate('/login');
      } finally {
        setLoading(false);
      }
    }
    loadData();
  }, [navigate]);

  const handleLogout = () => {
    localStorage.removeItem("specialist_token");
    navigate('/login');
  };

  const handleCopyCode = () => {
    if (profile?.clinic_code) {
      navigator.clipboard.writeText(profile.clinic_code);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  if (loading) {
    return <div style={{ display: 'flex', minHeight: '100vh', alignItems: 'center', justifyContent: 'center' }}>Loading...</div>;
  }

  return (
    <div style={{ maxWidth: '1200px', margin: '0 auto', padding: '2rem' }}>
      {/* Header */}
      <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '3rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <Activity color="var(--primary-accent)" size={32} />
          <div>
            <h2 style={{ margin: 0 }}>Specialist Dashboard</h2>
            <p style={{ margin: 0, fontSize: '0.875rem' }}>Welcome back, {profile?.name}</p>
          </div>
        </div>
        <button onClick={handleLogout} className="btn-outline" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <LogOut size={16} /> Logout
        </button>
      </header>

      {/* Main Content */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 3fr', gap: '2rem' }}>
        
        {/* Sidebar */}
        <div>
          <div className="glass-card animate-fade-in" style={{ padding: '2rem', textAlign: 'center' }}>
            <h3 style={{ color: 'var(--text-muted)', fontSize: '0.875rem', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '1rem' }}>Your Clinic Code</h3>
            <div 
              style={{ fontSize: '2.5rem', fontWeight: '700', letterSpacing: '4px', color: 'var(--primary-accent)', marginBottom: '1rem' }}
            >
              {profile?.clinic_code || '------'}
            </div>
            <p style={{ fontSize: '0.875rem', marginBottom: '1.5rem' }}>Share this 6-character code with parents to connect to their child's account.</p>
            <button onClick={handleCopyCode} className="btn-outline" style={{ width: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' }}>
              {copied ? <><Check size={16} /> Copied!</> : <><Copy size={16} /> Copy Code</>}
            </button>
          </div>
        </div>

        {/* Students Table */}
        <div className="glass-card animate-fade-in" style={{ padding: '2rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '2rem' }}>
            <Users color="var(--secondary-accent)" size={24} />
            <h2 style={{ margin: 0 }}>Connected Students</h2>
          </div>

          {students.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '4rem 0', color: 'var(--text-muted)' }}>
              No students connected yet. Share your Clinic Code with parents!
            </div>
          ) : (
            <table className="data-table">
              <thead>
                <tr>
                  <th>Student Name</th>
                  <th>Username</th>
                  <th>Grade Level</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {students.map((student) => (
                  <tr key={student.id} onClick={() => navigate(`/student/${student.id}`)}>
                    <td style={{ fontWeight: 600, color: 'var(--text-main)' }}>{student.first_name} {student.last_name}</td>
                    <td>{student.username}</td>
                    <td>{student.grade}</td>
                    <td><span className="badge success">Connected</span></td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </div>
  );
}
