using FamilyRecipeBook.Web.Data;
using Microsoft.AspNetCore.HttpOverrides;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllersWithViews();
builder.Services.AddSingleton<IRecipeRepository, FileRecipeRepository>();
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto | ForwardedHeaders.XForwardedHost;
    options.KnownIPNetworks.Clear();
    options.KnownProxies.Clear();
});

var app = builder.Build();

var pathBase = builder.Configuration["App:PathBase"];

if (!string.IsNullOrWhiteSpace(pathBase))
{
    if (!pathBase.StartsWith('/'))
    {
        pathBase = "/" + pathBase;
    }

    app.Use((context, next) =>
    {
        if (context.Request.Path.StartsWithSegments(pathBase, out var remainingPath))
        {
            context.Request.PathBase = pathBase;
            context.Request.Path = remainingPath;
        }

        return next();
    });
}

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseForwardedHeaders();

// Cloudflare terminates TLS — only redirect to HTTPS when running outside the tunnel
if (!app.Environment.IsProduction())
{
    app.UseHttpsRedirection();
}
app.UseRouting();

app.UseAuthorization();

app.MapStaticAssets();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}")
    .WithStaticAssets();


app.Run();
