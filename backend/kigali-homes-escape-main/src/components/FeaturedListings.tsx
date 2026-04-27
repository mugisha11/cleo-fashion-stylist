import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight } from 'lucide-react';
import { PropertyCard } from './PropertyCard';
import { fetchProperties } from '@/lib/queries';
import type { Property } from '@/lib/properties';
import { Skeleton } from '@/components/ui/skeleton';

export function FeaturedListings() {
  const [featured, setFeatured] = useState<Property[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchProperties({ featured: true })
      .then((p) => setFeatured(p.slice(0, 4)))
      .finally(() => setLoading(false));
  }, []);

  return (
    <section className="py-16 md:py-24">
      <div className="container mx-auto px-4">
        <div className="flex items-end justify-between mb-8">
          <div>
            <h2 className="text-2xl md:text-3xl font-bold mb-2">Featured Properties</h2>
            <p className="text-muted-foreground">Handpicked homes in Kigali's best neighborhoods</p>
          </div>
          <Link to="/listings" className="hidden sm:flex items-center gap-2 text-primary font-medium hover:underline">
            View all <ArrowRight className="w-4 h-4" />
          </Link>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          {loading
            ? Array.from({ length: 4 }).map((_, i) => (
                <div key={i} className="space-y-3">
                  <Skeleton className="aspect-[4/3] rounded-xl" />
                  <Skeleton className="h-4 w-3/4" />
                  <Skeleton className="h-4 w-1/2" />
                </div>
              ))
            : featured.map((property, idx) => (
                <PropertyCard
                  key={property.id}
                  property={property}
                  className="animate-fade-in"
                  style={{ animationDelay: `${idx * 0.1}s` }}
                />
              ))}
        </div>

        {!loading && featured.length === 0 && (
          <p className="text-center text-muted-foreground py-12">No featured properties yet.</p>
        )}

        <Link to="/listings" className="flex sm:hidden items-center justify-center gap-2 mt-8 text-primary font-medium">
          View all properties <ArrowRight className="w-4 h-4" />
        </Link>
      </div>
    </section>
  );
}
