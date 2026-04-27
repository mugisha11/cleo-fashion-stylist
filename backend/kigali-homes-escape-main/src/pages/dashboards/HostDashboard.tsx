import { Building2, DollarSign, Calendar, Star, TrendingUp, ArrowUpRight } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import DashboardLayout from '@/components/DashboardLayout';
import { Link } from 'react-router-dom';

const stats = [
  { title: 'My Properties', value: '6', change: '+1', icon: Building2 },
  { title: 'Monthly Earnings', value: 'RWF 3.2M', change: '+18%', icon: DollarSign },
  { title: 'Active Bookings', value: '8', change: '+2', icon: Calendar },
  { title: 'Avg Rating', value: '4.9', change: '+0.1', icon: Star },
];

const properties = [
  { name: 'Villa in Nyarutarama', status: 'Occupied', revenue: 'RWF 850K', occupancy: 92 },
  { name: 'Apartment in Kacyiru', status: 'Available', revenue: 'RWF 420K', occupancy: 78 },
  { name: 'House in Gacuriro', status: 'Occupied', revenue: 'RWF 380K', occupancy: 85 },
  { name: 'Studio in Kimihurura', status: 'Maintenance', revenue: 'RWF 0', occupancy: 0 },
];

const upcomingBookings = [
  { guest: 'John M.', property: 'Villa in Nyarutarama', checkin: 'Mar 25', checkout: 'Apr 10', status: 'Confirmed' },
  { guest: 'Sarah K.', property: 'Apartment in Kacyiru', checkin: 'Mar 28', checkout: 'Apr 5', status: 'Pending' },
  { guest: 'Peter N.', property: 'House in Gacuriro', checkin: 'Apr 1', checkout: 'Apr 15', status: 'Confirmed' },
];

export default function HostDashboard() {
  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold">Host Dashboard</h1>
            <p className="text-muted-foreground">Manage your properties and bookings</p>
          </div>
          <Button className="rounded-xl gap-2" asChild>
            <Link to="/dashboard/host/add"><Building2 className="w-4 h-4" /> List Property</Link>
          </Button>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {stats.map((s) => (
            <Card key={s.title} className="rounded-2xl border-border/50">
              <CardContent className="p-5">
                <div className="flex items-center justify-between mb-3">
                  <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center">
                    <s.icon className="w-5 h-5 text-primary" />
                  </div>
                  <span className="text-xs font-medium text-chart-2 flex items-center gap-1">
                    <TrendingUp className="w-3 h-3" />{s.change}
                  </span>
                </div>
                <p className="text-2xl font-bold">{s.value}</p>
                <p className="text-xs text-muted-foreground mt-1">{s.title}</p>
              </CardContent>
            </Card>
          ))}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Properties Overview */}
          <Card className="rounded-2xl border-border/50">
            <CardHeader className="flex flex-row items-center justify-between pb-3">
              <CardTitle className="text-base font-semibold">My Properties</CardTitle>
              <Button variant="ghost" size="sm" className="gap-1 text-xs text-primary">
                Manage <ArrowUpRight className="w-3 h-3" />
              </Button>
            </CardHeader>
            <CardContent className="space-y-4">
              {properties.map((p) => (
                <div key={p.name} className="space-y-2">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium">{p.name}</p>
                      <p className="text-xs text-muted-foreground">{p.revenue}/mo</p>
                    </div>
                    <Badge variant={p.status === 'Occupied' ? 'default' : p.status === 'Available' ? 'secondary' : 'outline'} className="text-[10px]">
                      {p.status}
                    </Badge>
                  </div>
                  <Progress value={p.occupancy} className="h-2" />
                </div>
              ))}
            </CardContent>
          </Card>

          {/* Upcoming Bookings */}
          <Card className="rounded-2xl border-border/50">
            <CardHeader className="flex flex-row items-center justify-between pb-3">
              <CardTitle className="text-base font-semibold">Upcoming Bookings</CardTitle>
              <Button variant="ghost" size="sm" className="gap-1 text-xs text-primary">
                View All <ArrowUpRight className="w-3 h-3" />
              </Button>
            </CardHeader>
            <CardContent className="p-0">
              <div className="divide-y divide-border/50">
                {upcomingBookings.map((b, i) => (
                  <div key={i} className="px-5 py-3">
                    <div className="flex items-center justify-between">
                      <p className="text-sm font-medium">{b.guest}</p>
                      <Badge variant={b.status === 'Confirmed' ? 'default' : 'secondary'} className="text-[10px]">{b.status}</Badge>
                    </div>
                    <p className="text-xs text-muted-foreground mt-1">{b.property}</p>
                    <p className="text-xs text-muted-foreground">{b.checkin} → {b.checkout}</p>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </DashboardLayout>
  );
}
