import { Link } from 'react-router-dom';
import { ArrowRight } from 'lucide-react';

const neighborhoods = [
  {
    name: 'Nyarutarama',
    image: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=600',
    properties: 45,
    description: 'Upscale residential area',
  },
  {
    name: 'Kiyovu',
    image: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=600',
    properties: 32,
    description: 'Embassy district',
  },
  {
    name: 'Kimihurura',
    image: 'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=600',
    properties: 28,
    description: 'Family-friendly area',
  },
  {
    name: 'Gacuriro',
    image: 'https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?w=600',
    properties: 38,
    description: 'Modern developments',
  },
];

export function NeighborhoodSection() {
  return (
    <section className="py-16 md:py-24 bg-secondary/50">
      <div className="container mx-auto px-4">
        <div className="text-center mb-12">
          <h2 className="text-2xl md:text-3xl font-bold mb-3">
            Explore Kigali Neighborhoods
          </h2>
          <p className="text-muted-foreground max-w-2xl mx-auto">
            Discover the unique character of each neighborhood and find the perfect location for your lifestyle
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {neighborhoods.map((neighborhood, idx) => (
            <Link
              key={neighborhood.name}
              to={`/listings?location=${neighborhood.name}`}
              className="group relative overflow-hidden rounded-2xl aspect-[3/4] animate-fade-in"
              style={{ animationDelay: `${idx * 0.1}s` }}
            >
              <img 
                src={neighborhood.image} 
                alt={neighborhood.name}
                className="absolute inset-0 w-full h-full object-cover transition-transform duration-500 group-hover:scale-110"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/20 to-transparent" />
              
              <div className="absolute bottom-0 left-0 right-0 p-6 text-white">
                <h3 className="text-xl font-bold mb-1">{neighborhood.name}</h3>
                <p className="text-white/80 text-sm mb-2">{neighborhood.description}</p>
                <div className="flex items-center gap-2 text-sm">
                  <span>{neighborhood.properties} properties</span>
                  <ArrowRight className="w-4 h-4 transition-transform group-hover:translate-x-1" />
                </div>
              </div>
            </Link>
          ))}
        </div>
      </div>
    </section>
  );
}
