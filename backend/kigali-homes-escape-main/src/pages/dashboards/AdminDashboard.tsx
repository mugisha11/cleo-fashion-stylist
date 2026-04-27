import { Building2, Users, UserCheck, DollarSign, TrendingUp, TrendingDown, Eye, ArrowUpRight } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import DashboardLayout from '@/components/DashboardLayout';

const stats = [
  { title: 'Total Properties', value: '2,847', change: '+12.5%', trend: 'up', icon: Building2 },
  { title: 'Active Users', value: '14,238', change: '+8.2%', trend: 'up', icon: Users },
  { title: 'Verified Agents', value: '342', change: '+5.1%', trend: 'up', icon: UserCheck },
  { title: 'Revenue (RWF)', value: '24.8M', change: '-2.3%', trend: 'down', icon: DollarSign },
];

const recentUsers = [
  { name: 'Amina K.', role: 'Agent', date: 'Today', status: 'Active' },
  { name: 'Patrick M.', role: 'Client', date: 'Today', status: 'Active' },
  { name: 'Grace U.', role: 'Host', date: 'Yesterday', status: 'Pending' },
  { name: 'David N.', role: 'Agent', date: 'Yesterday', status: 'Active' },
  { name: 'Claudine I.', role: 'Client', date: '2 days ago', status: 'Active' },
];

const topNeighborhoods = [
  { name: 'Nyarutarama', listings: 342, percent: 85 },
  { name: 'Kacyiru', listings: 285, percent: 71 },
  { name: 'Kimihurura', listings: 198, percent: 50 },
  { name: 'Gacuriro', listings: 167, percent: 42 },
  { name: 'Kibagabaga', listings: 123, percent: 31 },
];

export default function AdminDashboard() {
  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold">Admin Overview</h1>
          <p className="text-muted-foreground">Platform performance at a glance</p>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {stats.map((s) => (
            <Card key={s.title} className="rounded-2xl border-border/50">
              <CardContent className="p-5">
                <div className="flex items-center justify-between mb-3">
                  <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center">
                    <s.icon className="w-5 h-5 text-primary" />
                  </div>
                  <div className={`flex items-center gap-1 text-xs font-medium ${s.trend === 'up' ? 'text-chart-2' : 'text-destructive'}`}>
                    {s.trend === 'up' ? <TrendingUp className="w-3 h-3" /> : <TrendingDown className="w-3 h-3" />}
                    {s.change}
                  </div>
                </div>
                <p className="text-2xl font-bold">{s.value}</p>
                <p className="text-xs text-muted-foreground mt-1">{s.title}</p>
              </CardContent>
            </Card>
          ))}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Recent Users */}
          <Card className="rounded-2xl border-border/50">
            <CardHeader className="flex flex-row items-center justify-between pb-3">
              <CardTitle className="text-base font-semibold">Recent Users</CardTitle>
              <Button variant="ghost" size="sm" className="gap-1 text-xs text-primary">
                View All <ArrowUpRight className="w-3 h-3" />
              </Button>
            </CardHeader>
            <CardContent className="p-0">
              <div className="divide-y divide-border/50">
                {recentUsers.map((u) => (
                  <div key={u.name} className="flex items-center justify-between px-5 py-3">
                    <div>
                      <p className="text-sm font-medium">{u.name}</p>
                      <p className="text-xs text-muted-foreground">{u.role} · {u.date}</p>
                    </div>
                    <Badge variant={u.status === 'Active' ? 'default' : 'secondary'} className="text-[10px]">
                      {u.status}
                    </Badge>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Top Neighborhoods */}
          <Card className="rounded-2xl border-border/50">
            <CardHeader className="flex flex-row items-center justify-between pb-3">
              <CardTitle className="text-base font-semibold">Top Neighborhoods</CardTitle>
              <Button variant="ghost" size="sm" className="gap-1 text-xs text-primary">
                View All <ArrowUpRight className="w-3 h-3" />
              </Button>
            </CardHeader>
            <CardContent className="space-y-4">
              {topNeighborhoods.map((n) => (
                <div key={n.name} className="space-y-1.5">
                  <div className="flex items-center justify-between text-sm">
                    <span className="font-medium">{n.name}</span>
                    <span className="text-muted-foreground">{n.listings} listings</span>
                  </div>
                  <Progress value={n.percent} className="h-2" />
                </div>
              ))}
            </CardContent>
          </Card>
        </div>

        {/* Quick Actions */}
        <Card className="rounded-2xl border-border/50">
          <CardHeader>
            <CardTitle className="text-base font-semibold">Quick Actions</CardTitle>
          </CardHeader>
          <CardContent className="flex flex-wrap gap-3">
            <Button variant="outline" className="rounded-xl gap-2"><Users className="w-4 h-4" /> Manage Users</Button>
            <Button variant="outline" className="rounded-xl gap-2"><Building2 className="w-4 h-4" /> Review Listings</Button>
            <Button variant="outline" className="rounded-xl gap-2"><UserCheck className="w-4 h-4" /> Approve Agents</Button>
            <Button variant="outline" className="rounded-xl gap-2"><Eye className="w-4 h-4" /> View Reports</Button>
          </CardContent>
        </Card>
      </div>
    </DashboardLayout>
  );
}
