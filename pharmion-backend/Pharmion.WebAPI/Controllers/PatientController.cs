using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;
using Pharmion.Services.Interfaces;

namespace Pharmion.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize(Roles = "Pharmacist")]
    public class PatientController : BaseController<PatientResponse, PatientSearchObject>
    {
        public PatientController(IPatientService patientService) : base(patientService)
        {
        }
    }
}