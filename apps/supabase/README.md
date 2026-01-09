# Supabase

Database migrations and seeds for Week 5+ production backend.

## Migrations

SQL migration files go in `migrations/` folder.

Run migrations:
```bash
supabase migration up
```

## Schema

See [docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md) for full schema.

Tables:
- traders
- products
- orders
- payments
- daily_log (audit trail)

## Sync with Google Sheets

Use Whalesync to sync existing Sheets data to Supabase during Week 5 migration.

