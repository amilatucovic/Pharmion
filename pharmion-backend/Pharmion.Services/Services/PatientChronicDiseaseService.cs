using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Responses;
using Pharmion.Services.Database;
using Pharmion.Services.Database.Entities;
using Pharmion.Services.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Pharmion.Services.Services
{
    public class PatientChronicDiseaseService : IPatientChronicDiseaseService
    {
        private readonly PharmionDbContext _context;

        public PatientChronicDiseaseService(PharmionDbContext context)
        {
            _context = context;
        }

        public async Task<List<PatientChronicDiseaseResponse>> GetMyDiseasesAsync(int patientId)
        {
            return await _context.PatientChronicDiseases
                .Include(pcd => pcd.ChronicDisease)
                .Where(pcd => pcd.PatientId == patientId)
                .Select(pcd => new PatientChronicDiseaseResponse
                {
                    Id = pcd.Id,
                    ChronicDiseaseId = pcd.ChronicDiseaseId,
                    Code = pcd.ChronicDisease!.Code,
                    Name = pcd.ChronicDisease.Name,
                    Description = pcd.ChronicDisease.Description,
                    DiagnosedAt = pcd.DiagnosedAt,
                    Notes = pcd.Notes
                })
                .ToListAsync();
        }

        public async Task AddDiseaseAsync(int patientId, int chronicDiseaseId)
        {
            var exists = await _context.PatientChronicDiseases
                .AnyAsync(pcd => pcd.PatientId == patientId
                              && pcd.ChronicDiseaseId == chronicDiseaseId);
            if (exists)
                throw new UserException("This disease is already added to your profile.");

            var disease = await _context.ChronicDiseases.FindAsync(chronicDiseaseId)
                ?? throw new UserException("Chronic disease not found.");

            _context.PatientChronicDiseases.Add(new PatientChronicDisease
            {
                PatientId = patientId,
                ChronicDiseaseId = chronicDiseaseId,
                DiagnosedAt = DateTime.UtcNow,
                CreatedAt = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();
        }

        public async Task RemoveDiseaseAsync(int patientId, int chronicDiseaseId)
        {
            var record = await _context.PatientChronicDiseases
                .FirstOrDefaultAsync(pcd => pcd.PatientId == patientId
                                         && pcd.ChronicDiseaseId == chronicDiseaseId)
                ?? throw new UserException("Disease not found on your profile.");

            _context.PatientChronicDiseases.Remove(record);
            await _context.SaveChangesAsync();
        }
    }
}