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
using Microsoft.AspNetCore.Mvc;

DotNetEnv.Env.Load(Path.Combine(Directory.GetCurrentDirectory(), "..", ".env"));
var builder = WebApplication.CreateBuilder(args);
var jwtSecret = builder.Configuration["JwtSettings:Secret"]
    ?? throw new InvalidOperationException("JwtSettings:Secret is not configured.");
if (jwtSecret.Length < 32)
    throw new InvalidOperationException("JwtSettings:Secret must be at least 32 characters.");

var jwtIssuer = builder.Configuration["JwtSettings:Issuer"]
    ?? throw new InvalidOperationException("JwtSettings:Issuer is not configured.");

var jwtAudience = builder.Configuration["JwtSettings:Audience"]
    ?? throw new InvalidOperationException("JwtSettings:Audience is not configured.");

var stripeKey = builder.Configuration["Stripe:SecretKey"]
    ?? throw new InvalidOperationException("Stripe:SecretKey is not configured.");
if (!stripeKey.StartsWith("sk_"))
    throw new InvalidOperationException("Stripe:SecretKey has invalid format.");
Stripe.StripeConfiguration.ApiKey = stripeKey;
builder.Services.AddCors(options =>
{
    if (builder.Environment.IsDevelopment())
    {
        options.AddPolicy("CorsPolicy", policy =>
        {
            policy.AllowAnyOrigin()
                  .AllowAnyMethod()
                  .AllowAnyHeader();
        });
    }
    else
    {
        options.AddPolicy("CorsPolicy", policy =>
        {
            var origins = builder.Configuration["AllowedOrigins"]
                ?.Split(",", StringSplitOptions.RemoveEmptyEntries)
                ?? Array.Empty<string>();
            policy.WithOrigins(origins)
                  .AllowAnyMethod()
                  .AllowAnyHeader();
        });
    }
});



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
            var logger = context.HttpContext.RequestServices
            .GetRequiredService<ILogger<Program>>();
            logger.LogWarning("Authentication failed: {Message}",
                context.Exception.Message);
            return Task.CompletedTask;
        }
       
    };
});

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy(Policies.AdminOnly, policy =>
    policy.RequireClaim("IsAdministrator", "True"));
});

builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<ICityService, CityService>();
builder.Services.AddScoped<IPharmacyService, PharmacyService>();
builder.Services.AddScoped<IChronicDiseaseService, ChronicDiseaseService>();
builder.Services.AddScoped<IMedicationCategoryService, MedicationCategoryService>();
builder.Services.AddScoped<IPharmacologicalCategoryService, PharmacologicalCategoryService>();
builder.Services.AddScoped<IImageUploadService, ImageUploadService>();
builder.Services.AddScoped<IProductService, ProductService>();
builder.Services.AddScoped<IReservationService, ReservationService>();
builder.Services.AddScoped<IPrescriptionService, PrescriptionService>();
builder.Services.AddScoped<IPatientService, PatientService>();
builder.Services.AddScoped<IInventoryItemService, InventoryItemService>();
builder.Services.AddScoped<IStockMovementService, StockMovementService>();
builder.Services.AddScoped<IPharmacistService, PharmacistService>();
builder.Services.AddScoped<IEarlyDispenseExceptionService, EarlyDispenseExceptionService>();
builder.Services.AddScoped<IPaymentService, PaymentService>();
builder.Services.AddScoped<IPatientChronicDiseaseService, PatientChronicDiseaseService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ICurrentUserService, CurrentUserService>();
builder.Services.AddScoped<IPasswordHasher, PasswordHasher>();

builder.Services.AddScoped<InitialReservationState>();
builder.Services.AddScoped<DraftReservationState>();
builder.Services.AddScoped<SubmittedReservationState>();
builder.Services.AddScoped<ApprovedReservationState>();
builder.Services.AddScoped<ReadyForPickupReservationState>();
builder.Services.AddScoped<PickedUpReservationState>();
builder.Services.AddScoped<CancelledReservationState>();
builder.Services.AddScoped<RejectedReservationState>();

builder.Services.AddSingleton<IRecommendationService, RecommendationService>();
builder.Services.AddSingleton<IRabbitMQPublisher, RabbitMQPublisher>();

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");
builder.Services.AddDatabaseServices(connectionString);
builder.Services.Configure<ApiBehaviorOptions>(options =>
{
    options.InvalidModelStateResponseFactory = context =>
    {
        var errors = context.ModelState
            .Where(x => x.Value?.Errors.Count > 0)
            .SelectMany(kvp => kvp.Value!.Errors.Select(e => e.ErrorMessage))
            .ToList();

        return new BadRequestObjectResult(new
        {
            message = "Validation error.",
            errors
        });
    };
});


builder.Services.AddControllers(x =>
{
    x.Filters.Add<ExceptionFilter>();
})
.AddJsonOptions(options =>
{
    options.JsonSerializerOptions.Converters.Add(
        new System.Text.Json.Serialization.JsonStringEnumConverter());
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
app.Use(async (context, next) =>
{
    context.Request.EnableBuffering();
    await next();
});

using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    var logger = services.GetRequiredService<ILogger<Program>>();
    try
    {
        var context = services.GetRequiredService<PharmionDbContext>();
        var passwordHasher = scope.ServiceProvider.GetRequiredService<IPasswordHasher>();
        await context.Database.MigrateAsync();
        await DatabaseSeeder.SeedAllAsync(context, passwordHasher);
        logger.LogInformation("Database seeded successfully.");
    }
    catch (Exception ex)
    {
        logger.LogCritical(ex, "FATAL: Database migration/seed failed. Application cannot start.");
        throw; 
    }
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
app.UseCors("CorsPolicy"); 
app.UseStaticFiles();
app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();