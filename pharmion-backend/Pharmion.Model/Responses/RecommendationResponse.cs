using Pharmion.Model.Responses;

public class RecommendationResponse
{
    public ProductResponse Product { get; set; }
    public string Reason { get; set; } 
    public float Score { get; set; }
}