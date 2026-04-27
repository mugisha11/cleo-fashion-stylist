import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { Heart, ArrowLeft } from 'lucide-react';
import { Navbar } from '@/components/Navbar';
import { PropertyCard } from '@/components/PropertyCard';
import { Footer } from '@/components/Footer';
import { useAuth } from '@/contexts/AuthContext';
import { useFavorites } from '@/contexts/FavoritesContext';
import { fetchFavorites } from '@/lib/queries';
import type { Property } from '@/lib/properties';
import { Button } from '@/components/ui/button';
import { Skeleton } from '@/components/ui/skeleton';

export default function Favorites() {
  const { user } = useAuth();
  const { favorites } = useFavorites();
  const [properties, setProperties] = useState<Property[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user) { setProperties([]); setLoading(false); return; }
    setLoading(true);
    fetchFavorites(user.id).then(setProperties).finally(() => setLoading(false));
  }, [user, favorites.length]);

  return (
    <div className="min-h-screen bg-background">
      <Navbar />
      <main className="container mx-auto px-4 py-8">
        <Link to="/" className="inline-flex items-center gap-2 text-muted-foreground hover:text-foreground mb-6 transition-colors">
          <ArrowLeft className="w-4 h-4" /> Back to home
        </Link>

        <h1 className="text-2xl md:text-3xl font-bold mb-2">Your Favorites</h1>
        <p className="text-muted-foreground mb-8">
          {loading ? 'Loading…' : `${properties.length} saved ${properties.length === 1 ? 'property' : 'properties'}`}
        </p>

        {!user ? (
          <div className="text-center py-16">
            <h2 className="text-xl font-semibold mb-2">Sign in to view favorites</h2>
            <p className="text-muted-foreground mb-6">Create an account to save properties you love.</p>
            <Button asChild><Link to="/login">Sign in</Link></Button>
          </div>
        ) : loading ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="aspect-[4/3] rounded-xl" />)}
          </div>
        ) : properties.length > 0 ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {properties.map((property, idx) => (
              <PropertyCard key={property.id} property={property} className="animate-fade-in" style={{ animationDelay: `${idx * 0.05}s` }} />
            ))}
          </div>
        ) : (
          <div className="text-center py-16">
            <div className="w-24 h-24 rounded-full bg-secondary flex items-center justify-center mx-auto mb-6">
              <Heart className="w-10 h-10 text-muted-foreground" />
            </div>
            <h2 className="text-xl font-semibold mb-2">No favorites yet</h2>
            <p className="text-muted-foreground mb-6 max-w-md mx-auto">Start exploring and save properties you love by clicking the heart icon</p>
            <Button asChild><Link to="/listings">Browse Properties</Link></Button>
          </div>
        )}
      </main>
      <Footer />
    </div>
  );
}
