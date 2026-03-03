using Mapster;
using Microsoft.EntityFrameworkCore;
using Pharmion.Services.Database;
using Pharmion.Services.Database.Seed;
using Pharmion.Services.Interfaces;
using Pharmion.Services.Services;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.OpenApi.Models;
using Pharmion.WebAPI.Filters;
using Pharmion.Services.Services.StateMachines.ReservationStateMachine;
using Pharmion.Services.StateMachines.ReservationStateMachine;

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

    options.Events = new JwtBearerEvents
    {
        OnAuthenticationFailed = context =>
        {
            Console.WriteLine($"Auth failed: {context.Exception.Message}");
            return Task.CompletedTask;
        },
        OnTokenValidated = context =>
        {
            Console.WriteLine("Token validated successfully!");
            return Task.CompletedTask;
        }
    };
});

builder.Services.AddAuthorization();

builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<ICityService, CityService>();
builder.Services.AddScoped<IPharmacyService, PharmacyService>();
builder.Services.AddScoped<IChronicDiseaseService, ChronicDiseaseService>();
builder.Services.AddScoped<IMedicationCategoryService, MedicationCategoryService>();
builder.Services.AddScoped<IPharmacologicalCategoryService, PharmacologicalCategoryService>();
builder.Services.AddScoped<IImageUploadService, ImageUploadService>();
builder.Services.AddScoped<IProductService, ProductService>();
builder.Services.AddScoped<IReservationService, ReservationService>();

builder.Services.AddScoped<InitialReservationState>();
builder.Services.AddScoped<DraftReservationState>();
builder.Services.AddScoped<SubmittedReservationState>();
builder.Services.AddScoped<ApprovedReservationState>();
builder.Services.AddScoped<ReadyForPickupReservationState>();
builder.Services.AddScoped<PickedUpReservationState>();
builder.Services.AddScoped<CancelledReservationState>();
builder.Services.AddScoped<RejectedReservationState>();

builder.Services.AddSingleton<IRabbitMQPublisher, RabbitMQPublisher>();

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? "Server=localhost;Database=220207;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True";
builder.Services.AddDatabaseServices(connectionString);


builder.Services.AddControllers(x=>
{
    x.Filters.Add<ExceptionFilter>();
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Pharmion API",
        Version = "v1",
        Description = "Pharmion - Pharmacy Management System API"
    });

    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "JWT Authorization header using the Bearer scheme. Enter your token in the text input below."
    });

    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            new string[] {}
        }
    });
});

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