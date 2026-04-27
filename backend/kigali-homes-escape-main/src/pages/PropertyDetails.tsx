import { useEffect, useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { ArrowLeft, Star, Heart, Share, Bed, Bath, Square, Wifi, Car, Shield, Zap, Droplet, Trees, Dumbbell, Tv, Wind, MapPin, Phone, MessageCircle } from 'lucide-react';
import { formatPrice, type Property } from '@/lib/properties';
import { fetchProperty } from '@/lib/queries';
import { useFavorites } from '@/contexts/FavoritesContext';
import { useAuth } from '@/contexts/AuthContext';
import { supabase } from '@/integrations/supabase/client';
import { Button } from '@/components/ui/button';
import { Navbar } from '@/components/Navbar';
import { Footer } from '@/components/Footer';
import { Skeleton } from '@/components/ui/skeleton';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Textarea } from '@/components/ui/textarea';
import { Input } from '@/components/ui/input';
import { useToast } from '@/hooks/use-toast';
import { cn } from '@/lib/utils';

const amenityIcons: Record<string, React.ReactNode> = {
  'Swimming Pool': <Droplet className="w-5 h-5" />, 'Pool': <Droplet className="w-5 h-5" />,
  'Garden': <Trees className="w-5 h-5" />, 'Garage': <Car className="w-5 h-5" />, 'Parking': <Car className="w-5 h-5" />,
  'Security': <Shield className="w-5 h-5" />, 'Generator': <Zap className="w-5 h-5" />, 'Solar Panels': <Zap className="w-5 h-5" />, 'Solar': <Zap className="w-5 h-5" />,
  'Internet': <Wifi className="w-5 h-5" />, 'Wifi': <Wifi className="w-5 h-5" />, 'Gym': <Dumbbell className="w-5 h-5" />,
  'Air Conditioning': <Wind className="w-5 h-5" />, 'Cinema': <Tv className="w-5 h-5" />,
};

export default function PropertyDetails() {
  const { id } = useParams();
  const { user, isAuthenticated } = useAuth();
  const { toggleFavorite, isFavorite } = useFavorites();
  const { toast } = useToast();
  const [property, setProperty] = useState<Property | null>(null);
  const [loading, setLoading] = useState(true);
  const [inquiryOpen, setInquiryOpen] = useState(false);
  const [message, setMessage] = useState('');
  const [phone, setPhone] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (!id) return;
    setLoading(true);
    fetchProperty(id).then(setProperty).finally(() => setLoading(false));
  }, [id]);

  const handleInquirySubmit = async () => {
    if (!isAuthenticated || !user) {
      toast({ title: 'Sign in required', description: 'Please log in to send an inquiry.', variant: 'destructive' });
      return;
    }
    if (!message.trim() || !property) return;
    setSubmitting(true);
    const { error } = await supabase.from('inquiries').insert({
      property_id: property.id,
      client_id: user.id,
      agent_id: property.agent.id,
      message: message.trim(),
      contact_phone: phone || null,
    });
    setSubmitting(false);
    if (error) {
      toast({ title: 'Failed to send', description: error.message, variant: 'destructive' });
    } else {
      toast({ title: 'Inquiry sent', description: 'The agent will get back to you soon.' });
      setInquiryOpen(false);
      setMessage('');
      setPhone('');
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-background">
        <Navbar />
        <main className="container mx-auto px-4 py-6 space-y-4">
          <Skeleton className="h-10 w-1/2" />
          <Skeleton className="h-96 rounded-2xl" />
        </main>
      </div>
    );
  }

  if (!property) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold mb-4">Property not found</h1>
          <Link to="/listings" className="text-primary hover:underline">Back to listings</Link>
        </div>
      </div>
    );
  }

  const favorite = isFavorite(property.id);

  return (
    <div className="min-h-screen bg-background">
      <Navbar />
      <main className="container mx-auto px-4 py-6">
        <Link to="/listings" className="inline-flex items-center gap-2 text-muted-foreground hover:text-foreground mb-6 transition-colors">
          <ArrowLeft className="w-4 h-4" /> Back to search
        </Link>

        <div className="flex flex-col lg:flex-row lg:items-start lg:justify-between gap-4 mb-6">
          <div>
            <h1 className="text-2xl md:text-3xl font-bold mb-2">{property.title}</h1>
            <div className="flex flex-wrap items-center gap-4 text-muted-foreground">
              <div className="flex items-center gap-1">
                <Star className="w-4 h-4 fill-foreground text-foreground" />
                <span className="font-medium text-foreground">{property.rating || '—'}</span>
                <span>·</span>
                <span className="underline">{property.reviews} reviews</span>
              </div>
              <div className="flex items-center gap-1">
                <MapPin className="w-4 h-4" />
                <span>{property.location}</span>
              </div>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <button className="flex items-center gap-2 px-4 py-2 rounded-lg hover:bg-secondary transition-colors">
              <Share className="w-4 h-4" /> <span className="font-medium underline">Share</span>
            </button>
            <button onClick={() => toggleFavorite(property.id)} className="flex items-center gap-2 px-4 py-2 rounded-lg hover:bg-secondary transition-colors">
              <Heart className={cn('w-4 h-4', favorite && 'fill-primary text-primary')} />
              <span className="font-medium underline">{favorite ? 'Saved' : 'Save'}</span>
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-4 gap-2 mb-8 rounded-2xl overflow-hidden">
          <div className="md:col-span-2 md:row-span-2">
            <img src={property.images[0]} alt={property.title} className="w-full h-full object-cover aspect-square md:aspect-auto" />
          </div>
          {property.images.slice(1, 5).map((img, idx) => (
            <div key={idx} className="hidden md:block">
              <img src={img} alt={`${property.title} ${idx + 2}`} className="w-full h-full object-cover aspect-square" />
            </div>
          ))}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-12">
          <div className="lg:col-span-2">
            <div className="flex items-start justify-between pb-6 border-b border-border">
              <div>
                <h2 className="text-xl font-semibold mb-2">
                  {property.priceType === 'rent' ? 'For Rent' : 'For Sale'} in {property.neighborhood}
                </h2>
                <div className="flex items-center gap-4 text-muted-foreground">
                  <span className="flex items-center gap-1"><Bed className="w-4 h-4" /> {property.bedrooms} bedrooms</span>
                  <span className="flex items-center gap-1"><Bath className="w-4 h-4" /> {property.bathrooms} bathrooms</span>
                  {property.area > 0 && <span className="flex items-center gap-1"><Square className="w-4 h-4" /> {property.area}m²</span>}
                </div>
              </div>
              <img src={property.agent.image} alt={property.agent.name} className="w-14 h-14 rounded-full object-cover" />
            </div>

            <div className="py-6 border-b border-border">
              <h3 className="text-lg font-semibold mb-4">About this property</h3>
              <p className="text-muted-foreground leading-relaxed">{property.description}</p>
            </div>

            {property.amenities.length > 0 && (
              <div className="py-6 border-b border-border">
                <h3 className="text-lg font-semibold mb-4">What this place offers</h3>
                <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                  {property.amenities.map((amenity) => (
                    <div key={amenity} className="flex items-center gap-3 py-2">
                      {amenityIcons[amenity] || <Square className="w-5 h-5" />} <span>{amenity}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>

          <div className="lg:col-span-1">
            <div className="agent-card sticky top-24">
              <div className="text-2xl font-bold mb-1">{formatPrice(property.price, property.priceType)}</div>
              <p className="text-muted-foreground text-sm mb-6">{property.priceType === 'rent' ? 'per month' : 'total price'}</p>

              <div className="border-t border-border pt-6 mb-6">
                <div className="flex items-center gap-4 mb-4">
                  <img src={property.agent.image} alt={property.agent.name} className="w-14 h-14 rounded-full object-cover" />
                  <div>
                    <p className="font-semibold">{property.agent.name}</p>
                    <p className="text-sm text-muted-foreground">Property Agent</p>
                  </div>
                </div>
              </div>

              <div className="space-y-3">
                <a href={`https://wa.me/${property.agent.whatsapp}`} target="_blank" rel="noopener noreferrer">
                  <Button className="w-full gap-2 bg-[#25D366] hover:bg-[#20BD5A] text-white" size="lg">
                    <MessageCircle className="w-5 h-5" /> WhatsApp
                  </Button>
                </a>
                <a href={`tel:${property.agent.phone}`}>
                  <Button variant="outline" className="w-full gap-2 mt-3" size="lg">
                    <Phone className="w-5 h-5" /> {property.agent.phone}
                  </Button>
                </a>
                <Button variant="secondary" className="w-full" size="lg" onClick={() => setInquiryOpen(true)}>
                  Send Inquiry
                </Button>
              </div>
            </div>
          </div>
        </div>
      </main>

      <Dialog open={inquiryOpen} onOpenChange={setInquiryOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Contact {property.agent.name}</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 mt-4">
            <div>
              <label className="text-sm font-medium mb-1.5 block">Your phone (optional)</label>
              <Input placeholder="+250 …" value={phone} onChange={(e) => setPhone(e.target.value)} />
            </div>
            <div>
              <label className="text-sm font-medium mb-1.5 block">Message</label>
              <Textarea rows={5} placeholder="Hi, I'm interested in this property…" value={message} onChange={(e) => setMessage(e.target.value)} />
            </div>
            <Button className="w-full" onClick={handleInquirySubmit} disabled={submitting || !message.trim()}>
              {submitting ? 'Sending…' : 'Send inquiry'}
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      <Footer />
    </div>
  );
}
