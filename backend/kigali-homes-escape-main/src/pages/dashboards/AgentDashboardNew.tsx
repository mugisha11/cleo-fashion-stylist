import { Building2, DollarSign, Eye, Star, TrendingUp, MessageSquare, ArrowUpRight, PlusCircle } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import DashboardLayout from '@/components/DashboardLayout';
import { Link } from 'react-router-dom';

const stats = [
  { title: 'Active Listings', value: '18', change: '+3', icon: Building2 },
  { title: 'Total Views', value: '4,729', change: '+22%', icon: Eye },
  { title: 'Inquiries', value: '34', change: '+8', icon: MessageSquare },
  { title: 'Avg Rating', value: '4.8', change: '+0.2', icon: Star },
];

const recentInquiries = [
  { client: 'Patrick M.', property: 'Modern Villa in Nyarutarama', time: '2 hours ago', status: 'New' },
  { client: 'Grace U.', property: '3BR Apartment in Kacyiru', time: '5 hours ago', status: 'Replied' },
  { client: 'David N.', property: 'Luxury Penthouse', time: 'Yesterday', status: 'New' },
  { client: 'Claudine I.', property: 'Cozy Bungalow in Kibagabaga', time: 'Yesterday', status: 'Replied' },
];

const listingPerformance = [
  { name: 'Modern Villa', views: 892, inquiries: 12, percent: 90 },
  { name: '3BR Apartment', views: 654, inquiries: 8, percent: 66 },
  { name: 'Luxury Penthouse', views: 521, inquiries: 6, percent: 52 },
  { name: 'Cozy Bungalow', views: 340, inquiries: 4, percent: 34 },
];

export default function AgentDashboardNew() {
  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold">Agent Dashboard</h1>
            <p className="text-muted-foreground">Manage your listings and inquiries</p>
          </div>
          <Button className="rounded-xl gap-2" asChild>
            <Link to="/dashboard/agent/add"><PlusCircle className="w-4 h-4" /> Add Listing</Link>
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
          <Card className="rounded-2xl border-border/50">
            <CardHeader className="flex flex-row items-center justify-between pb-3">
              <CardTitle className="text-base font-semibold">Recent Inquiries</CardTitle>
              <Button variant="ghost" size="sm" className="gap-1 text-xs text-primary">
                View All <ArrowUpRight className="w-3 h-3" />
              </Button>
            </CardHeader>
            <CardContent className="p-0">
              <div className="divide-y divide-border/50">
                {recentInquiries.map((inq, i) => (
                  <div key={i} className="flex items-center justify-between px-5 py-3">
                    <div>
                      <p className="text-sm font-medium">{inq.client}</p>
                      <p className="text-xs text-muted-foreground">{inq.property} · {inq.time}</p>
                    </div>
                    <Badge variant={inq.status === 'New' ? 'default' : 'secondary'} className="text-[10px]">
                      {inq.status}
                    </Badge>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          <Card className="rounded-2xl border-border/50">
            <CardHeader className="flex flex-row items-center justify-between pb-3">
              <CardTitle className="text-base font-semibold">Listing Performance</CardTitle>
              <Button variant="ghost" size="sm" className="gap-1 text-xs text-primary">
                Details <ArrowUpRight className="w-3 h-3" />
              </Button>
            </CardHeader>
            <CardContent className="space-y-4">
              {listingPerformance.map((l) => (
                <div key={l.name} className="space-y-1.5">
                  <div className="flex items-center justify-between text-sm">
                    <span className="font-medium">{l.name}</span>
                    <span className="text-muted-foreground">{l.views} views · {l.inquiries} inquiries</span>
                  </div>
                  <Progress value={l.percent} className="h-2" />
                </div>
              ))}
            </CardContent>
          </Card>
        </div>

        {/* Earnings overview */}
        <Card className="rounded-2xl border-border/50">
          <CardHeader>
            <CardTitle className="text-base font-semibold">Monthly Earnings</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div className="rounded-xl bg-muted/50 p-4 text-center">
                <p className="text-2xl font-bold text-primary">RWF 2.4M</p>
                <p className="text-xs text-muted-foreground mt-1">This Month</p>
              </div>
              <div className="rounded-xl bg-muted/50 p-4 text-center">
                <p className="text-2xl font-bold">RWF 1.8M</p>
                <p className="text-xs text-muted-foreground mt-1">Last Month</p>
              </div>
              <div className="rounded-xl bg-muted/50 p-4 text-center">
                <p className="text-2xl font-bold text-chart-2">+33%</p>
                <p className="text-xs text-muted-foreground mt-1">Growth</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </DashboardLayout>
  );
}
