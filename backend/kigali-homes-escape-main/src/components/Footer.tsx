import { Link } from 'react-router-dom';
import { Home, Facebook, Instagram, Twitter, Mail, Phone, MapPin } from 'lucide-react';

export function Footer() {
  return (
    <footer className="bg-foreground text-background">
      <div className="container mx-auto px-4 py-12 md:py-16">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-10">
          {/* Brand */}
          <div>
            <Link to="/" className="flex items-center gap-2 mb-4">
              <div className="w-10 h-10 rounded-full bg-primary flex items-center justify-center">
                <Home className="w-5 h-5 text-primary-foreground" />
              </div>
              <span className="text-xl font-bold">Kigali Homes</span>
            </Link>
            <p className="text-background/70 mb-6">
              Your trusted partner for finding the perfect home in Kigali. We connect buyers, renters, and agents.
            </p>
            <div className="flex gap-4">
              <a href="#" className="p-2 rounded-full bg-background/10 hover:bg-background/20 transition-colors">
                <Facebook className="w-5 h-5" />
              </a>
              <a href="#" className="p-2 rounded-full bg-background/10 hover:bg-background/20 transition-colors">
                <Instagram className="w-5 h-5" />
              </a>
              <a href="#" className="p-2 rounded-full bg-background/10 hover:bg-background/20 transition-colors">
                <Twitter className="w-5 h-5" />
              </a>
            </div>
          </div>

          {/* Quick Links */}
          <div>
            <h3 className="font-semibold text-lg mb-4">Quick Links</h3>
            <ul className="space-y-3">
              <li>
                <Link to="/listings" className="text-background/70 hover:text-background transition-colors">
                  Browse Properties
                </Link>
              </li>
              <li>
                <Link to="/listings?type=rent" className="text-background/70 hover:text-background transition-colors">
                  Rent a Home
                </Link>
              </li>
              <li>
                <Link to="/listings?type=sale" className="text-background/70 hover:text-background transition-colors">
                  Buy a Property
                </Link>
              </li>
              <li>
                <Link to="/become-agent" className="text-background/70 hover:text-background transition-colors">
                  Become an Agent
                </Link>
              </li>
            </ul>
          </div>

          {/* Support */}
          <div>
            <h3 className="font-semibold text-lg mb-4">Support</h3>
            <ul className="space-y-3">
              <li>
                <Link to="/help" className="text-background/70 hover:text-background transition-colors">
                  Help Center
                </Link>
              </li>
              <li>
                <Link to="/safety" className="text-background/70 hover:text-background transition-colors">
                  Safety Tips
                </Link>
              </li>
              <li>
                <Link to="/terms" className="text-background/70 hover:text-background transition-colors">
                  Terms of Service
                </Link>
              </li>
              <li>
                <Link to="/privacy" className="text-background/70 hover:text-background transition-colors">
                  Privacy Policy
                </Link>
              </li>
            </ul>
          </div>

          {/* Contact */}
          <div>
            <h3 className="font-semibold text-lg mb-4">Contact Us</h3>
            <ul className="space-y-4">
              <li className="flex items-start gap-3">
                <MapPin className="w-5 h-5 text-primary shrink-0 mt-0.5" />
                <span className="text-background/70">KG 123 St, Kigali, Rwanda</span>
              </li>
              <li className="flex items-center gap-3">
                <Phone className="w-5 h-5 text-primary shrink-0" />
                <a href="tel:+250788000000" className="text-background/70 hover:text-background transition-colors">
                  +250 788 000 000
                </a>
              </li>
              <li className="flex items-center gap-3">
                <Mail className="w-5 h-5 text-primary shrink-0" />
                <a href="mailto:info@kigalihomes.rw" className="text-background/70 hover:text-background transition-colors">
                  info@kigalihomes.rw
                </a>
              </li>
            </ul>
          </div>
        </div>

        <div className="border-t border-background/10 mt-12 pt-8 flex flex-col md:flex-row items-center justify-between gap-4">
          <p className="text-background/50 text-sm">
            © {new Date().getFullYear()} Kigali Homes. All rights reserved.
          </p>
          <p className="text-background/50 text-sm">
            Made with ❤️ in Rwanda
          </p>
        </div>
      </div>
    </footer>
  );
}
