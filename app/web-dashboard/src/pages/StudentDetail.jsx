import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, User, Activity, AlertCircle } from 'lucide-react';
import { fetchStudents } from '../utils/api';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar } from 'recharts';

export default function StudentDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [student, setStudent] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadData() {
      try {
        const students = await fetchStudents();
        const found = students.find(s => s.id === id);
        if (found) {
          setStudent(found);
        } else {
          navigate('/dashboard');
        }
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    }
    loadData();
  }, [id, navigate]);

  if (loading) {
    return <div style={{ display: 'flex', minHeight: '100vh', alignItems: 'center', justifyContent: 'center' }}>Loading...</div>;
  }
  if (!student) return null;

  // Mock data for specialist viewing Response To Intervention (RTI)
  const progressData = [
    { name: 'Week 1', fluency: 40, comprehension: 24 },
    { name: 'Week 2', fluency: 45, comprehension: 28 },
    { name: 'Week 3', fluency: 42, comprehension: 35 },
    { name: 'Week 4', fluency: 55, comprehension: 48 },
    { name: 'Week 5', fluency: 65, comprehension: 52 },
    { name: 'Week 6', fluency: 72, comprehension: 60 },
  ];

  const errorData = [
    { type: 'Visual Reversals (b/d)', count: 24 },
    { type: 'Auditory Confusion (f/th)', count: 12 },
    { type: 'Skipped Sight Words', count: 35 },
    { type: 'Vowel Sound Errors', count: 18 },
  ];

  return (
    <div style={{ maxWidth: '1200px', margin: '0 auto', padding: '2rem' }}>
      {/* Header */}
      <header style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '3rem' }}>
        <button onClick={() => navigate('/dashboard')} className="btn-outline" style={{ padding: '0.5rem', borderRadius: '50%' }}>
          <ArrowLeft size={20} />
        </button>
        <div>
          <h2 style={{ margin: 0, display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
            <User color="var(--primary-accent)" />
            {student.first_name} {student.last_name}
          </h2>
          <p style={{ margin: 0, fontSize: '0.875rem' }}>Grade {student.grade} • Username: {student.username}</p>
        </div>
      </header>

      {/* Main Content */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem', marginBottom: '2rem' }}>
        
        {/* RTI Chart */}
        <div className="glass-card animate-fade-in" style={{ padding: '2rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1.5rem' }}>
            <Activity color="var(--secondary-accent)" size={20} />
            <h3 style={{ margin: 0, fontSize: '1.25rem' }}>Response to Intervention (RTI)</h3>
          </div>
          <div style={{ height: '300px', width: '100%' }}>
            <ResponsiveContainer>
              <AreaChart data={progressData}>
                <defs>
                  <linearGradient id="colorFluency" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="var(--primary-accent)" stopOpacity={0.8}/>
                    <stop offset="95%" stopColor="var(--primary-accent)" stopOpacity={0}/>
                  </linearGradient>
                  <linearGradient id="colorComp" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="var(--secondary-accent)" stopOpacity={0.8}/>
                    <stop offset="95%" stopColor="var(--secondary-accent)" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.1)" vertical={false} />
                <XAxis dataKey="name" stroke="var(--text-muted)" tick={{fill: 'var(--text-muted)'}} />
                <YAxis stroke="var(--text-muted)" tick={{fill: 'var(--text-muted)'}} />
                <Tooltip />
                <Area type="monotone" dataKey="fluency" stroke="var(--primary-accent)" fillOpacity={1} fill="url(#colorFluency)" name="Reading Fluency" />
                <Area type="monotone" dataKey="comprehension" stroke="var(--secondary-accent)" fillOpacity={1} fill="url(#colorComp)" name="Comprehension" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Phonetic Error Profile */}
        <div className="glass-card animate-fade-in" style={{ padding: '2rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1.5rem' }}>
            <AlertCircle color="var(--coral-accent)" size={20} />
            <h3 style={{ margin: 0, fontSize: '1.25rem' }}>Phonetic Error Profile</h3>
          </div>
          <div style={{ height: '300px', width: '100%' }}>
            <ResponsiveContainer>
              <BarChart data={errorData} layout="vertical" margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.1)" horizontal={false} />
                <XAxis type="number" stroke="var(--text-muted)" tick={{fill: 'var(--text-muted)'}} />
                <YAxis dataKey="type" type="category" width={150} stroke="var(--text-muted)" tick={{fill: 'var(--text-muted)', fontSize: 12}} />
                <Tooltip cursor={{fill: 'rgba(255,255,255,0.05)'}} />
                <Bar dataKey="count" fill="var(--coral-accent)" radius={[0, 4, 4, 0]} barSize={24} name="Error Frequency" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </div>
  );
}
