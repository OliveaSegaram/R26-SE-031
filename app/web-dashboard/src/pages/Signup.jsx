import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { Stethoscope, ArrowRight, CheckCircle2 } from 'lucide-react';
import { signup, verifyEmail } from '../utils/api';

export default function Signup() {
  const navigate = useNavigate();
  const [step, setStep] = useState(1);
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [otp, setOtp] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSignup = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await signup(name, email, password);
      setStep(2);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleVerify = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await verifyEmail(email, otp);
      navigate('/dashboard');
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ display: 'flex', minHeight: '100vh', alignItems: 'center', justifyContent: 'center', padding: '2rem' }}>
      <div className="glass-panel animate-fade-in" style={{ maxWidth: '400px', width: '100%', padding: '2.5rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '2rem', justifyContent: 'center' }}>
          <Stethoscope color="var(--primary-accent)" size={32} />
          <h2>Specialist Registration</h2>
        </div>
        
        {step === 1 ? (
          <>
            <p style={{ textAlign: 'center', marginBottom: '2rem' }}>Create your professional account to generate your Clinic Code.</p>
            <form onSubmit={handleSignup} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
              <div>
                <label className="input-label">Full Name</label>
                <input 
                  type="text" 
                  className="input-field" 
                  value={name} 
                  onChange={(e) => setName(e.target.value)}
                  required 
                  placeholder="Dr. Sarah Smith"
                />
              </div>
              <div>
                <label className="input-label">Email Address</label>
                <input 
                  type="email" 
                  className="input-field" 
                  value={email} 
                  onChange={(e) => setEmail(e.target.value)}
                  required 
                  placeholder="dr.smith@clinic.com"
                />
              </div>
              <div>
                <label className="input-label">Password</label>
                <input 
                  type="password" 
                  className="input-field" 
                  value={password} 
                  onChange={(e) => setPassword(e.target.value)}
                  required 
                  placeholder="••••••••"
                />
              </div>
              
              {error && <div style={{ color: 'var(--coral-accent)', fontSize: '0.875rem' }}>{error}</div>}
              
              <button type="submit" className="btn-primary" disabled={loading} style={{ marginTop: '1rem' }}>
                {loading ? 'Creating...' : 'Create Account'}
                <ArrowRight size={18} />
              </button>
            </form>
          </>
        ) : (
          <>
            <p style={{ textAlign: 'center', marginBottom: '2rem' }}>We sent a 6-digit verification code to <strong>{email}</strong>.</p>
            <form onSubmit={handleVerify} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
              <div>
                <label className="input-label">Verification Code</label>
                <input 
                  type="text" 
                  maxLength={6}
                  className="input-field" 
                  value={otp} 
                  onChange={(e) => setOtp(e.target.value)}
                  required 
                  style={{ textAlign: 'center', fontSize: '1.5rem', letterSpacing: '8px' }}
                  placeholder="XXXXXX"
                />
              </div>
              
              {error && <div style={{ color: 'var(--coral-accent)', fontSize: '0.875rem' }}>{error}</div>}
              
              <button type="submit" className="btn-primary" disabled={loading} style={{ marginTop: '1rem' }}>
                {loading ? 'Verifying...' : 'Verify & Login'}
                <CheckCircle2 size={18} />
              </button>
            </form>
          </>
        )}
        
        {step === 1 && (
          <div style={{ marginTop: '2rem', textAlign: 'center', fontSize: '0.875rem' }}>
            <span style={{ color: 'var(--text-muted)' }}>Already have an account? </span>
            <Link to="/login" style={{ color: 'var(--primary-accent)', textDecoration: 'none', fontWeight: 600 }}>Sign In</Link>
          </div>
        )}
      </div>
    </div>
  );
}
