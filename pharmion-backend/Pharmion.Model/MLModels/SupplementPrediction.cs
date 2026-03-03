using System;
using System.Collections.Generic;
using System.Text;

namespace Pharmion.Model.MLModels
{
    public class SupplementPrediction
    {
        [System.Runtime.Serialization.DataMember(Name = "Score")]
        public float Score { get; set; }
    }
}
