import { supabase } from '@/integrations/supabase/client';
import { mapDbProperty, type Property, type OwnerLite, type DbProperty } from './properties';

async function loadOwners(ownerIds: string[]): Promise<Record<string, OwnerLite>> {
  if (ownerIds.length === 0) return {};
  const { data } = await supabase
    .from('profiles')
    .select('user_id, display_name, avatar_url, phone')
    .in('user_id', ownerIds);
  const map: Record<string, OwnerLite> = {};
  (data ?? []).forEach((p) => {
    const phone = p.phone ?? '+250 788 000 000';
    map[p.user_id] = {
      id: p.user_id,
      name: p.display_name ?? 'Property Owner',
      image: p.avatar_url ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
      phone,
      whatsapp: phone.replace(/[^\d]/g, ''),
    };
  });
  return map;
}

export async function fetchProperties(filters?: {
  priceType?: 'rent' | 'sale';
  neighborhood?: string;
  bedrooms?: number;
  minBeds?: number;
  featured?: boolean;
  ownerId?: string;
}): Promise<Property[]> {
  let q = supabase.from('properties').select('*').order('created_at', { ascending: false });
  if (filters?.priceType) q = q.eq('price_type', filters.priceType);
  if (filters?.neighborhood && filters.neighborhood !== 'All Locations') q = q.eq('neighborhood', filters.neighborhood);
  if (filters?.bedrooms !== undefined) q = q.eq('bedrooms', filters.bedrooms);
  if (filters?.minBeds !== undefined) q = q.gte('bedrooms', filters.minBeds);
  if (filters?.featured) q = q.eq('is_featured', true);
  if (filters?.ownerId) q = q.eq('owner_id', filters.ownerId);

  const { data, error } = await q;
  if (error) throw error;
  const owners = await loadOwners([...new Set((data ?? []).map((p) => p.owner_id))]);
  return (data ?? []).map((p) => mapDbProperty(p as DbProperty, owners[p.owner_id]));
}

export async function fetchProperty(id: string): Promise<Property | null> {
  const { data, error } = await supabase.from('properties').select('*').eq('id', id).maybeSingle();
  if (error) throw error;
  if (!data) return null;
  const owners = await loadOwners([data.owner_id]);
  return mapDbProperty(data as DbProperty, owners[data.owner_id]);
}

export async function fetchFavorites(userId: string): Promise<Property[]> {
  const { data, error } = await supabase
    .from('favorites')
    .select('property_id, properties(*)')
    .eq('user_id', userId);
  if (error) throw error;
  const props = (data ?? []).map((r) => r.properties).filter(Boolean) as DbProperty[];
  const owners = await loadOwners([...new Set(props.map((p) => p.owner_id))]);
  return props.map((p) => mapDbProperty(p, owners[p.owner_id]));
}
