// Shared types/helpers for property data (now sourced from Supabase).
// Keeps formatPrice + neighborhoods constants used across the app.

import type { Database } from '@/integrations/supabase/types';

export type DbProperty = Database['public']['Tables']['properties']['Row'];

// View-model used by PropertyCard / PropertyDetails (mapped from DbProperty).
export interface Property {
  id: string;
  title: string;
  location: string;
  neighborhood: string;
  price: number;
  priceType: 'sale' | 'rent';
  bedrooms: number;
  bathrooms: number;
  area: number;
  images: string[];
  description: string;
  amenities: string[];
  rating: number;
  reviews: number;
  agent: {
    id: string;
    name: string;
    image: string;
    phone: string;
    whatsapp: string;
  };
  featured: boolean;
  createdAt: string;
}

export interface OwnerLite {
  id: string;
  name: string;
  image: string;
  phone: string;
  whatsapp: string;
}

export function mapDbProperty(p: DbProperty, owner?: OwnerLite | null): Property {
  const fallback: OwnerLite = {
    id: p.owner_id,
    name: 'Property Owner',
    image: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
    phone: '+250 788 000 000',
    whatsapp: '250788000000',
  };
  const a = owner ?? fallback;
  return {
    id: p.id,
    title: p.title,
    location: p.address || `${p.neighborhood}, Kigali`,
    neighborhood: p.neighborhood,
    price: Number(p.price),
    priceType: p.price_type,
    bedrooms: p.bedrooms,
    bathrooms: Number(p.bathrooms),
    area: p.area_sqm ? Number(p.area_sqm) : 0,
    images: p.images ?? [],
    description: p.description ?? '',
    amenities: p.amenities ?? [],
    rating: p.rating ? Number(p.rating) : 0,
    reviews: p.review_count ?? 0,
    agent: a,
    featured: p.is_featured,
    createdAt: p.created_at,
  };
}

export const neighborhoods = [
  'All Locations',
  'Nyarutarama',
  'Kiyovu',
  'Kimihurura',
  'Gacuriro',
  'Remera',
  'Kicukiro',
  'Gikondo',
  'Nyamirambo',
];

export const bedroomOptions = ['Any', '1', '2', '3', '4', '5+'];

export function formatPrice(price: number, type: 'sale' | 'rent'): string {
  if (price >= 1_000_000_000) return `${(price / 1_000_000_000).toFixed(1)}B RWF`;
  if (price >= 1_000_000) return `${(price / 1_000_000).toFixed(0)}M RWF${type === 'rent' ? '/mo' : ''}`;
  if (price >= 1_000) return `${(price / 1_000).toFixed(0)}K RWF${type === 'rent' ? '/mo' : ''}`;
  return `${price} RWF${type === 'rent' ? '/mo' : ''}`;
}
