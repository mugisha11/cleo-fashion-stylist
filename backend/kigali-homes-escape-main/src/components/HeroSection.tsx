import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Search, ChevronDown } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { neighborhoods, bedroomOptions } from '@/lib/properties';
import heroImage from '@/assets/hero-kigali.jpg';

export function HeroSection() {
  const navigate = useNavigate();
  const [location, setLocation] = useState('');
  const [propertyType, setPropertyType] = useState<'rent' | 'sale'>('rent');
  const [bedrooms, setBedrooms] = useState('Any');

  const handleSearch = () => {
    const params = new URLSearchParams();
    if (location && location !== 'All Locations') params.set('location', location);
    if (propertyType) params.set('type', propertyType);
    if (bedrooms !== 'Any') params.set('bedrooms', bedrooms);
    navigate(`/listings?${params.toString()}`);
  };

  return (
    <section className="relative h-[70vh] min-h-[500px] max-h-[700px] flex items-center justify-center overflow-hidden">
      {/* Background Image */}
      <div className="absolute inset-0">
        <img 
          src={heroImage} 
          alt="Beautiful homes in Kigali"
          className="w-full h-full object-cover"
        />
        <div className="absolute inset-0 gradient-hero" />
      </div>

      {/* Content */}
      <div className="relative z-10 container mx-auto px-4 text-center">
        <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold text-white mb-4 animate-fade-up">
          Find Your Dream Home in Kigali
        </h1>
        <p className="text-lg md:text-xl text-white/90 mb-8 max-w-2xl mx-auto animate-fade-up" style={{ animationDelay: '0.1s' }}>
          Discover beautiful properties for rent and sale in Rwanda's vibrant capital
        </p>

        {/* Search Box */}
        <div 
          className="bg-background rounded-2xl p-4 md:p-6 max-w-4xl mx-auto animate-fade-up shadow-2xl"
          style={{ animationDelay: '0.2s' }}
        >
          {/* Property Type Toggle */}
          <div className="flex justify-center mb-6">
            <div className="inline-flex rounded-full bg-secondary p-1">
              <button
                onClick={() => setPropertyType('rent')}
                className={`px-6 py-2 rounded-full text-sm font-medium transition-all ${
                  propertyType === 'rent' 
                    ? 'bg-foreground text-background' 
                    : 'text-muted-foreground hover:text-foreground'
                }`}
              >
                Rent
              </button>
              <button
                onClick={() => setPropertyType('sale')}
                className={`px-6 py-2 rounded-full text-sm font-medium transition-all ${
                  propertyType === 'sale' 
                    ? 'bg-foreground text-background' 
                    : 'text-muted-foreground hover:text-foreground'
                }`}
              >
                Buy
              </button>
            </div>
          </div>

          {/* Search Fields */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {/* Location */}
            <div className="relative">
              <label className="block text-xs font-semibold text-foreground mb-1.5 text-left uppercase tracking-wide">
                Location
              </label>
              <div className="relative">
                <select
                  value={location}
                  onChange={(e) => setLocation(e.target.value)}
                  className="w-full appearance-none bg-secondary rounded-xl px-4 py-3 pr-10 text-foreground focus:outline-none focus:ring-2 focus:ring-primary cursor-pointer"
                >
                  {neighborhoods.map(n => (
                    <option key={n} value={n}>{n}</option>
                  ))}
                </select>
                <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground pointer-events-none" />
              </div>
            </div>

            {/* Bedrooms */}
            <div className="relative">
              <label className="block text-xs font-semibold text-foreground mb-1.5 text-left uppercase tracking-wide">
                Bedrooms
              </label>
              <div className="relative">
                <select
                  value={bedrooms}
                  onChange={(e) => setBedrooms(e.target.value)}
                  className="w-full appearance-none bg-secondary rounded-xl px-4 py-3 pr-10 text-foreground focus:outline-none focus:ring-2 focus:ring-primary cursor-pointer"
                >
                  {bedroomOptions.map(b => (
                    <option key={b} value={b}>{b === 'Any' ? 'Any bedrooms' : `${b} bedroom${b === '1' ? '' : 's'}`}</option>
                  ))}
                </select>
                <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground pointer-events-none" />
              </div>
            </div>

            {/* Search Button */}
            <div className="flex items-end">
              <Button 
                onClick={handleSearch}
                className="w-full h-12 rounded-xl text-base font-semibold gap-2"
                size="lg"
              >
                <Search className="w-5 h-5" />
                Search
              </Button>
            </div>
          </div>
        </div>

        {/* Stats */}
        <div 
          className="flex flex-wrap justify-center gap-8 md:gap-16 mt-10 animate-fade-up"
          style={{ animationDelay: '0.3s' }}
        >
          <div className="text-center">
            <p className="text-3xl md:text-4xl font-bold text-white">500+</p>
            <p className="text-white/70 text-sm">Properties Listed</p>
          </div>
          <div className="text-center">
            <p className="text-3xl md:text-4xl font-bold text-white">50+</p>
            <p className="text-white/70 text-sm">Verified Agents</p>
          </div>
          <div className="text-center">
            <p className="text-3xl md:text-4xl font-bold text-white">1000+</p>
            <p className="text-white/70 text-sm">Happy Clients</p>
          </div>
        </div>
      </div>
    </section>
  );
}
