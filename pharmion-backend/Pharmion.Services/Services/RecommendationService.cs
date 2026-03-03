using Microsoft.Extensions.DependencyInjection;
using Microsoft.ML;
using Pharmion.Model.Enums;
using Pharmion.Model.MLModels;
using Pharmion.Model.Responses;
using Pharmion.Services.Database.Entities;
using Pharmion.Services.Database;
using Pharmion.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

public class RecommendationService : IRecommendationService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly MLContext _mlContext;
    private ITransformer? _cachedModel;
    private DateTime _lastTrainedAt = DateTime.MinValue;
    private static readonly TimeSpan _retrainInterval = TimeSpan.FromHours(24);

    public RecommendationService(IServiceScopeFactory scopeFactory)
    {
        _scopeFactory = scopeFactory;
        _mlContext = new MLContext(seed: 42);
    }

    public async Task<List<ProductResponse>> GetRecommendationsAsync(int patientId)
    {
        using var scope = _scopeFactory.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<PharmionDbContext>();

        var patient = await context.Patients
            .FirstOrDefaultAsync(p => p.Id == patientId)
            ?? throw new Exception("Pacijent nije pronađen");

        int age = DateTime.Now.Year - patient.DateOfBirth.Year;
        float genderFloat = patient.Gender == Gender.Female ? 1f : 0f;

        var supplements = await context.Products
            .Include(p => p.SupplementDetails)
            .Where(p => p.Type == ProductType.Supplement && p.IsActive)
            .ToListAsync();

        var reservedSupplementIds = await context.ReservationItems
            .Where(ri => ri.Reservation.PatientId == patientId
                      && ri.Product.Type == ProductType.Supplement)
            .Select(ri => ri.ProductId)
            .Distinct()
            .ToListAsync();

        // Treniraj samo ako nije cachiran ili stariji od 24h
        if (_cachedModel == null || DateTime.UtcNow - _lastTrainedAt > _retrainInterval)
        {
            var trainingData = await BuildTrainingDataAsync(context, supplements);

            if (trainingData.Count < 5)
                return await GetFallbackRecommendationsAsync(context, supplements, reservedSupplementIds);

            _cachedModel = TrainModel(trainingData);
            _lastTrainedAt = DateTime.UtcNow;
            Console.WriteLine($"[{DateTime.Now:HH:mm:ss}] ML model treniran sa {trainingData.Count} zapisa");
        }

        var candidates = supplements
            .Where(s => !reservedSupplementIds.Contains(s.Id))
            .ToList();

        if (!candidates.Any())
            return await GetFallbackRecommendationsAsync(context, supplements, reservedSupplementIds);

        // Kreiraj prediction engine jednom za sve kandidate
        var predictionEngine = _mlContext.Model
            .CreatePredictionEngine<SupplementRatingData, SupplementPrediction>(_cachedModel);

        var predictions = candidates.Select(supplement =>
        {
            var details = supplement.SupplementDetails;
            var input = new SupplementRatingData
            {
                PatientAge = age,
                PatientGender = genderFloat,
                GenderMatch = CalculateGenderMatch(patient.Gender, details?.TargetGender),
                AgeMatch = CalculateAgeMatch(age, details?.MinAge, details?.MaxAge),
                ProductPrice = (float)supplement.Price,
                Label = 0
            };
            return new { Supplement = supplement, Score = predictionEngine.Predict(input).Score };
        })
        .OrderByDescending(x => x.Score)
        .Take(5)
        .ToList();

        return predictions.Select(p => new ProductResponse
        {
            Id = p.Supplement.Id,
            Name = p.Supplement.Name,
            Type = p.Supplement.Type,
            TypeName = p.Supplement.Type.ToString(),
            IsPrescriptionRequired = p.Supplement.IsPrescriptionRequired,
            IsActive = p.Supplement.IsActive,
            SKU = p.Supplement.SKU,
            Barcode = p.Supplement.Barcode,
            Manufacturer = p.Supplement.Manufacturer,
            Unit = p.Supplement.Unit,
            PackageSize = p.Supplement.PackageSize,
            Price = p.Supplement.Price,
            SideEffects = p.Supplement.SideEffects,
            InstructionsForUse = p.Supplement.InstructionsForUse,
            Contraindications = p.Supplement.Contraindications,
            ImageUrl = p.Supplement.ImageUrl,
            CreatedAt = p.Supplement.CreatedAt,
            UpdatedAt = p.Supplement.UpdatedAt
        }).ToList();
    }

    private async Task<List<SupplementRatingData>> BuildTrainingDataAsync(
        PharmionDbContext context, List<Product> supplements)
    {
        var trainingData = new List<SupplementRatingData>();
        var patients = await context.Patients.ToListAsync();

        foreach (var patient in patients)
        {
            int age = DateTime.Now.Year - patient.DateOfBirth.Year;
            float genderFloat = patient.Gender == Gender.Female ? 1f : 0f;

            var reservedIds = await context.ReservationItems
                .Where(ri => ri.Reservation.PatientId == patient.Id
                          && ri.Product.Type == ProductType.Supplement)
                .Select(ri => ri.ProductId)
                .Distinct()
                .ToListAsync();

            foreach (var supplement in supplements)
            {
                var details = supplement.SupplementDetails;
                trainingData.Add(new SupplementRatingData
                {
                    PatientAge = age,
                    PatientGender = genderFloat,
                    GenderMatch = CalculateGenderMatch(patient.Gender, details?.TargetGender),
                    AgeMatch = CalculateAgeMatch(age, details?.MinAge, details?.MaxAge),
                    ProductPrice = (float)supplement.Price,
                    Label = reservedIds.Contains(supplement.Id) ? 1.0f : 0.0f
                });
            }
        }

        return trainingData;
    }

    private ITransformer TrainModel(List<SupplementRatingData> trainingData)
    {
        var dataView = _mlContext.Data.LoadFromEnumerable(trainingData);

        var pipeline = _mlContext.Transforms
            .Concatenate("Features",
                nameof(SupplementRatingData.PatientAge),
                nameof(SupplementRatingData.PatientGender),
                nameof(SupplementRatingData.GenderMatch),
                nameof(SupplementRatingData.AgeMatch),
                nameof(SupplementRatingData.ProductPrice))
            .Append(_mlContext.Regression.Trainers.Sdca(
                labelColumnName: "Label",
                featureColumnName: "Features"));

        return pipeline.Fit(dataView);
    }

    private async Task<List<ProductResponse>> GetFallbackRecommendationsAsync(
        PharmionDbContext context, List<Product> supplements, List<int> reservedIds)
    {
        var popular = await context.ReservationItems
            .Where(ri => ri.Product.Type == ProductType.Supplement
                      && !reservedIds.Contains(ri.ProductId))
            .GroupBy(ri => ri.ProductId)
            .OrderByDescending(g => g.Count())
            .Take(5)
            .Select(g => g.Key)
            .ToListAsync();

        var candidates = supplements.Where(s => popular.Contains(s.Id)).ToList();

        if (!candidates.Any())
            candidates = supplements.Take(5).ToList();

        return candidates.Select(s => new ProductResponse
        {
            Id = s.Id,
            Name = s.Name,
            Type = s.Type,
            TypeName = s.Type.ToString(),
            IsPrescriptionRequired = s.IsPrescriptionRequired,
            IsActive = s.IsActive,
            SKU = s.SKU,
            Barcode = s.Barcode,
            Manufacturer = s.Manufacturer,
            Unit = s.Unit,
            PackageSize = s.PackageSize,
            Price = s.Price,
            SideEffects = s.SideEffects,
            InstructionsForUse = s.InstructionsForUse,
            Contraindications = s.Contraindications,
            ImageUrl = s.ImageUrl,
            CreatedAt = s.CreatedAt,
            UpdatedAt = s.UpdatedAt
        }).ToList();
    }

    private float CalculateGenderMatch(Gender patientGender, Gender? targetGender)
    {
        if (targetGender == null) return 0.5f;
        return patientGender == targetGender ? 1.0f : 0.0f;
    }

    private float CalculateAgeMatch(int age, int? minAge, int? maxAge)
    {
        if (minAge == null && maxAge == null) return 0.5f;
        if (minAge.HasValue && age < minAge.Value) return 0.0f;
        if (maxAge.HasValue && age > maxAge.Value) return 0.0f;
        return 1.0f;
    }
}