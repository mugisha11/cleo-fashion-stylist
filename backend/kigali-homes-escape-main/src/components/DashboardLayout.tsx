import { ReactNode } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard, Home, Users, Building2, Heart, Settings, LogOut,
  BarChart3, MessageSquare, Bell, PlusCircle, FileText, Star, Search, Menu,
  UserCheck, Shield, Briefcase,
} from 'lucide-react';
import { useAuth, UserRole } from '@/contexts/AuthContext';
import { Button } from '@/components/ui/button';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import {
  Sidebar, SidebarContent, SidebarFooter, SidebarGroup, SidebarGroupContent,
  SidebarGroupLabel, SidebarHeader, SidebarMenu, SidebarMenuButton,
  SidebarMenuItem, SidebarProvider, SidebarTrigger, useSidebar,
} from '@/components/ui/sidebar';
import { NavLink } from '@/components/NavLink';
import { Separator } from '@/components/ui/separator';
import {
  DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuSeparator, DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';

interface NavItem {
  title: string;
  url: string;
  icon: React.ElementType;
  badge?: string;
}

const roleNavItems: Record<UserRole, { main: NavItem[]; secondary: NavItem[] }> = {
  admin: {
    main: [
      { title: 'Overview', url: '/dashboard/admin', icon: LayoutDashboard },
      { title: 'All Properties', url: '/dashboard/admin/properties', icon: Building2 },
      { title: 'Users', url: '/dashboard/admin/users', icon: Users },
      { title: 'Agents', url: '/dashboard/admin/agents', icon: UserCheck },
      { title: 'Analytics', url: '/dashboard/admin/analytics', icon: BarChart3 },
      { title: 'Reports', url: '/dashboard/admin/reports', icon: FileText },
    ],
    secondary: [
      { title: 'Messages', url: '/dashboard/admin/messages', icon: MessageSquare, badge: '5' },
      { title: 'Settings', url: '/dashboard/admin/settings', icon: Settings },
    ],
  },
  agent: {
    main: [
      { title: 'Overview', url: '/dashboard/agent', icon: LayoutDashboard },
      { title: 'My Listings', url: '/dashboard/agent/listings', icon: Building2 },
      { title: 'Add Property', url: '/dashboard/agent/add', icon: PlusCircle },
      { title: 'Inquiries', url: '/dashboard/agent/inquiries', icon: MessageSquare, badge: '3' },
      { title: 'Performance', url: '/dashboard/agent/performance', icon: BarChart3 },
    ],
    secondary: [
      { title: 'Reviews', url: '/dashboard/agent/reviews', icon: Star },
      { title: 'Settings', url: '/dashboard/agent/settings', icon: Settings },
    ],
  },
  host: {
    main: [
      { title: 'Overview', url: '/dashboard/host', icon: LayoutDashboard },
      { title: 'My Properties', url: '/dashboard/host/properties', icon: Building2 },
      { title: 'List Property', url: '/dashboard/host/add', icon: PlusCircle },
      { title: 'Bookings', url: '/dashboard/host/bookings', icon: FileText },
      { title: 'Earnings', url: '/dashboard/host/earnings', icon: BarChart3 },
    ],
    secondary: [
      { title: 'Messages', url: '/dashboard/host/messages', icon: MessageSquare, badge: '2' },
      { title: 'Settings', url: '/dashboard/host/settings', icon: Settings },
    ],
  },
  client: {
    main: [
      { title: 'Overview', url: '/dashboard/client', icon: LayoutDashboard },
      { title: 'Browse Properties', url: '/listings', icon: Search },
      { title: 'Saved Properties', url: '/dashboard/client/saved', icon: Heart },
      { title: 'My Inquiries', url: '/dashboard/client/inquiries', icon: MessageSquare },
      { title: 'Appointments', url: '/dashboard/client/appointments', icon: FileText },
    ],
    secondary: [
      { title: 'Notifications', url: '/dashboard/client/notifications', icon: Bell, badge: '4' },
      { title: 'Settings', url: '/dashboard/client/settings', icon: Settings },
    ],
  },
};

const roleLabels: Record<UserRole, { label: string; icon: React.ElementType; color: string }> = {
  admin: { label: 'Administrator', icon: Shield, color: 'bg-destructive/10 text-destructive' },
  agent: { label: 'Agent', icon: Briefcase, color: 'bg-primary/10 text-primary' },
  host: { label: 'Property Host', icon: Home, color: 'bg-chart-4/20 text-chart-4' },
  client: { label: 'Client', icon: Users, color: 'bg-chart-2/20 text-chart-2' },
};

function AppSidebar() {
  const { user, logout } = useAuth();
  const { state } = useSidebar();
  const navigate = useNavigate();
  const collapsed = state === 'collapsed';
  const role = user?.role ?? 'client';
  const items = roleNavItems[role];
  const roleInfo = roleLabels[role];

  return (
    <Sidebar collapsible="icon" className="border-r border-border">
      <SidebarHeader className="p-4">
        <Link to="/" className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-lg bg-primary flex items-center justify-center shrink-0">
            <Home className="w-4.5 h-4.5 text-primary-foreground" />
          </div>
          {!collapsed && <span className="text-lg font-bold tracking-tight">Kigali Homes</span>}
        </Link>
        {!collapsed && (
          <div className={`mt-3 flex items-center gap-2 rounded-lg px-2.5 py-1.5 text-xs font-medium ${roleInfo.color}`}>
            <roleInfo.icon className="w-3.5 h-3.5" />
            {roleInfo.label}
          </div>
        )}
      </SidebarHeader>

      <Separator className="mx-3 w-auto" />

      <SidebarContent className="pt-2">
        <SidebarGroup>
          <SidebarGroupLabel>Main Menu</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              {items.main.map((item) => (
                <SidebarMenuItem key={item.title}>
                  <SidebarMenuButton asChild tooltip={item.title}>
                    <NavLink to={item.url} end className="hover:bg-accent" activeClassName="bg-accent text-primary font-medium">
                      <item.icon className="w-4 h-4" />
                      {!collapsed && <span>{item.title}</span>}
                      {!collapsed && item.badge && (
                        <Badge variant="secondary" className="ml-auto text-[10px] h-5 min-w-5 flex items-center justify-center bg-primary/10 text-primary">
                          {item.badge}
                        </Badge>
                      )}
                    </NavLink>
                  </SidebarMenuButton>
                </SidebarMenuItem>
              ))}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>

        <SidebarGroup>
          <SidebarGroupLabel>Support</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              {items.secondary.map((item) => (
                <SidebarMenuItem key={item.title}>
                  <SidebarMenuButton asChild tooltip={item.title}>
                    <NavLink to={item.url} end className="hover:bg-accent" activeClassName="bg-accent text-primary font-medium">
                      <item.icon className="w-4 h-4" />
                      {!collapsed && <span>{item.title}</span>}
                      {!collapsed && item.badge && (
                        <Badge variant="secondary" className="ml-auto text-[10px] h-5 min-w-5 flex items-center justify-center bg-primary/10 text-primary">
                          {item.badge}
                        </Badge>
                      )}
                    </NavLink>
                  </SidebarMenuButton>
                </SidebarMenuItem>
              ))}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>

      <SidebarFooter className="p-3">
        <Separator className="mb-3" />
        {!collapsed ? (
          <div className="flex items-center gap-3">
            <Avatar className="h-9 w-9">
              <AvatarImage src={user?.avatar} />
              <AvatarFallback>{user?.name?.charAt(0)}</AvatarFallback>
            </Avatar>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium truncate">{user?.name}</p>
              <p className="text-xs text-muted-foreground truncate">{user?.email}</p>
            </div>
            <Button variant="ghost" size="icon" className="shrink-0 h-8 w-8" onClick={() => { logout(); navigate('/login'); }}>
              <LogOut className="w-4 h-4" />
            </Button>
          </div>
        ) : (
          <Button variant="ghost" size="icon" className="w-full" onClick={() => { logout(); navigate('/login'); }}>
            <LogOut className="w-4 h-4" />
          </Button>
        )}
      </SidebarFooter>
    </Sidebar>
  );
}

function DashboardHeader() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  return (
    <header className="h-14 border-b border-border flex items-center justify-between px-4 bg-card/80 backdrop-blur-sm sticky top-0 z-20">
      <div className="flex items-center gap-3">
        <SidebarTrigger />
        <Separator orientation="vertical" className="h-5" />
        <h2 className="text-sm font-medium text-muted-foreground hidden sm:block">Dashboard</h2>
      </div>
      <div className="flex items-center gap-2">
        <Button variant="ghost" size="icon" className="relative h-9 w-9">
          <Bell className="w-4 h-4" />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-primary rounded-full" />
        </Button>
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" className="gap-2 px-2">
              <Avatar className="h-7 w-7">
                <AvatarImage src={user?.avatar} />
                <AvatarFallback>{user?.name?.charAt(0)}</AvatarFallback>
              </Avatar>
              <span className="text-sm hidden sm:inline">{user?.name}</span>
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-48">
            <DropdownMenuItem asChild><Link to="/">Back to Site</Link></DropdownMenuItem>
            <DropdownMenuItem asChild><Link to={`/dashboard/${user?.role}/settings`}>Settings</Link></DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem onClick={() => { logout(); navigate('/login'); }} className="text-destructive">
              <LogOut className="w-4 h-4 mr-2" /> Logout
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </header>
  );
}

function DashboardFooter() {
  return (
    <footer className="border-t border-border px-6 py-3 flex items-center justify-between text-xs text-muted-foreground bg-card/50">
      <span>© 2026 Kigali Homes. All rights reserved.</span>
      <div className="flex items-center gap-4">
        <Link to="/" className="hover:text-foreground transition-colors">Home</Link>
        <Link to="/listings" className="hover:text-foreground transition-colors">Listings</Link>
        <span>v1.0</span>
      </div>
    </footer>
  );
}

export default function DashboardLayout({ children }: { children: ReactNode }) {
  return (
    <SidebarProvider>
      <div className="min-h-screen flex w-full bg-muted/30">
        <AppSidebar />
        <div className="flex-1 flex flex-col min-w-0">
          <DashboardHeader />
          <main className="flex-1 p-4 md:p-6 overflow-auto">{children}</main>
          <DashboardFooter />
        </div>
      </div>
    </SidebarProvider>
  );
}
