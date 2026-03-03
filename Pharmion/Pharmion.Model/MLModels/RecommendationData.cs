using Microsoft.ML.Data;

namespace Pharmion.Model.MLModels
{
    public class SupplementRatingData
    {
        public float PatientAge { get; set; }
        public float PatientGender { get; set; }
        public float GenderMatch { get; set; }
        public float AgeMatch { get; set; }
        public float ProductPrice { get; set; }
        public float Label { get; set; }
    }
}