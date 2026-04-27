import { Heart, Search, MessageSquare, Calendar, Eye, ArrowUpRight, Building2 } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import DashboardLayout from '@/components/DashboardLayout';
import { Link } from 'react-router-dom';

const stats = [
  { title: 'Saved Properties', value: '12', icon: Heart },
  { title: 'Properties Viewed', value: '47', icon: Eye },
  { title: 'Active Inquiries', value: '5', icon: MessageSquare },
  { title: 'Appointments', value: '2', icon: Calendar },
];

const savedProperties = [
  { name: 'Modern Villa in Nyarutarama', price: 'RWF 850K/mo', beds: 4, type: 'Rent', image: 'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=300' },
  { name: 'Luxury Apartment in Kacyiru', price: 'RWF 120M', beds: 3, type: 'Sale', image: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=300' },
  { name: 'Cozy Home in Kibagabaga', price: 'RWF 450K/mo', beds: 2, type: 'Rent', image: 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=300' },
];

const recentInquiries = [
  { property: 'Modern Villa in Nyarutarama', agent: 'Jean Baptiste', time: '2 hours ago', status: 'Replied' },
  { property: 'Luxury Apartment in Kacyiru', agent: 'Amina K.', time: 'Yesterday', status: 'Pending' },
  { property: '3BR House in Gacuriro', agent: 'Patrick M.', time: '3 days ago', status: 'Replied' },
];

export default function ClientDashboard() {
  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold">Welcome back!</h1>
            <p className="text-muted-foreground">Find your perfect home in Kigali</p>
          </div>
          <Button className="rounded-xl gap-2" asChild>
            <Link to="/listings"><Search className="w-4 h-4" /> Browse Properties</Link>
          </Button>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {stats.map((s) => (
            <Card key={s.title} className="rounded-2xl border-border/50">
              <CardContent className="p-5">
                <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center mb-3">
                  <s.icon className="w-5 h-5 text-primary" />
                </div>
                <p className="text-2xl font-bold">{s.value}</p>
                <p className="text-xs text-muted-foreground mt-1">{s.title}</p>
              </CardContent>
            </Card>
          ))}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Saved Properties */}
          <Card className="rounded-2xl border-border/50">
            <CardHeader className="flex flex-row items-center justify-between pb-3">
              <CardTitle className="text-base font-semibold">Saved Properties</CardTitle>
              <Button variant="ghost" size="sm" className="gap-1 text-xs text-primary" asChild>
                <Link to="/favorites">View All <ArrowUpRight className="w-3 h-3" /></Link>
              </Button>
            </CardHeader>
            <CardContent className="p-0">
              <div className="divide-y divide-border/50">
                {savedProperties.map((p) => (
                  <div key={p.name} className="flex items-center gap-3 px-5 py-3">
                    <img src={p.image} alt={p.name} className="w-14 h-14 rounded-xl object-cover shrink-0" />
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium truncate">{p.name}</p>
                      <p className="text-xs text-muted-foreground">{p.beds} beds · {p.price}</p>
                    </div>
                    <Badge variant={p.type === 'Sale' ? 'default' : 'secondary'} className="text-[10px] shrink-0">{p.type}</Badge>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Recent Inquiries */}
          <Card className="rounded-2xl border-border/50">
            <CardHeader className="flex flex-row items-center justify-between pb-3">
              <CardTitle className="text-base font-semibold">My Inquiries</CardTitle>
              <Button variant="ghost" size="sm" className="gap-1 text-xs text-primary">
                View All <ArrowUpRight className="w-3 h-3" />
              </Button>
            </CardHeader>
            <CardContent className="p-0">
              <div className="divide-y divide-border/50">
                {recentInquiries.map((inq, i) => (
                  <div key={i} className="px-5 py-3">
                    <div className="flex items-center justify-between">
                      <p className="text-sm font-medium">{inq.property}</p>
                      <Badge variant={inq.status === 'Replied' ? 'default' : 'secondary'} className="text-[10px]">{inq.status}</Badge>
                    </div>
                    <p className="text-xs text-muted-foreground mt-1">Agent: {inq.agent} · {inq.time}</p>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Recommended */}
        <Card className="rounded-2xl border-border/50">
          <CardHeader>
            <CardTitle className="text-base font-semibold">Recommended for You</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              {savedProperties.map((p) => (
                <div key={p.name} className="rounded-xl overflow-hidden border border-border/50 hover:shadow-md transition-shadow">
                  <img src={p.image} alt={p.name} className="w-full h-32 object-cover" />
                  <div className="p-3">
                    <p className="text-sm font-medium truncate">{p.name}</p>
                    <p className="text-xs text-muted-foreground">{p.beds} beds</p>
                    <p className="text-sm font-bold text-primary mt-1">{p.price}</p>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    </DashboardLayout>
  );
}
