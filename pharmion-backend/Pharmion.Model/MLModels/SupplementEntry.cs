using Microsoft.ML.Data;

public class SupplementEntry
{
    [KeyType(count: 10000)]
    public uint SupplementId { get; set; }

    [KeyType(count: 10000)]
    public uint CoReservedSupplementId { get; set; }

    public float Label { get; set; }
}