import React, { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from './AuthContext';
import { useToast } from '@/hooks/use-toast';

interface FavoritesContextType {
  favorites: string[];
  toggleFavorite: (propertyId: string) => Promise<void>;
  isFavorite: (propertyId: string) => boolean;
  loading: boolean;
}

const FavoritesContext = createContext<FavoritesContextType | undefined>(undefined);

export function FavoritesProvider({ children }: { children: React.ReactNode }) {
  const { user } = useAuth();
  const { toast } = useToast();
  const [favorites, setFavorites] = useState<string[]>([]);
  const [loading, setLoading] = useState(false);

  const refresh = useCallback(async () => {
    if (!user) { setFavorites([]); return; }
    setLoading(true);
    const { data } = await supabase.from('favorites').select('property_id').eq('user_id', user.id);
    setFavorites((data ?? []).map((r) => r.property_id));
    setLoading(false);
  }, [user]);

  useEffect(() => { refresh(); }, [refresh]);

  const toggleFavorite = async (propertyId: string) => {
    if (!user) {
      toast({ title: 'Sign in required', description: 'Please log in to save properties.', variant: 'destructive' });
      return;
    }
    const isFav = favorites.includes(propertyId);
    if (isFav) {
      setFavorites((p) => p.filter((id) => id !== propertyId));
      await supabase.from('favorites').delete().eq('user_id', user.id).eq('property_id', propertyId);
    } else {
      setFavorites((p) => [...p, propertyId]);
      await supabase.from('favorites').insert({ user_id: user.id, property_id: propertyId });
    }
  };

  const isFavorite = (id: string) => favorites.includes(id);

  return (
    <FavoritesContext.Provider value={{ favorites, toggleFavorite, isFavorite, loading }}>
      {children}
    </FavoritesContext.Provider>
  );
}

export function useFavorites() {
  const ctx = useContext(FavoritesContext);
  if (!ctx) throw new Error('useFavorites must be used within FavoritesProvider');
  return ctx;
}
