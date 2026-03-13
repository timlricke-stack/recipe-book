# Family Recipe Book

Shared family recipe website backed by Microsoft SQL Server 2025.

## What is included

- Database schema and seed data: `family_recipe_book.sql`
- Operations pack (status/search/maintenance procedures): `family_recipe_book_ops.sql`
- ASP.NET Core MVC site: `FamilyRecipeBook.Web`

## 1) Create the database

Run scripts in this order on your SQL Server instance:

1. `family_recipe_book.sql`
2. `family_recipe_book_ops.sql`

## 2) App data storage

The website currently uses a local JSON data file for runtime storage:

- Data file: FamilyRecipeBook.Web/App_Data/recipes.json

The SQL scripts remain included and can be used independently for SQL Server setup:

- family_recipe_book.sql
- family_recipe_book_ops.sql

## 3) Run website locally

```powershell
cd FamilyRecipeBook.Web
dotnet run
```

Open the URL printed in the terminal (usually `https://localhost:xxxx`).

## Deploy behind Cloudflare at /db

Current app config is set for subpath hosting:

- App path base is `/db` in FamilyRecipeBook.Web/appsettings.json

If your reverse proxy forwards traffic from `https://ab0h.com/db` to this app:

1. Keep `App:PathBase` as `/db`
2. Ensure forwarded headers are passed (`X-Forwarded-For`, `X-Forwarded-Proto`, `X-Forwarded-Host`)
3. Keep the app running on an internal port (for example `http://localhost:5055`)

Example reverse-proxy target:

- Public: `https://ab0h.com/db`
- Origin app: `http://localhost:5055`

If you later host at root domain instead of `/db`, set `App:PathBase` to an empty string.

## Website features (starter)

- Browse all recipes
- View recipe details (ingredients and steps)
- Create recipe core details from the web form

## Notes

- NuGet package restore was unavailable in this environment, so the website uses file-backed storage to stay deployable.
- For family sharing on home network, run the app on an always-on machine and publish with IIS or a reverse proxy.
- For SQL-backed production later, add a SQL client package on your deployment machine and switch IRecipeRepository implementation.