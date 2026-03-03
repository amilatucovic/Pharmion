using Microsoft.EntityFrameworkCore;
using Pharmion.Services.Database.Entities;
using System;
using System.Linq;
using System.Threading.Tasks;

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
            new ChronicDisease { Code = "I10", Name = "Esencijalna (primarna) hipertenzija", Description = "Hronično povišen arterijski krvni pritisak." },
            new ChronicDisease { Code = "I25", Name = "Hronična ishemijska bolest srca", Description = "Dugotrajno smanjena prokrvljenost srčanog mišića." },
            new ChronicDisease { Code = "I50", Name = "Hronično zatajenje srca", Description = "Smanjena sposobnost srca da pumpa krv." },

            // Endokrine i metaboličke bolesti
            new ChronicDisease { Code = "E10", Name = "Dijabetes melitus tip 1", Description = "Autoimuno oboljenje sa apsolutnim nedostatkom inzulina." },
            new ChronicDisease { Code = "E11", Name = "Dijabetes melitus tip 2", Description = "Metabolički poremećaj sa insulinskom rezistencijom." },
            new ChronicDisease { Code = "E03", Name = "Hipotireoza", Description = "Smanjena funkcija štitne žlijezde." },
            new ChronicDisease { Code = "E05", Name = "Hipertireoza", Description = "Povećana funkcija štitne žlijezde." },
            new ChronicDisease { Code = "E66", Name = "Gojaznost", Description = "Hronično stanje prekomjerne tjelesne mase." },

            // Respiratorne bolesti
            new ChronicDisease { Code = "J45", Name = "Astma", Description = "Hronična upalna bolest disajnih puteva." },
            new ChronicDisease { Code = "J44", Name = "Hronična opstruktivna plućna bolest", Description = "Progresivna bolest pluća sa ograničenim protokom zraka." },

            // Neurološke bolesti
            new ChronicDisease { Code = "G35", Name = "Multipla skleroza", Description = "Autoimuna demijelinizacijska bolest centralnog nervnog sistema." },
            new ChronicDisease { Code = "G20", Name = "Parkinsonova bolest", Description = "Progresivni neurodegenerativni poremećaj pokreta." },
            new ChronicDisease { Code = "G40", Name = "Epilepsija", Description = "Hronični neurološki poremećaj sa ponavljanim epileptičnim napadima." },
            new ChronicDisease { Code = "G43", Name = "Migrena", Description = "Hronični poremećaj sa epizodama jake glavobolje." },
            new ChronicDisease { Code = "G30", Name = "Alzheimerova bolest", Description = "Progresivna neurodegenerativna bolest koja dovodi do demencije." },

            // Bubrežne bolesti
            new ChronicDisease { Code = "N18", Name = "Hronična bubrežna bolest", Description = "Postepeni i trajni gubitak funkcije bubrega." },

            // Gastrointestinalne bolesti
            new ChronicDisease { Code = "K50", Name = "Crohnova bolest", Description = "Hronična upalna bolest probavnog trakta." },
            new ChronicDisease { Code = "K51", Name = "Ulcerozni kolitis", Description = "Hronična upalna bolest debelog crijeva." },
            new ChronicDisease { Code = "K21", Name = "Gastroezofagealna refluksna bolest", Description = "Hronični povrat želučane kiseline u jednjak." },

            // Reumatološke i autoimune bolesti
            new ChronicDisease { Code = "M05", Name = "Reumatoidni artritis", Description = "Autoimuna upalna bolest zglobova." },
            new ChronicDisease { Code = "M81", Name = "Osteoporoza bez patološkog prijeloma", Description = "Smanjena gustina kostiju i povećan rizik od prijeloma." },
            new ChronicDisease { Code = "M79.7", Name = "Fibromialgija", Description = "Hronični sindrom difuznih bolova u mišićima." },
            new ChronicDisease { Code = "L40", Name = "Psorijaza", Description = "Hronična autoimuna bolest kože." },
            new ChronicDisease { Code = "M32", Name = "Sistemski eritemski lupus", Description = "Sistemska autoimuna bolest koja može zahvatiti više organa." },

            // Mentalni poremećaji
            new ChronicDisease { Code = "F33", Name = "Rekurentni depresivni poremećaj", Description = "Ponavljajuće epizode depresije." },
            new ChronicDisease { Code = "F41", Name = "Anksiozni poremećaji", Description = "Hronični poremećaji sa izraženom anksioznošću." },

            // Hronične infekcije
            new ChronicDisease { Code = "B18", Name = "Hronični virusni hepatitis", Description = "Dugotrajna virusna infekcija jetre (hepatitis B ili C)." },
            new ChronicDisease { Code = "B20", Name = "HIV bolest", Description = "Hronična infekcija virusom humane imunodeficijencije." }
            };

            await context.ChronicDiseases.AddRangeAsync(diseases);
            await context.SaveChangesAsync();
        }
    }
}