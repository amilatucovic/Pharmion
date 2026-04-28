using Pharmion.Model.Enums;
using System.ComponentModel.DataAnnotations;

public class AddToReservationRequest
{
    [Required]
    public int PharmacyId { get; set; }
    [Required]
    public int ProductId { get; set; }
    [Required, Range(1, 999)]
    public int Quantity { get; set; }
    public int? PrescriptionItemId { get; set; }
    public bool IsSubstitutionAllowed { get; set; } = false;

    public EarlyDispenseReasonType? EarlyDispenseReasonType { get; set; }
    public string? EarlyDispenseReason { get; set; } 
}