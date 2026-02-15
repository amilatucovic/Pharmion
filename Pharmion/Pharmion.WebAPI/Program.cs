using Mapster;
using Microsoft.EntityFrameworkCore;
using Pharmion.Services.Database;
using Pharmion.Services.Interfaces;
using Pharmion.Services.Services;


var builder = WebApplication.CreateBuilder(args);
builder.Services.AddScoped<ICityService, CityService>();
builder.Services.AddScoped<IPharmacyService, PharmacyService>();
builder.Services.AddScoped<IChronicDiseaseService, ChronicDiseaseService>();
builder.Services.AddScoped<IMedicationCategoryService, MedicationCategoryService>();
builder.Services.AddScoped<IPharmacologicalCategoryService, PharmacologicalCategoryService>();
// Add services to the container.
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ?? "Server=localhost;Database=220207;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True";
builder.Services.AddDatabaseServices(connectionString);
builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddMapster();


var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
