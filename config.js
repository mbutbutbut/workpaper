// Supabase connection for Workpaper (see SETUP.md).
// Both values are safe to publish: access is controlled by the row rules in supabase/schema.sql.
// Leave them empty to run the local prototype with sample data.
window.WORKPAPER_CONFIG = {
  supabaseUrl: 'https://ysfieamdzqefgkqgjwjh.supabase.co',
  supabaseAnonKey: 'sb_publishable_i2o7dsEg-vrlcY7QIvz2sg_myr-OtII',
  // First month of your fiscal year (1 to 12). September = 9. Used by the date range filter.
  fiscalYearStartMonth: 9
};
