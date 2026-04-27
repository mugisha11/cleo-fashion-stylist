import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Search, Heart, User, Menu, X, Home, LayoutDashboard, LogOut } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useFavorites } from '@/contexts/FavoritesContext';
import { useAuth } from '@/contexts/AuthContext';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuSeparator, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';

export function Navbar() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const { favorites } = useFavorites();
  const { user, isAuthenticated, logout } = useAuth();
  const navigate = useNavigate();

  return (
    <header className="sticky top-0 z-50 bg-background navbar-shadow">
      <nav className="container mx-auto px-4 lg:px-6">
        <div className="flex items-center justify-between h-20">
          {/* Logo */}
          <Link to="/" className="flex items-center gap-2">
            <div className="w-10 h-10 rounded-full bg-primary flex items-center justify-center">
              <Home className="w-5 h-5 text-primary-foreground" />
            </div>
            <span className="text-xl font-bold hidden sm:block">Kigali Homes</span>
          </Link>

          {/* Center Search - Desktop */}
          <div className="hidden lg:flex">
            <button 
              onClick={() => navigate('/listings')}
              className="search-bar px-2 py-2"
            >
              <div className="flex items-center divide-x divide-border">
                <div className="px-4 py-1 text-sm font-medium hover:bg-secondary rounded-full transition-colors">
                  Anywhere in Kigali
                </div>
                <div className="px-4 py-1 text-sm font-medium hover:bg-secondary rounded-full transition-colors">
                  Any price
                </div>
                <div className="px-4 py-1 text-sm text-muted-foreground hover:bg-secondary rounded-full transition-colors">
                  Add bedrooms
                </div>
              </div>
              <div className="ml-2 w-8 h-8 rounded-full bg-primary flex items-center justify-center">
                <Search className="w-4 h-4 text-primary-foreground" />
              </div>
            </button>
          </div>

          {/* Mobile Search */}
          <button 
            onClick={() => navigate('/listings')}
            className="lg:hidden search-bar px-4 py-3 flex-1 mx-4"
          >
            <Search className="w-4 h-4 text-muted-foreground" />
            <div className="ml-3 text-left">
              <div className="text-sm font-medium">Where to?</div>
              <div className="text-xs text-muted-foreground">Anywhere • Any price • Any beds</div>
            </div>
          </button>

          {/* Right Side Actions */}
          <div className="hidden md:flex items-center gap-2">
            <Button variant="ghost" className="rounded-full font-medium" asChild>
              <Link to="/become-agent">Become an Agent</Link>
            </Button>
            <Link 
              to="/favorites" 
              className="relative p-3 hover:bg-secondary rounded-full transition-colors"
            >
              <Heart className="w-5 h-5" />
              {favorites.length > 0 && (
                <span className="absolute top-1 right-1 w-4 h-4 bg-primary text-primary-foreground text-xs rounded-full flex items-center justify-center">
                  {favorites.length}
                </span>
              )}
            </Link>
            {isAuthenticated ? (
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <button className="flex items-center gap-2 border border-border rounded-full p-1 pl-3 hover:shadow-md transition-shadow">
                    <Menu className="w-4 h-4" />
                    <Avatar className="h-8 w-8">
                      <AvatarImage src={user?.avatar} />
                      <AvatarFallback>{user?.name?.charAt(0)}</AvatarFallback>
                    </Avatar>
                  </button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end" className="w-52">
                  <DropdownMenuItem asChild>
                    <Link to={`/dashboard/${user?.role}`} className="gap-2"><LayoutDashboard className="w-4 h-4" /> Dashboard</Link>
                  </DropdownMenuItem>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem onClick={() => { logout(); navigate('/'); }} className="text-destructive gap-2">
                    <LogOut className="w-4 h-4" /> Logout
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            ) : (
              <Button variant="outline" className="rounded-full" asChild>
                <Link to="/login">Log in</Link>
              </Button>
            )}
          </div>

          {/* Mobile Menu Button */}
          <button 
            className="md:hidden p-2"
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          >
            {mobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>

        {/* Mobile Menu */}
        {mobileMenuOpen && (
          <div className="md:hidden py-4 border-t border-border animate-fade-in">
            <div className="flex flex-col gap-2">
              <Link 
                to="/listings" 
                className="px-4 py-3 hover:bg-secondary rounded-lg transition-colors"
                onClick={() => setMobileMenuOpen(false)}
              >
                Browse Properties
              </Link>
              <Link 
                to="/favorites" 
                className="px-4 py-3 hover:bg-secondary rounded-lg transition-colors flex items-center justify-between"
                onClick={() => setMobileMenuOpen(false)}
              >
                <span>Favorites</span>
                {favorites.length > 0 && (
                  <span className="bg-primary text-primary-foreground text-xs px-2 py-1 rounded-full">
                    {favorites.length}
                  </span>
                )}
              </Link>
              <Link 
                to="/become-agent" 
                className="px-4 py-3 hover:bg-secondary rounded-lg transition-colors"
                onClick={() => setMobileMenuOpen(false)}
              >
                Become an Agent
              </Link>
              <Link 
                to="/agent-dashboard" 
                className="px-4 py-3 hover:bg-secondary rounded-lg transition-colors"
                onClick={() => setMobileMenuOpen(false)}
              >
                Agent Dashboard
              </Link>
              <div className="border-t border-border my-2" />
              <Link 
                to="/login" 
                className="px-4 py-3 hover:bg-secondary rounded-lg transition-colors"
                onClick={() => setMobileMenuOpen(false)}
              >
                Log in
              </Link>
              <Link 
                to="/signup" 
                className="px-4 py-3 hover:bg-secondary rounded-lg transition-colors"
                onClick={() => setMobileMenuOpen(false)}
              >
                Sign up
              </Link>
            </div>
          </div>
        )}
      </nav>
    </header>
  );
}
