# Technical Framework (Vue + Supabase)

### 1. System Architecture

The game follows a Server-Authoritative model. To prevent cheating, all RNG (Sifting results) and currency transactions must happen via Supabase Edge Functions or PostgreSQL Stored Procedures (RPC), not on the client.

* Frontend: Vue 3 (Composition API) + Pinia (State Management).
* Backend: Supabase Auth, PostgreSQL, and Realtime (Broadcast/Presence).
* Styling: Tailwind CSS (for rapid Brutalist UI styling).
