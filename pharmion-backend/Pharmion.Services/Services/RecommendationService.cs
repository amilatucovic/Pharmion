using Microsoft.Extensions.DependencyInjection;
using Microsoft.ML;
using Microsoft.ML.Trainers;
using Pharmion.Model.Enums;
using Pharmion.Model.MLModels;
using Pharmion.Model.Responses;
using Pharmion.Services.Database;
using Pharmion.Services.Database.Entities;
using Pharmion.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Pharmion.Model.Exceptions;

public class RecommendationService : IRecommendationService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly MLContext _mlContext;
    private ITransformer? _model;
    private PredictionEngine<SupplementEntry, SupplementPrediction>? _predictionEngine;
    private readonly object _predictionLock = new object();
    private readonly string _modelFilePath = "supplement_model.zip";
    private readonly ILogger<RecommendationService> _logger;

    public RecommendationService(IServiceScopeFactory scopeFactory, ILogger<RecommendationService> logger)
    {
        _scopeFactory = scopeFactory;
        _mlContext = new MLContext(seed: 42);
        _logger = logger;
    }

    private async Task LoadOrTrainModelAsync()
    {
        if (File.Exists(_modelFilePath))
        {
            using var stream = new FileStream(_modelFilePath, FileMode.Open,
                FileAccess.Read, FileShare.Read);
            _model = _mlContext.Model.Load(stream, out _);
            lock (_predictionLock)
            {
                _predictionEngine = _mlContext.Model
                    .CreatePredictionEngine<SupplementEntry, SupplementPrediction>(_model);
            }
            _logger.LogInformation("ML model loaded from file");
        }
        else
        {
            await TrainAndSaveModelAsync();
        }
    }

    private async Task TrainAndSaveModelAsync()
    {
        using var scope = _scopeFactory.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<PharmionDbContext>();

        var reservationsByPatient = await context.ReservationItems
            .Where(ri => ri.Product.Type == ProductType.Supplement)
            .GroupBy(ri => ri.Reservation.PatientId)
            .Select(g => new
            {
                PatientId = g.Key,
                SupplementIds = g.Select(ri => ri.ProductId).Distinct().ToList()
            })
            .ToListAsync();

        var data = new List<SupplementEntry>();

        foreach (var patient in reservationsByPatient)
        {
            var ids = patient.SupplementIds;
            foreach (var s1 in ids)
            {
                foreach (var s2 in ids)
                {
                    if (s1 != s2)
                    {
                        data.Add(new SupplementEntry
                        {
                            SupplementId = (uint)s1,
                            CoReservedSupplementId = (uint)s2,
                            Label = 1
                        });
                    }
                }
            }
        }

        if (!data.Any())
        {
            _logger.LogWarning("There is not enough data to train the model.");
            return;
        }

        var trainData = _mlContext.Data.LoadFromEnumerable(data);

        var options = new MatrixFactorizationTrainer.Options
        {
            MatrixColumnIndexColumnName = nameof(SupplementEntry.SupplementId),
            MatrixRowIndexColumnName = nameof(SupplementEntry.CoReservedSupplementId),
            LabelColumnName = nameof(SupplementEntry.Label),
            NumberOfIterations = 100,
            ApproximationRank = 32,
            Alpha = 0.01,
            Lambda = 0.025,
            LossFunction = MatrixFactorizationTrainer.LossFunctionType.SquareLossOneClass,
            C = 0.00001
        };

        var estimator = _mlContext.Recommendation().Trainers.MatrixFactorization(options);
        _model = estimator.Fit(trainData);

        using var fs = new FileStream(_modelFilePath, FileMode.Create,
            FileAccess.Write, FileShare.Write);
        _mlContext.Model.Save(_model, trainData.Schema, fs);

        lock (_predictionLock)
        {
            _predictionEngine = _mlContext.Model
                .CreatePredictionEngine<SupplementEntry, SupplementPrediction>(_model);
        }

        _logger.LogInformation("ML model trained with {Count} records and saved", data.Count);
    }

    public async Task<List<RecommendationResponse>> GetRecommendationsAsync(int patientId, int count = 3)
    {
        if (_model == null || _predictionEngine == null)
            await LoadOrTrainModelAsync();

        using var scope = _scopeFactory.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<PharmionDbContext>();

        var patient = await context.Patients
            .FirstOrDefaultAsync(p => p.Id == patientId)
            ?? throw new UserException("Patient not found");

        int age = DateTime.Now.Year - patient.DateOfBirth.Year;

        var reservedIds = await context.ReservationItems
            .Where(ri => ri.Reservation.PatientId == patientId
                      && ri.Product.Type == ProductType.Supplement)
            .Select(ri => ri.ProductId)
            .Distinct()
            .ToListAsync();

        var allSupplements = await context.Products
            .Include(p => p.SupplementDetails)
            .Where(p => p.Type == ProductType.Supplement && p.IsActive)
            .ToListAsync();

        if (!reservedIds.Any())
            return await GetFallbackRecommendationsAsync(context, allSupplements, reservedIds, count);

        var candidates = allSupplements
            .Where(s => !reservedIds.Contains(s.Id))
            .ToList();

        if (!candidates.Any())
            return await GetFallbackRecommendationsAsync(context, allSupplements, reservedIds, count);

        var scores = new Dictionary<int, float>();
        foreach (var reservedId in reservedIds)
        {
            foreach (var candidate in candidates)
            {
                float score;
                lock (_predictionLock)
                {
                    var prediction = _predictionEngine!.Predict(new SupplementEntry
                    {
                        SupplementId = (uint)reservedId,
                        CoReservedSupplementId = (uint)candidate.Id
                    });
                    score = prediction.Score;
                }

                if (scores.ContainsKey(candidate.Id))
                    scores[candidate.Id] += score;
                else
                    scores[candidate.Id] = score;
            }
        }

        var topIds = scores.OrderByDescending(x => x.Value)
            .Take(count)
            .Select(x => x.Key)
            .ToList();

        var topSupplements = candidates
            .Where(s => topIds.Contains(s.Id))
            .OrderBy(s => topIds.IndexOf(s.Id))
            .ToList();

        return topSupplements.Select(s => new RecommendationResponse
        {
            Product = MapToProductResponse(s),
            Score = scores[s.Id],
            Reason = BuildReason()
        }).ToList();
    }

    private async Task<List<RecommendationResponse>> GetFallbackRecommendationsAsync(
        PharmionDbContext context, List<Product> supplements, List<int> reservedIds, int count = 3)
    {
        var popular = await context.ReservationItems
            .Where(ri => ri.Product.Type == ProductType.Supplement
                      && !reservedIds.Contains(ri.ProductId))
            .GroupBy(ri => ri.ProductId)
            .OrderByDescending(g => g.Count())
            .Take(count)
            .Select(g => g.Key)
            .ToListAsync();

        var candidates = supplements.Where(s => popular.Contains(s.Id)).ToList();
        if (!candidates.Any())
            candidates = supplements.Take(5).ToList();

        return candidates.Select(s => new RecommendationResponse
        {
            Product = MapToProductResponse(s),
            Score = 0,
            Reason = "Popular supplement among our users"
        }).ToList();
    }

    private ProductResponse MapToProductResponse(Product s) => new()
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
    };

    private string BuildReason()
    {
        return "Recommended because it is frequently reserved together with similar users";
    }
}