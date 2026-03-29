using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Enums;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Services.Database;
using Pharmion.Services.Database.Entities;
using Pharmion.Services.Interfaces;
using System;
using System.Threading.Tasks;

namespace Pharmion.Services.Services
{
    public class StockMovementService : IStockMovementService
    {
        private readonly PharmionDbContext _context;

        public StockMovementService(PharmionDbContext context)
        {
            _context = context;
        }

        public async Task<StockMovementResponse> AddMovementAsync(StockMovementRequest request, int pharmacistId)
        {
            var item = await _context.InventoryItems
                .Include(i => i.Product)
                .FirstOrDefaultAsync(i => i.Id == request.InventoryItemId);

            if (item == null)
                throw new UserException("Inventory item not found.");

            // Reason obavezan za Out i Adjustment
            if ((request.Type == StockMovementType.Out || request.Type == StockMovementType.Adjustment)
                && string.IsNullOrWhiteSpace(request.Reason))
                throw new UserException("Reason is required for Out and Adjustment movements.");

            // Validacija količine
            switch (request.Type)
            {
                case StockMovementType.In:
                    item.QuantityOnHand += request.Quantity;
                    break;

                case StockMovementType.Out:
                    var available = item.QuantityOnHand - item.ReservedQuantity;
                    if (request.Quantity > available)
                        throw new UserException($"Cannot remove {request.Quantity} units. Available quantity is {available}.");
                    item.QuantityOnHand -= request.Quantity;
                    break;

                case StockMovementType.Adjustment:
                    if (request.Quantity < item.ReservedQuantity)
                        throw new UserException($"Cannot adjust below reserved quantity ({item.ReservedQuantity}).");
                    item.QuantityOnHand = request.Quantity;
                    break;

                default:
                    throw new UserException("Invalid stock movement type. Use In, Out, or Adjustment.");
            }

            item.UpdatedAt = DateTime.UtcNow;

            var movement = new StockMovement
            {
                InventoryItemId = request.InventoryItemId,
                Type = request.Type,
                Quantity = request.Quantity,
                Reason = request.Reason,
                CreatedAt = DateTime.UtcNow,
                CreatedByPharmacistId = pharmacistId,
            };

            _context.StockMovements.Add(movement);
            await _context.SaveChangesAsync();

            return new StockMovementResponse
            {
                Id = movement.Id,
                InventoryItemId = movement.InventoryItemId,
                Type = movement.Type,
                TypeName = movement.Type.ToString(),
                Quantity = movement.Quantity,
                Reason = movement.Reason,
                CreatedAt = movement.CreatedAt,
            };
        }
    }
}