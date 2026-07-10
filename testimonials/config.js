// Reuses the same Supabase project as live-quiz/config.js (one project,
// separate tables) rather than requiring a second project — swap these if
// you'd rather keep testimonials on its own project.
// The anon key is safe to expose client-side — it's restricted by the
// row-level-security policies in schema.sql (insert-only / approved-only read).
export const SUPABASE_URL = 'https://xitzohnweabeizfjajoo.supabase.co';
export const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhpdHpvaG53ZWFiZWl6Zmpham9vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM1OTIwMjYsImV4cCI6MjA5OTE2ODAyNn0.uP_ED2jGgZgBfv0hv9_hR5o9dJaJl9IWWFvs_hiUeKk';
export const PHOTO_BUCKET = 'testimonial-photos';
