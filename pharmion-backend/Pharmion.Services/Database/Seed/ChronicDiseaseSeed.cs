using Microsoft.EntityFrameworkCore;
using Pharmion.Services.Database.Entities;
using Pharmion.Services.Interfaces;

namespace Pharmion.Services.Database.Seed
{
    public class ChronicDiseaseSeed : IEntitySeeder<ChronicDisease>
    {
        public async Task SeedAsync(PharmionDbContext context)
        {
            if (await context.ChronicDiseases.AnyAsync())
                return;

            var diseases = new[]
            {
                
                new ChronicDisease { Code = "I10", Name = "Essential (primary) hypertension", Description = "Chronically elevated arterial blood pressure." },
                new ChronicDisease { Code = "I25", Name = "Chronic ischaemic heart disease", Description = "Long-term reduced blood supply to the heart muscle." },
                new ChronicDisease { Code = "I50", Name = "Chronic heart failure", Description = "Reduced ability of the heart to pump blood." },

                new ChronicDisease { Code = "E10", Name = "Type 1 diabetes mellitus", Description = "Autoimmune disease with absolute insulin deficiency." },
                new ChronicDisease { Code = "E11", Name = "Type 2 diabetes mellitus", Description = "Metabolic disorder characterised by insulin resistance." },
                new ChronicDisease { Code = "E03", Name = "Hypothyroidism", Description = "Reduced function of the thyroid gland." },
                new ChronicDisease { Code = "E05", Name = "Hyperthyroidism", Description = "Increased function of the thyroid gland." },
                new ChronicDisease { Code = "E66", Name = "Obesity", Description = "Chronic condition of excess body weight." },

                new ChronicDisease { Code = "J45", Name = "Asthma", Description = "Chronic inflammatory disease of the airways." },
                new ChronicDisease { Code = "J44", Name = "Chronic obstructive pulmonary disease (COPD)", Description = "Progressive lung disease with limited airflow." },

                new ChronicDisease { Code = "G35", Name = "Multiple sclerosis", Description = "Autoimmune demyelinating disease of the central nervous system." },
                new ChronicDisease { Code = "G20", Name = "Parkinson's disease", Description = "Progressive neurodegenerative movement disorder." },
                new ChronicDisease { Code = "G40", Name = "Epilepsy", Description = "Chronic neurological disorder with recurrent seizures." },
                new ChronicDisease { Code = "G43", Name = "Migraine", Description = "Chronic disorder with episodes of severe headache." },
                new ChronicDisease { Code = "G30", Name = "Alzheimer's disease", Description = "Progressive neurodegenerative disease leading to dementia." },

                new ChronicDisease { Code = "N18", Name = "Chronic kidney disease", Description = "Progressive and permanent loss of kidney function." },

                new ChronicDisease { Code = "K50", Name = "Crohn's disease", Description = "Chronic inflammatory bowel disease affecting the digestive tract." },
                new ChronicDisease { Code = "K51", Name = "Ulcerative colitis", Description = "Chronic inflammatory disease of the large intestine." },
                new ChronicDisease { Code = "K21", Name = "Gastro-oesophageal reflux disease (GERD)", Description = "Chronic backflow of stomach acid into the oesophagus." },

                new ChronicDisease { Code = "M05", Name = "Rheumatoid arthritis", Description = "Autoimmune inflammatory disease of the joints." },
                new ChronicDisease { Code = "M81", Name = "Osteoporosis without pathological fracture", Description = "Reduced bone density with increased fracture risk." },
                new ChronicDisease { Code = "M79.7", Name = "Fibromyalgia", Description = "Chronic syndrome of diffuse muscle pain." },
                new ChronicDisease { Code = "L40", Name = "Psoriasis", Description = "Chronic autoimmune skin disease." },
                new ChronicDisease { Code = "M32", Name = "Systemic lupus erythematosus", Description = "Systemic autoimmune disease that can affect multiple organs." },

                new ChronicDisease { Code = "F33", Name = "Recurrent depressive disorder", Description = "Recurrent episodes of depression." },
                new ChronicDisease { Code = "F41", Name = "Anxiety disorders", Description = "Chronic disorders characterised by marked anxiety." },

                new ChronicDisease { Code = "B18", Name = "Chronic viral hepatitis", Description = "Long-term viral infection of the liver (hepatitis B or C)." },
                new ChronicDisease { Code = "B20", Name = "HIV disease", Description = "Chronic infection with the human immunodeficiency virus." }
            };

            await context.ChronicDiseases.AddRangeAsync(diseases);
            await context.SaveChangesAsync();
        }
    }
}