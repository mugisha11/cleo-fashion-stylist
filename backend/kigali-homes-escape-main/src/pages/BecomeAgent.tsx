import { useState } from 'react';
import { Link } from 'react-router-dom';
import { ArrowLeft, Home, DollarSign, Users, CheckCircle, ArrowRight } from 'lucide-react';
import { Navbar } from '@/components/Navbar';
import { Footer } from '@/components/Footer';
import { Button } from '@/components/ui/button';

const steps = [
  {
    icon: Home,
    title: 'List Your Properties',
    description: 'Add your properties with photos, descriptions, amenities, and pricing. Make them stand out to potential buyers and renters.',
  },
  {
    icon: Users,
    title: 'Connect with Clients',
    description: 'Receive inquiries directly via WhatsApp and phone. Respond quickly to interested buyers and schedule viewings.',
  },
  {
    icon: DollarSign,
    title: 'Close Deals',
    description: 'Manage your listings, track interest, and close deals. Build your reputation with reviews from satisfied clients.',
  },
];

const benefits = [
  'Free to join and list properties',
  'Direct contact with buyers and renters',
  'Featured listings for premium visibility',
  'Professional property analytics',
  'Mobile-friendly dashboard',
  'Verified agent badge',
];

export default function BecomeAgent() {
  const [email, setEmail] = useState('');

  return (
    <div className="min-h-screen bg-background">
      <Navbar />

      <main>
        {/* Hero Section */}
        <section className="relative py-20 md:py-32 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-primary/10 via-transparent to-primary/5" />
          
          <div className="container mx-auto px-4 relative">
            <Link 
              to="/" 
              className="inline-flex items-center gap-2 text-muted-foreground hover:text-foreground mb-8 transition-colors"
            >
              <ArrowLeft className="w-4 h-4" />
              Back to home
            </Link>

            <div className="max-w-3xl">
              <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold mb-6 animate-fade-up">
                Become an Agent on Kigali Homes
              </h1>
              <p className="text-xl text-muted-foreground mb-8 animate-fade-up" style={{ animationDelay: '0.1s' }}>
                Join Rwanda's leading real estate platform and connect with thousands of home seekers. 
                List properties, grow your network, and build your business.
              </p>

              {/* Email Signup */}
              <div 
                className="flex flex-col sm:flex-row gap-4 max-w-xl animate-fade-up"
                style={{ animationDelay: '0.2s' }}
              >
                <input
                  type="email"
                  placeholder="Enter your email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="flex-1 px-5 py-4 rounded-xl border border-border bg-card focus:outline-none focus:ring-2 focus:ring-primary"
                />
                <Button size="lg" className="px-8 rounded-xl">
                  Get Started
                  <ArrowRight className="w-4 h-4 ml-2" />
                </Button>
              </div>

              <p className="text-sm text-muted-foreground mt-4 animate-fade-up" style={{ animationDelay: '0.3s' }}>
                Already an agent? <Link to="/login" className="text-primary hover:underline">Sign in here</Link>
              </p>
            </div>
          </div>
        </section>

        {/* How It Works */}
        <section className="py-16 md:py-24 bg-secondary/30">
          <div className="container mx-auto px-4">
            <h2 className="text-2xl md:text-3xl font-bold text-center mb-4">
              How it works
            </h2>
            <p className="text-muted-foreground text-center mb-12 max-w-2xl mx-auto">
              Getting started as an agent is simple. Follow these steps to begin listing properties and connecting with clients.
            </p>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
              {steps.map((step, idx) => (
                <div 
                  key={step.title}
                  className="bg-card rounded-2xl p-8 text-center animate-fade-in"
                  style={{ animationDelay: `${idx * 0.1}s` }}
                >
                  <div className="w-16 h-16 rounded-full bg-primary/10 flex items-center justify-center mx-auto mb-6">
                    <step.icon className="w-8 h-8 text-primary" />
                  </div>
                  <div className="text-sm font-medium text-primary mb-2">Step {idx + 1}</div>
                  <h3 className="text-xl font-semibold mb-3">{step.title}</h3>
                  <p className="text-muted-foreground">{step.description}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Benefits */}
        <section className="py-16 md:py-24">
          <div className="container mx-auto px-4">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
              <div>
                <h2 className="text-2xl md:text-3xl font-bold mb-6">
                  Why agents love Kigali Homes
                </h2>
                <p className="text-muted-foreground mb-8">
                  We provide everything you need to succeed in Rwanda's growing real estate market. 
                  Focus on what you do best - we'll handle the rest.
                </p>

                <ul className="space-y-4">
                  {benefits.map((benefit, idx) => (
                    <li 
                      key={benefit}
                      className="flex items-center gap-3 animate-fade-in"
                      style={{ animationDelay: `${idx * 0.05}s` }}
                    >
                      <CheckCircle className="w-5 h-5 text-primary shrink-0" />
                      <span>{benefit}</span>
                    </li>
                  ))}
                </ul>

                <Button size="lg" className="mt-8">
                  Start Listing Today
                </Button>
              </div>

              <div className="relative">
                <img 
                  src="https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=800"
                  alt="Real estate agent"
                  className="rounded-2xl shadow-2xl"
                />
                <div className="absolute -bottom-6 -left-6 bg-card rounded-xl p-4 shadow-lg">
                  <div className="flex items-center gap-3">
                    <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center">
                      <Users className="w-6 h-6 text-primary" />
                    </div>
                    <div>
                      <p className="font-bold">50+ Agents</p>
                      <p className="text-sm text-muted-foreground">Already listing</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* CTA */}
        <section className="py-16 md:py-24 bg-foreground text-background">
          <div className="container mx-auto px-4 text-center">
            <h2 className="text-2xl md:text-3xl font-bold mb-4">
              Ready to grow your real estate business?
            </h2>
            <p className="text-background/70 mb-8 max-w-xl mx-auto">
              Join Kigali Homes today and start connecting with buyers and renters across Rwanda.
            </p>
            <Button size="lg" variant="secondary" className="text-foreground">
              Become an Agent
            </Button>
          </div>
        </section>
      </main>

      <Footer />
    </div>
  );
}
