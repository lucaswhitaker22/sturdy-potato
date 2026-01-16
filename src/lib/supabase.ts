import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://your-project.supabase.co'
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'your-anon-key'

// Safety wrapper for navigator.locks which often throws SecurityError in Edge/Private modes
if (typeof navigator !== 'undefined' && navigator.locks && navigator.locks.request) {
    const originalRequest = navigator.locks.request.bind(navigator.locks);
    navigator.locks.request = (async (...args: any[]) => {
        try {
            return await (originalRequest as any).apply(navigator.locks, args);
        } catch (err: any) {
            if (err.name === 'SecurityError' || err.message?.includes('SecurityError')) {
                console.warn('[Supabase] navigator.locks.request() blocked by security policy. Bypassing lock.');
                const callback = args[args.length - 1];
                if (typeof callback === 'function') return callback();
                return;
            }
            throw err;
        }
    }) as any;
}

// Truly robust storage with in-memory fallback to prevent SecurityErrors
const createSafeStorage = () => {
    const memoryStore: Record<string, string> = {};
    let storageAvailable = false;

    try {
        if (typeof window !== 'undefined' && window.localStorage) {
            const testKey = '__storage_test__';
            localStorage.setItem(testKey, testKey);
            localStorage.removeItem(testKey);
            storageAvailable = true;
        }
    } catch (e) {
        console.warn('[Supabase] Local storage unavailable, falling back to memory store.');
        storageAvailable = false;
    }

    return {
        getItem: (key: string) => {
            try {
                if (storageAvailable) return localStorage.getItem(key);
            } catch { }
            return memoryStore[key] || null;
        },
        setItem: (key: string, value: string) => {
            try {
                if (storageAvailable) {
                    localStorage.setItem(key, value);
                    return;
                }
            } catch { }
            memoryStore[key] = value;
        },
        removeItem: (key: string) => {
            try {
                if (storageAvailable) {
                    localStorage.removeItem(key);
                    return;
                }
            } catch { }
            delete memoryStore[key];
        }
    };
};

const safeStorage = createSafeStorage();

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    auth: {
        storage: safeStorage,
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true,
        flowType: 'pkce' // Use PKCE as it is more robust
    },
    global: {
        // Add headers to potentially bypass some simple tracker blockers
        headers: { 'x-application-name': 'sturdy-potato' }
    }
})
