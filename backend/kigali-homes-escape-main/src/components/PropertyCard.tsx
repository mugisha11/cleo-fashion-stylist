import { useState } from 'react';
import { Link } from 'react-router-dom';
import { Heart, Star, Bed, Bath, Square } from 'lucide-react';
import { Property, formatPrice } from '@/lib/properties';
import { useFavorites } from '@/contexts/FavoritesContext';
import { cn } from '@/lib/utils';

interface PropertyCardProps {
  property: Property;
  className?: string;
  style?: React.CSSProperties;
}

export function PropertyCard({ property, className, style }: PropertyCardProps) {
  const { toggleFavorite, isFavorite } = useFavorites();
  const [currentImage, setCurrentImage] = useState(0);
  const [isHovering, setIsHovering] = useState(false);
  const favorite = isFavorite(property.id);

  const handleFavoriteClick = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    toggleFavorite(property.id);
  };

  return (
    <Link 
      to={`/property/${property.id}`}
      className={cn("block group", className)}
      style={style}
      onMouseEnter={() => setIsHovering(true)}
      onMouseLeave={() => {
        setIsHovering(false);
        setCurrentImage(0);
      }}
    >
      <div className="property-card">
        {/* Image Container */}
        <div className="relative aspect-[4/3] overflow-hidden rounded-xl">
          <img 
            src={property.images[currentImage]} 
            alt={property.title}
            className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
          />
          
          {/* Favorite Button */}
          <button 
            onClick={handleFavoriteClick}
            className={cn(
              "heart-button",
              favorite && "active"
            )}
          >
            <Heart 
              className={cn(
                "w-5 h-5 transition-all",
                favorite ? "fill-primary text-primary animate-pulse-heart" : "text-foreground"
              )} 
            />
          </button>

          {/* Image Dots */}
          {property.images.length > 1 && isHovering && (
            <div className="absolute bottom-3 left-1/2 -translate-x-1/2 flex gap-1.5">
              {property.images.map((_, idx) => (
                <button
                  key={idx}
                  onMouseEnter={() => setCurrentImage(idx)}
                  className={cn(
                    "w-1.5 h-1.5 rounded-full transition-all",
                    currentImage === idx 
                      ? "bg-background w-2" 
                      : "bg-background/60 hover:bg-background/80"
                  )}
                />
              ))}
            </div>
          )}

          {/* Property Type Badge */}
          <div className="absolute top-3 left-3">
            <span className={cn(
              "px-3 py-1 rounded-full text-xs font-medium",
              property.priceType === 'rent' 
                ? "bg-background/90 text-foreground" 
                : "bg-primary text-primary-foreground"
            )}>
              For {property.priceType === 'rent' ? 'Rent' : 'Sale'}
            </span>
          </div>
        </div>

        {/* Content */}
        <div className="pt-3">
          <div className="flex items-start justify-between gap-2">
            <h3 className="font-semibold text-foreground line-clamp-1">
              {property.location}
            </h3>
            <div className="flex items-center gap-1 shrink-0">
              <Star className="w-4 h-4 fill-foreground" />
              <span className="text-sm font-medium">{property.rating}</span>
            </div>
          </div>
          
          <p className="text-muted-foreground text-sm mt-0.5 line-clamp-1">
            {property.title}
          </p>

          {/* Property Details */}
          <div className="flex items-center gap-3 mt-2 text-muted-foreground text-sm">
            <span className="flex items-center gap-1">
              <Bed className="w-4 h-4" />
              {property.bedrooms}
            </span>
            <span className="flex items-center gap-1">
              <Bath className="w-4 h-4" />
              {property.bathrooms}
            </span>
            <span className="flex items-center gap-1">
              <Square className="w-4 h-4" />
              {property.area}m²
            </span>
          </div>

          {/* Price */}
          <p className="mt-2">
            <span className="font-semibold">{formatPrice(property.price, property.priceType)}</span>
          </p>
        </div>
      </div>
    </Link>
  );
}
