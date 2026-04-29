using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.AspNetCore.Mvc;
using Pharmion.Model.Exceptions;
using System.Net;

namespace Pharmion.WebAPI.Filters
{
    public class ExceptionFilter : ExceptionFilterAttribute
    {
        private readonly ILogger<ExceptionFilter> _logger;
        public ExceptionFilter(ILogger<ExceptionFilter> logger)
        {
            _logger = logger;
        }
        public override void OnException(ExceptionContext context)
        {
            _logger.LogError(context.Exception, "Unhandled exception: {Message}",
                context.Exception.Message);

            if (context.Exception is EarlyDispenseRequiredException earlyEx)
            {
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.Conflict;
                context.Result = new JsonResult(new
                {
                    requiresEarlyDispenseReason = true,
                    message = earlyEx.Message,
                    nextEligibleDate = earlyEx.NextEligibleDate,
                    daysRemaining = earlyEx.DaysRemaining
                });
            }
            else if (context.Exception is UserException userEx)
            {
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.BadRequest;
                context.Result = new JsonResult(new { message = userEx.Message });
            }
            else if (context.Exception is UnauthorizedAccessException)
            {
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.Forbidden;
                context.Result = new JsonResult(new { message = "Access denied." });
            }
            else if (context.Exception is NotFoundException notFoundEx)
            {
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.NotFound;
                context.Result = new JsonResult(new { message = notFoundEx.Message });
            }
            else
            {
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
                context.Result = new JsonResult(new
                {
                    message = "Server side error, please check logs."
                });
            }

            context.ExceptionHandled = true;
        }
    }
}
