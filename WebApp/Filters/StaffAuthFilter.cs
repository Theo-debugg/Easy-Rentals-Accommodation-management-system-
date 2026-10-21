using EasyRentalsStaff.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace EasyRentalsStaff.Filters;

/// Put on an action that a signed-in staff member may open even while they
/// still have to change the default password (only ChangePassword uses this).
[AttributeUsage(AttributeTargets.Method | AttributeTargets.Class)]
public class AllowWhenPasswordChangeRequiredAttribute : Attribute { }

/// Global filter. Replaces the middleware "gatekeeper" of the Razor Pages version.
///  - [AllowAnonymous] actions (Login, Logout, Error) are open to everyone.
///  - Everything else needs a signed-in staff member with an unexpired token.
///  - While must_change is "true", only [AllowWhenPasswordChangeRequired] actions are allowed.
public class StaffAuthFilter : IActionFilter
{
    public void OnActionExecuting(ActionExecutingContext context)
    {
        var metadata = context.ActionDescriptor.EndpointMetadata;

        if (metadata.OfType<IAllowAnonymous>().Any())
            return;

        var session = context.HttpContext.Session;
        var token = session.GetString("token");
        var expiresAt = long.TryParse(session.GetString("expires_at"), out var e) ? e : 0;

        if (token is null || DateTimeOffset.UtcNow.ToUnixTimeSeconds() >= expiresAt)
        {
            session.Clear();
            context.Result = new RedirectToActionResult("Login", "Account", null);
            return;
        }

        if (session.GetString("must_change") == "true"
            && !metadata.OfType<AllowWhenPasswordChangeRequiredAttribute>().Any())
        {
            context.Result = new RedirectToActionResult("ChangePassword", "Account", null);
        }
    }

    public void OnActionExecuted(ActionExecutedContext context) { }
}
