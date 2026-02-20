using Mapster;
using Microsoft.EntityFrameworkCore;
using Pharmion.Services.Database;
using Pharmion.Services.Database.Seed;
using Pharmion.Services.Interfaces;
using Pharmion.Services.Services;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;


var builder = WebApplication.CreateBuilder(args);

var jwtSecret = builder.Configuration["JwtSettings:Secret"];
var jwtIssuer = builder.Configuration["JwtSettings:Issuer"];
var jwtAudience = builder.Configuration["JwtSettings:Audience"];

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtIssuer,
        ValidAudience = jwtAudience,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret)),
        ClockSkew = TimeSpan.Zero
    };
});

builder.Services.AddAuthorization();

builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<ICityService, CityService>();
builder.Services.AddScoped<ICityService, CityService>();
builder.Services.AddScoped<IPharmacyService, PharmacyService>();
builder.Services.AddScoped<IChronicDiseaseService, ChronicDiseaseService>();
builder.Services.AddScoped<IMedicationCategoryService, MedicationCategoryService>();
builder.Services.AddScoped<IPharmacologicalCategoryService, PharmacologicalCategoryService>();
builder.Services.AddScoped<IImageUploadService, ImageUploadService>();
builder.Services.AddScoped<IProductService, ProductService>();
// Add services to the container.
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ?? "Server=localhost;Database=220207;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True";
builder.Services.AddDatabaseServices(connectionString);
builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddMapster();


var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<PharmionDbContext>();
        await context.Database.MigrateAsync();
        await DatabaseSeeder.SeedAllAsync(context);
        Console.WriteLine("Database seeded successfully!");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Error seeding database: {ex.Message}");
    }
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
app.UseStaticFiles();
app.UseHttpsRedirection();

app.UseAuthentication();  
app.UseAuthorization();

app.MapControllers();

app.Run();
