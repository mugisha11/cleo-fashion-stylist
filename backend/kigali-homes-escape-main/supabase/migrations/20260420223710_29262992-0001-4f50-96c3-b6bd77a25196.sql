
-- Create demo agent user
DO $$
DECLARE
  agent_id uuid := '00000000-0000-0000-0000-000000000a01';
BEGIN
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = agent_id) THEN
    INSERT INTO auth.users (
      id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, recovery_token
    ) VALUES (
      agent_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
      'demo.agent@kigalihomes.rw',
      crypt('demo1234', gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{"display_name":"Demo Agent","role":"agent"}'::jsonb,
      now(), now(), '', ''
    );
  END IF;
  -- Ensure profile + role (handle_new_user trigger should have done this, but be safe)
  INSERT INTO public.profiles (user_id, display_name, email, avatar_url, phone)
  VALUES (agent_id, 'Jean Baptiste', 'demo.agent@kigalihomes.rw',
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
          '+250 788 123 456')
  ON CONFLICT (user_id) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    avatar_url = EXCLUDED.avatar_url,
    phone = EXCLUDED.phone;

  INSERT INTO public.user_roles (user_id, role) VALUES (agent_id, 'agent')
  ON CONFLICT (user_id, role) DO NOTHING;
END $$;

-- Seed properties (only if none exist for this owner)
INSERT INTO public.properties (owner_id, title, description, price, price_type, neighborhood, address, bedrooms, bathrooms, area_sqm, images, amenities, is_featured, rating, review_count)
SELECT * FROM (VALUES
  ('00000000-0000-0000-0000-000000000a01'::uuid,
   'Stunning Modern Villa with Pool',
   'Experience luxury living in this stunning modern villa located in the prestigious Nyarutarama neighborhood. Floor-to-ceiling windows, infinity pool, breathtaking views.',
   350000000::numeric, 'sale'::price_type, 'Nyarutarama', 'Nyarutarama, Kigali', 5, 4::numeric, 450::numeric,
   ARRAY['https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800','https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800','https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800','https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800'],
   ARRAY['Swimming Pool','Garden','Garage','Security','Generator','Solar Panels','Smart Home','Gym'],
   true, 4.9::numeric, 28),
  ('00000000-0000-0000-0000-000000000a01'::uuid,
   'Contemporary Apartment in Kiyovu',
   'Modern 3-bedroom apartment in the heart of Kiyovu with open-plan living and stunning city views. Walking distance to embassies.',
   1500000::numeric, 'rent', 'Kiyovu', 'Kiyovu, Kigali', 3, 2::numeric, 180::numeric,
   ARRAY['https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800','https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800','https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=800'],
   ARRAY['Balcony','Parking','Security','24/7 Water','Internet','Air Conditioning'],
   true, 4.7::numeric, 15),
  ('00000000-0000-0000-0000-000000000a01'::uuid,
   'Family Home with Garden',
   'Beautiful family home in quiet Kimihurura. Large garden, modern kitchen, spacious bedrooms. Close to international schools.',
   180000000::numeric, 'sale', 'Kimihurura', 'Kimihurura, Kigali', 4, 3::numeric, 320::numeric,
   ARRAY['https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?w=800','https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=800','https://images.unsplash.com/photo-1600573472591-ee6b68d14c68?w=800'],
   ARRAY['Garden','Garage','Security','Generator','Staff Quarters','Storage'],
   false, 4.8::numeric, 22),
  ('00000000-0000-0000-0000-000000000a01'::uuid,
   'Luxury Penthouse Suite',
   'Exclusive penthouse with panoramic views of Kigali. Private terrace, designer interiors, premium appliances.',
   2500000::numeric, 'rent', 'Nyarutarama', 'Nyarutarama, Kigali', 4, 3::numeric, 280::numeric,
   ARRAY['https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?w=800','https://images.unsplash.com/photo-1600566752355-35792bedcfea?w=800','https://images.unsplash.com/photo-1600210492493-0946911123ea?w=800'],
   ARRAY['Terrace','Concierge','Gym','Pool','Parking','Security','Elevator'],
   true, 4.95::numeric, 12),
  ('00000000-0000-0000-0000-000000000a01'::uuid,
   'Cozy Studio in Remera',
   'Perfect starter apartment for young professionals. Modern finishes, fully furnished, near public transport.',
   400000::numeric, 'rent', 'Remera', 'Remera, Kigali', 1, 1::numeric, 45::numeric,
   ARRAY['https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800','https://images.unsplash.com/photo-1560185893-a55cbc8c57e8?w=800'],
   ARRAY['Furnished','Internet','Security','Parking'],
   false, 4.5::numeric, 34),
  ('00000000-0000-0000-0000-000000000a01'::uuid,
   'Executive Villa in Gacuriro',
   'Magnificent executive villa with stunning architecture, home cinema, wine cellar, and landscaped gardens.',
   280000000::numeric, 'sale', 'Gacuriro', 'Gacuriro, Kigali', 6, 5::numeric, 520::numeric,
   ARRAY['https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800','https://images.unsplash.com/photo-1600607687644-c7171b42498f?w=800','https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?w=800'],
   ARRAY['Pool','Cinema','Wine Cellar','Garden','Garage','Security','Generator','Solar'],
   true, 4.85::numeric, 8)
) AS v(owner_id, title, description, price, price_type, neighborhood, address, bedrooms, bathrooms, area_sqm, images, amenities, is_featured, rating, review_count)
WHERE NOT EXISTS (SELECT 1 FROM public.properties WHERE owner_id = '00000000-0000-0000-0000-000000000a01');
