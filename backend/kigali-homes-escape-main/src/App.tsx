import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { FavoritesProvider } from "@/contexts/FavoritesContext";
import { AuthProvider } from "@/contexts/AuthContext";
import Index from "./pages/Index";
import Listings from "./pages/Listings";
import PropertyDetails from "./pages/PropertyDetails";
import Favorites from "./pages/Favorites";
import BecomeAgent from "./pages/BecomeAgent";
import AgentDashboard from "./pages/AgentDashboard";
import LoginPage from "./pages/LoginPage";
import AdminDashboard from "./pages/dashboards/AdminDashboard";
import AgentDashboardNew from "./pages/dashboards/AgentDashboardNew";
import HostDashboard from "./pages/dashboards/HostDashboard";
import ClientDashboard from "./pages/dashboards/ClientDashboard";
import MessagesPage from "./pages/dashboards/MessagesPage";
import NotFound from "./pages/NotFound";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <AuthProvider>
        <FavoritesProvider>
          <Toaster />
          <Sonner />
          <BrowserRouter>
            <Routes>
              <Route path="/" element={<Index />} />
              <Route path="/listings" element={<Listings />} />
              <Route path="/property/:id" element={<PropertyDetails />} />
              <Route path="/favorites" element={<Favorites />} />
              <Route path="/become-agent" element={<BecomeAgent />} />
              <Route path="/agent-dashboard" element={<AgentDashboard />} />
              <Route path="/login" element={<LoginPage />} />
              <Route path="/dashboard/admin/*" element={<AdminDashboard />} />
              <Route path="/dashboard/admin/messages" element={<MessagesPage />} />
              <Route path="/dashboard/agent/*" element={<AgentDashboardNew />} />
              <Route path="/dashboard/agent/inquiries" element={<MessagesPage />} />
              <Route path="/dashboard/host/*" element={<HostDashboard />} />
              <Route path="/dashboard/host/messages" element={<MessagesPage />} />
              <Route path="/dashboard/client/*" element={<ClientDashboard />} />
              <Route path="/dashboard/client/inquiries" element={<MessagesPage />} />
              {/* ADD ALL CUSTOM ROUTES ABOVE THE CATCH-ALL "*" ROUTE */}
              <Route path="*" element={<NotFound />} />
            </Routes>
          </BrowserRouter>
        </FavoritesProvider>
      </AuthProvider>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
