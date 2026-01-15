# Technical Framework (Vue + Supabase)

### 1. System Architecture

The target architecture is server-authoritative.

Phase guidance:

* Phase 1 can be client-only for speed (local persistence).
* Phase 3+ must be server-authoritative for RNG and economy integrity.

When server-authoritative is enabled, all RNG and currency writes happen via Supabase Edge Functions or PostgreSQL RPC, not on the client.

* Frontend: Vue 3 (Composition API) + Pinia (State Management).
* Backend: Supabase Auth, PostgreSQL, and Realtime (Broadcast/Presence).
* Styling: Tailwind CSS (for rapid Brutalist UI styling).
