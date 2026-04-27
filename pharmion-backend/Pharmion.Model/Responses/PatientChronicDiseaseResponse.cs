using System;

namespace Pharmion.Model.Responses
{
    public class PatientChronicDiseaseResponse
    {
        public int Id { get; set; }
        public int ChronicDiseaseId { get; set; }
        public string Code { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public DateTime DiagnosedAt { get; set; }
        public string Notes { get; set; } = string.Empty;
    }
}