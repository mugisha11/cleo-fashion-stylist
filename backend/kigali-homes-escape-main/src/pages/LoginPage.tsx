import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { Home, Eye, EyeOff } from 'lucide-react';
import { useAuth, UserRole } from '@/contexts/AuthContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';

const roleOptions: { role: UserRole; label: string; desc: string; color: string }[] = [
  { role: 'admin', label: 'Admin', desc: 'Full platform control', color: 'border-destructive/40 bg-destructive/5 hover:border-destructive' },
  { role: 'agent', label: 'Agent', desc: 'Manage & sell listings', color: 'border-primary/40 bg-primary/5 hover:border-primary' },
  { role: 'host', label: 'Host', desc: 'List your properties', color: 'border-chart-4/40 bg-chart-4/5 hover:border-chart-4' },
  { role: 'client', label: 'Client', desc: 'Browse & save homes', color: 'border-chart-2/40 bg-chart-2/5 hover:border-chart-2' },
];

export default function LoginPage() {
  const navigate = useNavigate();
  const { signIn, signUp } = useAuth();
  const { toast } = useToast();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [showPw, setShowPw] = useState(false);
  const [selectedRole, setSelectedRole] = useState<UserRole>('client');
  const [busy, setBusy] = useState(false);

  const resolveDashboardPath = async () => {
    const { data: { user: u } } = await supabase.auth.getUser();
    if (!u) return '/';
    const { data: roleRow } = await supabase
      .from('user_roles').select('role').eq('user_id', u.id)
      .order('created_at', { ascending: true }).limit(1).maybeSingle();
    return `/dashboard/${roleRow?.role ?? 'client'}`;
  };

  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      toast({ title: 'Email and password required', variant: 'destructive' }); return;
    }
    setBusy(true);
    const { error } = await signIn(email, password);
    setBusy(false);
    if (error) { toast({ title: 'Sign in failed', description: error, variant: 'destructive' }); return; }
    toast({ title: 'Welcome back!' });
    navigate(await resolveDashboardPath());
  };

  const handleSignUp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password || !name) {
      toast({ title: 'All fields required', variant: 'destructive' }); return;
    }
    setBusy(true);
    const { error } = await signUp(email, password, name, selectedRole);
    setBusy(false);
    if (error) { toast({ title: 'Sign up failed', description: error, variant: 'destructive' }); return; }
    toast({ title: 'Account created!', description: `Welcome, ${name}` });
    navigate(`/dashboard/${selectedRole}`);
  };

  return (
    <div className="min-h-screen flex bg-muted/30">
      <div className="hidden lg:flex lg:w-1/2 relative bg-primary items-center justify-center overflow-hidden">
        <div className="absolute inset-0 bg-[url('https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=1200')] bg-cover bg-center opacity-20" />
        <div className="relative z-10 text-center px-12">
          <div className="w-16 h-16 rounded-2xl bg-primary-foreground/20 backdrop-blur flex items-center justify-center mx-auto mb-6">
            <Home className="w-8 h-8 text-primary-foreground" />
          </div>
          <h1 className="text-4xl font-bold text-primary-foreground mb-4">Kigali Homes</h1>
          <p className="text-primary-foreground/80 text-lg max-w-md">Discover your perfect property in the heart of Rwanda's vibrant capital</p>
        </div>
      </div>

      <div className="flex-1 flex items-center justify-center p-6">
        <div className="w-full max-w-md">
          <div className="lg:hidden flex items-center gap-2 mb-8 justify-center">
            <div className="w-10 h-10 rounded-xl bg-primary flex items-center justify-center">
              <Home className="w-5 h-5 text-primary-foreground" />
            </div>
            <span className="text-xl font-bold">Kigali Homes</span>
          </div>

          <Tabs defaultValue="signin" className="w-full">
            <TabsList className="grid w-full grid-cols-2 mb-6">
              <TabsTrigger value="signin">Sign In</TabsTrigger>
              <TabsTrigger value="signup">Sign Up</TabsTrigger>
            </TabsList>

            <TabsContent value="signin">
              <h2 className="text-2xl font-bold mb-1">Welcome back</h2>
              <p className="text-muted-foreground mb-6">Sign in to access your dashboard</p>
              <form onSubmit={handleSignIn} className="space-y-4">
                <div>
                  <label className="text-sm font-medium mb-1.5 block">Email</label>
                  <Input type="email" placeholder="you@example.com" value={email} onChange={(e) => setEmail(e.target.value)} className="h-11 rounded-xl" />
                </div>
                <div>
                  <label className="text-sm font-medium mb-1.5 block">Password</label>
                  <div className="relative">
                    <Input type={showPw ? 'text' : 'password'} placeholder="Enter your password" value={password} onChange={(e) => setPassword(e.target.value)} className="h-11 rounded-xl pr-10" />
                    <button type="button" onClick={() => setShowPw(!showPw)} className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground">
                      {showPw ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                  </div>
                </div>
                <Button type="submit" disabled={busy} className="w-full h-11 rounded-xl text-base font-semibold">
                  {busy ? 'Signing in…' : 'Sign In'}
                </Button>
              </form>
            </TabsContent>

            <TabsContent value="signup">
              <h2 className="text-2xl font-bold mb-1">Create your account</h2>
              <p className="text-muted-foreground mb-6">Pick a role and join Kigali Homes</p>

              <div className="grid grid-cols-2 gap-3 mb-6">
                {roleOptions.map((opt) => (
                  <button
                    key={opt.role}
                    type="button"
                    onClick={() => setSelectedRole(opt.role)}
                    className={`rounded-xl border-2 p-3 text-left transition-all ${opt.color} ${
                      selectedRole === opt.role ? 'ring-2 ring-offset-2 ring-primary scale-[1.02]' : 'opacity-70'
                    }`}
                  >
                    <p className="font-semibold text-sm">{opt.label}</p>
                    <p className="text-xs text-muted-foreground">{opt.desc}</p>
                  </button>
                ))}
              </div>

              <form onSubmit={handleSignUp} className="space-y-4">
                <div>
                  <label className="text-sm font-medium mb-1.5 block">Full name</label>
                  <Input value={name} onChange={(e) => setName(e.target.value)} className="h-11 rounded-xl" placeholder="Jane Doe" />
                </div>
                <div>
                  <label className="text-sm font-medium mb-1.5 block">Email</label>
                  <Input type="email" placeholder="you@example.com" value={email} onChange={(e) => setEmail(e.target.value)} className="h-11 rounded-xl" />
                </div>
                <div>
                  <label className="text-sm font-medium mb-1.5 block">Password</label>
                  <Input type="password" placeholder="At least 6 characters" value={password} onChange={(e) => setPassword(e.target.value)} className="h-11 rounded-xl" />
                </div>
                <Button type="submit" disabled={busy} className="w-full h-11 rounded-xl text-base font-semibold">
                  {busy ? 'Creating account…' : `Sign Up as ${roleOptions.find(r => r.role === selectedRole)?.label}`}
                </Button>
              </form>
            </TabsContent>
          </Tabs>

          <p className="text-center mt-6">
            <Link to="/" className="text-sm text-muted-foreground hover:text-foreground transition-colors">← Back to home</Link>
          </p>
        </div>
      </div>
    </div>
  );
}
