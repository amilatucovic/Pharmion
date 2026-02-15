using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Pharmion.Services.Interfaces
{
    public interface IPharmacologicalCategoryService : ICRUDService<PharmacologicalCategoryResponse, PharmacologicalCategorySearchObject, PharmacologicalCategoryUpsertRequest, PharmacologicalCategoryUpsertRequest>
    {
    }
}
