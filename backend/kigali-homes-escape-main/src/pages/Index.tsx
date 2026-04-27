import { Navbar } from '@/components/Navbar';
import { HeroSection } from '@/components/HeroSection';
import { FeaturedListings } from '@/components/FeaturedListings';
import { NeighborhoodSection } from '@/components/NeighborhoodSection';
import { Footer } from '@/components/Footer';

const Index = () => {
  return (
    <div className="min-h-screen bg-background">
      <Navbar />
      <HeroSection />
      <FeaturedListings />
      <NeighborhoodSection />
      <Footer />
    </div>
  );
};

export default Index;
