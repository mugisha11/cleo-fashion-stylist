import { useEffect, useState, useMemo } from 'react';
import { useSearchParams } from 'react-router-dom';
import { SlidersHorizontal, Map, ChevronDown } from 'lucide-react';
import { Navbar } from '@/components/Navbar';
import { PropertyCard } from '@/components/PropertyCard';
import { Footer } from '@/components/Footer';
import { Button } from '@/components/ui/button';
import { Skeleton } from '@/components/ui/skeleton';
import { neighborhoods, bedroomOptions, type Property } from '@/lib/properties';
import { fetchProperties } from '@/lib/queries';
import { cn } from '@/lib/utils';

export default function Listings() {
  const [searchParams, setSearchParams] = useSearchParams();
  const [showMap, setShowMap] = useState(false);
  const [allProps, setAllProps] = useState<Property[]>([]);
  const [loading, setLoading] = useState(true);

  const [location, setLocation] = useState(searchParams.get('location') || 'All Locations');
  const [propertyType, setPropertyType] = useState<'all' | 'rent' | 'sale'>(
    (searchParams.get('type') as 'rent' | 'sale') || 'all'
  );
  const [bedrooms, setBedrooms] = useState(searchParams.get('bedrooms') || 'Any');
  const [sortBy, setSortBy] = useState('newest');

  useEffect(() => {
    setLoading(true);
    fetchProperties().then(setAllProps).finally(() => setLoading(false));
  }, []);

  const filteredProperties = useMemo(() => {
    let result = [...allProps];
    if (location !== 'All Locations') result = result.filter((p) => p.neighborhood === location);
    if (propertyType !== 'all') result = result.filter((p) => p.priceType === propertyType);
    if (bedrooms !== 'Any') {
      if (bedrooms === '5+') result = result.filter((p) => p.bedrooms >= 5);
      else result = result.filter((p) => p.bedrooms === parseInt(bedrooms));
    }
    if (sortBy === 'price-low') result.sort((a, b) => a.price - b.price);
    else if (sortBy === 'price-high') result.sort((a, b) => b.price - a.price);
    else result.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
    return result;
  }, [allProps, location, propertyType, bedrooms, sortBy]);

  const clearFilters = () => {
    setLocation('All Locations');
    setPropertyType('all');
    setBedrooms('Any');
    setSearchParams({});
  };

  const hasActiveFilters = location !== 'All Locations' || propertyType !== 'all' || bedrooms !== 'Any';

  return (
    <div className="min-h-screen bg-background">
      <Navbar />

      <div className="sticky top-20 z-40 bg-background border-b border-border">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center gap-3 overflow-x-auto pb-2 scrollbar-hide">
            <div className="flex rounded-full bg-secondary p-1 shrink-0">
              {(['all', 'rent', 'sale'] as const).map((type) => (
                <button
                  key={type}
                  onClick={() => setPropertyType(type)}
                  className={cn(
                    'px-4 py-2 rounded-full text-sm font-medium transition-all whitespace-nowrap',
                    propertyType === type ? 'bg-foreground text-background' : 'text-muted-foreground hover:text-foreground'
                  )}
                >
                  {type === 'all' ? 'All' : type === 'rent' ? 'Rent' : 'Buy'}
                </button>
              ))}
            </div>

            <div className="relative shrink-0">
              <select value={location} onChange={(e) => setLocation(e.target.value)} className="filter-pill appearance-none pr-8 cursor-pointer">
                {neighborhoods.map((n) => <option key={n} value={n}>{n}</option>)}
              </select>
              <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 pointer-events-none" />
            </div>

            <div className="relative shrink-0">
              <select value={bedrooms} onChange={(e) => setBedrooms(e.target.value)} className="filter-pill appearance-none pr-8 cursor-pointer">
                {bedroomOptions.map((b) => <option key={b} value={b}>{b === 'Any' ? 'Any beds' : `${b} bed${b === '1' ? '' : 's'}`}</option>)}
              </select>
              <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 pointer-events-none" />
            </div>

            <div className="relative shrink-0">
              <select value={sortBy} onChange={(e) => setSortBy(e.target.value)} className="filter-pill appearance-none pr-8 cursor-pointer">
                <option value="newest">Newest</option>
                <option value="price-low">Price: Low to High</option>
                <option value="price-high">Price: High to Low</option>
              </select>
              <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 pointer-events-none" />
            </div>

            {hasActiveFilters && (
              <button onClick={clearFilters} className="text-sm text-primary font-medium hover:underline shrink-0">Clear all</button>
            )}
          </div>
        </div>
      </div>

      <main className="container mx-auto px-4 py-6">
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-xl font-semibold">
            {loading ? 'Loading…' : `${filteredProperties.length} properties ${location !== 'All Locations' ? `in ${location}` : 'in Kigali'}`}
          </h1>
          <Button variant="outline" className="hidden md:flex gap-2" onClick={() => setShowMap(!showMap)}>
            <Map className="w-4 h-4" />
            {showMap ? 'Hide map' : 'Show map'}
          </Button>
        </div>

        <div className={cn('grid gap-6', showMap ? 'lg:grid-cols-2' : '')}>
          <div className={cn('grid gap-6', showMap ? 'grid-cols-1 sm:grid-cols-2' : 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4')}>
            {loading
              ? Array.from({ length: 8 }).map((_, i) => (
                  <div key={i} className="space-y-3">
                    <Skeleton className="aspect-[4/3] rounded-xl" />
                    <Skeleton className="h-4 w-3/4" />
                  </div>
                ))
              : filteredProperties.map((property, idx) => (
                  <PropertyCard
                    key={property.id}
                    property={property}
                    className="animate-fade-in"
                    style={{ animationDelay: `${idx * 0.05}s` }}
                  />
                ))}
          </div>

          {showMap && (
            <div className="hidden lg:block sticky top-40 h-[calc(100vh-200px)] rounded-2xl overflow-hidden bg-secondary">
              <div className="w-full h-full flex items-center justify-center text-muted-foreground">
                <div className="text-center">
                  <Map className="w-16 h-16 mx-auto mb-4 opacity-50" />
                  <p className="font-medium">Map View</p>
                  <p className="text-sm">Interactive map coming soon</p>
                </div>
              </div>
            </div>
          )}
        </div>

        {!loading && filteredProperties.length === 0 && (
          <div className="text-center py-16">
            <div className="w-24 h-24 rounded-full bg-secondary flex items-center justify-center mx-auto mb-6">
              <SlidersHorizontal className="w-10 h-10 text-muted-foreground" />
            </div>
            <h2 className="text-xl font-semibold mb-2">No properties found</h2>
            <p className="text-muted-foreground mb-6">Try adjusting your filters to see more results</p>
            <Button onClick={clearFilters}>Clear all filters</Button>
          </div>
        )}
      </main>

      <Footer />
    </div>
  );
}
