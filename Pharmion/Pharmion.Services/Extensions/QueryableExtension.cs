using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Pharmion.Services.Extensions
{
    public static class QueryableExtension
    {
        public static IQueryable<T> OrderByDynamic<T>(this IQueryable<T> source, string propertyName)
        {
            if (string.IsNullOrEmpty(propertyName))
                return source;

            // Remove any prefix like "-" for descending order
            var cleanPropertyName = propertyName.TrimStart('-');

            try
            {
                return source.OrderBy(e => EF.Property<object>(e, cleanPropertyName));
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Property '{cleanPropertyName}' not found on entity type '{typeof(T).Name}'. Available properties: {string.Join(", ", typeof(T).GetProperties().Select(p => p.Name))}", ex);
            }
        }

        public static IQueryable<T> OrderByDescendingDynamic<T>(this IQueryable<T> source, string propertyName)
        {
            if (string.IsNullOrEmpty(propertyName))
                return source;

            // Remove any prefix like "-" for descending order
            var cleanPropertyName = propertyName.TrimStart('-');

            try
            {
                return source.OrderByDescending(e => EF.Property<object>(e, cleanPropertyName));
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException($"Property '{cleanPropertyName}' not found on entity type '{typeof(T).Name}'. Available properties: {string.Join(", ", typeof(T).GetProperties().Select(p => p.Name))}", ex);
            }
        }
    }
}

