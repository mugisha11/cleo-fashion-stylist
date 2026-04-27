import { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Plus, Pencil, Trash2, Eye, Home, DollarSign, MapPin, BedDouble, Bath, X, Image as ImageIcon, ArrowLeft } from 'lucide-react';
import { Navbar } from '@/components/Navbar';
import { Footer } from '@/components/Footer';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';
import { neighborhoods, formatPrice, type Property } from '@/lib/properties';
import { fetchProperties } from '@/lib/queries';
import { useAuth } from '@/contexts/AuthContext';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';

const emptyForm = {
  title: '', description: '', neighborhood: 'Nyarutarama', address: '',
  price: 0, priceType: 'rent' as 'rent' | 'sale', bedrooms: 1, bathrooms: 1, area: 0,
  images: [] as string[], amenities: [] as string[], featured: false,
};

const amenityOptions = [
  'Swimming Pool', 'Garden', 'Garage', 'Security', 'Generator', 'Solar Panels',
  'Smart Home', 'Gym', 'Balcony', 'Parking', '24/7 Water', 'Internet',
  'Air Conditioning', 'Furnished', 'Staff Quarters', 'Storage', 'Terrace',
  'Concierge', 'Elevator', 'Cinema', 'Wine Cellar',
];

export default function AgentDashboard() {
  const { user, loading: authLoading } = useAuth();
  const { toast } = useToast();
  const navigate = useNavigate();

  const [listings, setListings] = useState<Property[]>([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [deleteId, setDeleteId] = useState<string | null>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState(emptyForm);
  const [imageUrl, setImageUrl] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!authLoading && !user) navigate('/login');
  }, [authLoading, user, navigate]);

  const refresh = async () => {
    if (!user) return;
    setLoading(true);
    const data = await fetchProperties({ ownerId: user.id });
    setListings(data);
    setLoading(false);
  };
  useEffect(() => { if (user) refresh(); /* eslint-disable-next-line */ }, [user]);

  const resetForm = () => { setForm(emptyForm); setEditingId(null); setImageUrl(''); };
  const openAdd = () => { resetForm(); setDialogOpen(true); };
  const openEdit = (p: Property) => {
    setEditingId(p.id);
    setForm({
      title: p.title, description: p.description, neighborhood: p.neighborhood, address: p.location,
      price: p.price, priceType: p.priceType, bedrooms: p.bedrooms, bathrooms: p.bathrooms, area: p.area,
      images: [...p.images], amenities: [...p.amenities], featured: p.featured,
    });
    setDialogOpen(true);
  };

  const addImage = () => {
    if (imageUrl.trim()) { setForm((f) => ({ ...f, images: [...f.images, imageUrl.trim()] })); setImageUrl(''); }
  };
  const removeImage = (idx: number) => setForm((f) => ({ ...f, images: f.images.filter((_, i) => i !== idx) }));
  const toggleAmenity = (a: string) => setForm((f) => ({
    ...f, amenities: f.amenities.includes(a) ? f.amenities.filter((x) => x !== a) : [...f.amenities, a]
  }));

  const handleSave = async () => {
    if (!user) return;
    if (!form.title || !form.price || form.images.length === 0) {
      toast({ title: 'Missing fields', description: 'Title, price, and at least one image required.', variant: 'destructive' });
      return;
    }
    setSaving(true);
    const payload = {
      title: form.title, description: form.description, neighborhood: form.neighborhood,
      address: form.address, price: form.price, price_type: form.priceType,
      bedrooms: form.bedrooms, bathrooms: form.bathrooms, area_sqm: form.area || null,
      images: form.images, amenities: form.amenities, is_featured: form.featured,
    };
    const { error } = editingId
      ? await supabase.from('properties').update(payload).eq('id', editingId)
      : await supabase.from('properties').insert({ ...payload, owner_id: user.id });
    setSaving(false);
    if (error) { toast({ title: 'Save failed', description: error.message, variant: 'destructive' }); return; }
    toast({ title: editingId ? 'Property updated' : 'Property added' });
    setDialogOpen(false); resetForm(); refresh();
  };

  const handleDelete = async () => {
    if (!deleteId) return;
    const { error } = await supabase.from('properties').delete().eq('id', deleteId);
    if (error) { toast({ title: 'Delete failed', description: error.message, variant: 'destructive' }); }
    else { toast({ title: 'Property deleted' }); refresh(); }
    setDeleteId(null);
  };

  const stats = {
    total: listings.length,
    forSale: listings.filter((l) => l.priceType === 'sale').length,
    forRent: listings.filter((l) => l.priceType === 'rent').length,
    featured: listings.filter((l) => l.featured).length,
  };

  return (
    <div className="min-h-screen bg-background">
      <Navbar />
      <main className="container mx-auto px-4 py-8">
        <Link to="/" className="inline-flex items-center gap-2 text-muted-foreground hover:text-foreground mb-6 transition-colors">
          <ArrowLeft className="w-4 h-4" /> Back to home
        </Link>

        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-8">
          <div>
            <h1 className="text-2xl md:text-3xl font-bold">My Listings</h1>
            <p className="text-muted-foreground mt-1">Manage your property listings</p>
          </div>
          <Button onClick={openAdd} className="rounded-xl gap-2"><Plus className="w-4 h-4" /> Add Property</Button>
        </div>

        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
          {[
            { label: 'Total', value: stats.total, icon: Home },
            { label: 'For Sale', value: stats.forSale, icon: DollarSign },
            { label: 'For Rent', value: stats.forRent, icon: MapPin },
            { label: 'Featured', value: stats.featured, icon: Eye },
          ].map((s) => (
            <div key={s.label} className="rounded-2xl border border-border bg-card p-5">
              <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center mb-2">
                <s.icon className="w-5 h-5 text-primary" />
              </div>
              <p className="text-2xl font-bold">{s.value}</p>
              <p className="text-sm text-muted-foreground">{s.label}</p>
            </div>
          ))}
        </div>

        {loading ? (
          <div className="space-y-4">{Array.from({ length: 3 }).map((_, i) => <Skeleton key={i} className="h-32 rounded-2xl" />)}</div>
        ) : listings.length === 0 ? (
          <div className="text-center py-20 rounded-2xl border border-dashed border-border">
            <Home className="w-12 h-12 text-muted-foreground mx-auto mb-4" />
            <h3 className="text-lg font-semibold mb-2">No listings yet</h3>
            <p className="text-muted-foreground mb-6">Start by adding your first property listing.</p>
            <Button onClick={openAdd} className="rounded-xl gap-2"><Plus className="w-4 h-4" /> Add Property</Button>
          </div>
        ) : (
          <div className="space-y-4">
            {listings.map((p) => (
              <div key={p.id} className="flex flex-col sm:flex-row gap-4 p-4 rounded-2xl border border-border bg-card hover:shadow-md transition-shadow">
                <div className="w-full sm:w-40 h-28 rounded-xl overflow-hidden shrink-0">
                  <img src={p.images[0]} alt={p.title} className="w-full h-full object-cover" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <h3 className="font-semibold truncate">{p.title}</h3>
                      <p className="text-sm text-muted-foreground flex items-center gap-1 mt-1"><MapPin className="w-3.5 h-3.5" /> {p.location}</p>
                    </div>
                    <Badge variant={p.priceType === 'sale' ? 'default' : 'secondary'} className="shrink-0">
                      {p.priceType === 'sale' ? 'For Sale' : 'For Rent'}
                    </Badge>
                  </div>
                  <div className="flex items-center gap-4 mt-3 text-sm text-muted-foreground">
                    <span className="font-semibold text-foreground">{formatPrice(p.price, p.priceType)}</span>
                    <span className="flex items-center gap-1"><BedDouble className="w-3.5 h-3.5" /> {p.bedrooms} beds</span>
                    <span className="flex items-center gap-1"><Bath className="w-3.5 h-3.5" /> {p.bathrooms} baths</span>
                    {p.area > 0 && <span>{p.area} m²</span>}
                  </div>
                </div>
                <div className="flex sm:flex-col gap-2 shrink-0">
                  <Button variant="outline" size="sm" className="rounded-xl gap-1.5" asChild>
                    <Link to={`/property/${p.id}`}><Eye className="w-3.5 h-3.5" /> View</Link>
                  </Button>
                  <Button variant="outline" size="sm" className="rounded-xl gap-1.5" onClick={() => openEdit(p)}>
                    <Pencil className="w-3.5 h-3.5" /> Edit
                  </Button>
                  <Button variant="outline" size="sm" className="rounded-xl gap-1.5 text-destructive hover:text-destructive" onClick={() => setDeleteId(p.id)}>
                    <Trash2 className="w-3.5 h-3.5" /> Delete
                  </Button>
                </div>
              </div>
            ))}
          </div>
        )}
      </main>

      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{editingId ? 'Edit Property' : 'Add New Property'}</DialogTitle>
          </DialogHeader>
          <div className="space-y-6 mt-4">
            <div>
              <label className="text-sm font-medium mb-1.5 block">Title</label>
              <Input value={form.title} onChange={(e) => setForm((f) => ({ ...f, title: e.target.value }))} placeholder="e.g. Modern Villa with Pool" />
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="text-sm font-medium mb-1.5 block">Address</label>
                <Input value={form.address} onChange={(e) => setForm((f) => ({ ...f, address: e.target.value }))} placeholder="e.g. KG 11 Ave, Kigali" />
              </div>
              <div>
                <label className="text-sm font-medium mb-1.5 block">Neighborhood</label>
                <Select value={form.neighborhood} onValueChange={(v) => setForm((f) => ({ ...f, neighborhood: v }))}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {neighborhoods.filter((n) => n !== 'All Locations').map((n) => <SelectItem key={n} value={n}>{n}</SelectItem>)}
                  </SelectContent>
                </Select>
              </div>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="text-sm font-medium mb-1.5 block">Price (RWF)</label>
                <Input type="number" value={form.price || ''} onChange={(e) => setForm((f) => ({ ...f, price: Number(e.target.value) }))} />
              </div>
              <div>
                <label className="text-sm font-medium mb-1.5 block">Listing Type</label>
                <Select value={form.priceType} onValueChange={(v: 'sale' | 'rent') => setForm((f) => ({ ...f, priceType: v }))}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="sale">For Sale</SelectItem>
                    <SelectItem value="rent">For Rent</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>
            <div className="grid grid-cols-3 gap-4">
              <div>
                <label className="text-sm font-medium mb-1.5 block">Bedrooms</label>
                <Input type="number" min={0} value={form.bedrooms} onChange={(e) => setForm((f) => ({ ...f, bedrooms: Number(e.target.value) }))} />
              </div>
              <div>
                <label className="text-sm font-medium mb-1.5 block">Bathrooms</label>
                <Input type="number" min={0} value={form.bathrooms} onChange={(e) => setForm((f) => ({ ...f, bathrooms: Number(e.target.value) }))} />
              </div>
              <div>
                <label className="text-sm font-medium mb-1.5 block">Area (m²)</label>
                <Input type="number" min={0} value={form.area || ''} onChange={(e) => setForm((f) => ({ ...f, area: Number(e.target.value) }))} />
              </div>
            </div>
            <div>
              <label className="text-sm font-medium mb-1.5 block">Description</label>
              <Textarea rows={4} value={form.description} onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))} />
            </div>
            <div>
              <label className="text-sm font-medium mb-1.5 block">Images</label>
              <div className="flex gap-2 mb-3">
                <Input placeholder="Paste image URL" value={imageUrl} onChange={(e) => setImageUrl(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && (e.preventDefault(), addImage())} />
                <Button type="button" variant="outline" onClick={addImage}><ImageIcon className="w-4 h-4" /></Button>
              </div>
              {form.images.length > 0 && (
                <div className="flex gap-2 flex-wrap">
                  {form.images.map((img, idx) => (
                    <div key={idx} className="relative w-20 h-20 rounded-lg overflow-hidden group">
                      <img src={img} alt="" className="w-full h-full object-cover" />
                      <button onClick={() => removeImage(idx)} className="absolute inset-0 bg-foreground/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                        <X className="w-4 h-4 text-background" />
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>
            <div>
              <label className="text-sm font-medium mb-1.5 block">Amenities</label>
              <div className="flex flex-wrap gap-2">
                {amenityOptions.map((a) => (
                  <button key={a} type="button" onClick={() => toggleAmenity(a)}
                    className={`filter-pill text-xs ${form.amenities.includes(a) ? 'active' : ''}`}>{a}</button>
                ))}
              </div>
            </div>
            <label className="flex items-center gap-3 cursor-pointer">
              <input type="checkbox" checked={form.featured} onChange={(e) => setForm((f) => ({ ...f, featured: e.target.checked }))} className="w-4 h-4 accent-primary" />
              <span className="text-sm font-medium">Mark as Featured</span>
            </label>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>Cancel</Button>
            <Button onClick={handleSave} disabled={saving}>{saving ? 'Saving…' : editingId ? 'Update' : 'Create'}</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={!!deleteId} onOpenChange={(o) => !o && setDeleteId(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle>Delete listing?</DialogTitle></DialogHeader>
          <p className="text-muted-foreground">This action cannot be undone.</p>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteId(null)}>Cancel</Button>
            <Button variant="destructive" onClick={handleDelete}>Delete</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Footer />
    </div>
  );
}
