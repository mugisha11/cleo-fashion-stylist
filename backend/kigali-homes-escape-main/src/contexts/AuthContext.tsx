import { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import type { Session, User as SupaUser } from '@supabase/supabase-js';
import { supabase } from '@/integrations/supabase/client';

export type UserRole = 'admin' | 'agent' | 'host' | 'client';

export interface AppUser {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  avatar: string;
}

interface AuthContextType {
  user: AppUser | null;
  session: Session | null;
  loading: boolean;
  signUp: (email: string, password: string, displayName: string, role: UserRole) => Promise<{ error: string | null }>;
  signIn: (email: string, password: string) => Promise<{ error: string | null }>;
  logout: () => Promise<void>;
  isAuthenticated: boolean;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}

async function buildAppUser(supaUser: SupaUser): Promise<AppUser> {
  const [{ data: profile }, { data: roleRow }] = await Promise.all([
    supabase.from('profiles').select('display_name, avatar_url').eq('user_id', supaUser.id).maybeSingle(),
    supabase.from('user_roles').select('role').eq('user_id', supaUser.id).order('created_at', { ascending: true }).limit(1).maybeSingle(),
  ]);
  return {
    id: supaUser.id,
    email: supaUser.email ?? '',
    name: profile?.display_name ?? supaUser.email?.split('@')[0] ?? 'User',
    avatar: profile?.avatar_url ?? `https://api.dicebear.com/7.x/initials/svg?seed=${encodeURIComponent(profile?.display_name ?? supaUser.email ?? 'U')}`,
    role: (roleRow?.role as UserRole) ?? 'client',
  };
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [user, setUser] = useState<AppUser | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Listener first, then getSession (per Supabase guidance)
    const { data: sub } = supabase.auth.onAuthStateChange((_event, newSession) => {
      setSession(newSession);
      if (newSession?.user) {
        // Defer to avoid deadlock
        setTimeout(() => {
          buildAppUser(newSession.user).then(setUser);
        }, 0);
      } else {
        setUser(null);
      }
    });

    supabase.auth.getSession().then(({ data: { session: s } }) => {
      setSession(s);
      if (s?.user) buildAppUser(s.user).then((u) => { setUser(u); setLoading(false); });
      else setLoading(false);
    });

    return () => sub.subscription.unsubscribe();
  }, []);

  const signUp: AuthContextType['signUp'] = async (email, password, displayName, role) => {
    const { error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        emailRedirectTo: `${window.location.origin}/`,
        data: { display_name: displayName, role },
      },
    });
    return { error: error?.message ?? null };
  };

  const signIn: AuthContextType['signIn'] = async (email, password) => {
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    return { error: error?.message ?? null };
  };

  const logout = async () => {
    await supabase.auth.signOut();
    setUser(null);
    setSession(null);
  };

  return (
    <AuthContext.Provider value={{ user, session, loading, signUp, signIn, logout, isAuthenticated: !!session }}>
      {children}
    </AuthContext.Provider>
  );
}
