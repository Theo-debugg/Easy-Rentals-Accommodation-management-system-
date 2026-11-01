using EasyRentalsStaff.Filters;
using EasyRentalsStaff.Models;
using EasyRentalsStaff.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EasyRentalsStaff.Controllers;

public class AccountController : Controller
{
    //Field variable
    private readonly SupabaseService _supabase;

     //Constructor
    public AccountController(SupabaseService supabase) => _supabase = supabase;

    //---- Login ---------------------------------------------------------
    [AllowAnonymous]
    [HttpGet]
    public IActionResult Login() => View(new LoginViewModel());

    [AllowAnonymous]
    [HttpPost]
    public async Task<IActionResult> Login(LoginViewModel model)
    {
        if (string.IsNullOrWhiteSpace(model.Email) || string.IsNullOrWhiteSpace(model.Password))
        {
            model.Error = "Enter your email address and password.";
            return View(model);
        }

        try
        {
            //1. Supabase Auth checks the email and password.
            var result = await _supabase.SignInAsync(model.Email.Trim(), model.Password);

            //2. Only staff may use this portal.
            var staff = (await _supabase.SelectAsync<StaffRow>(
                result.AccessToken, "staff",
                $"id=eq.{result.UserId}&select=id,full_name,must_change_password")).FirstOrDefault();

            if (staff is null)
            {
                model.Error = "This account is not a staff account.";
                return View(model);
            }

            //3. Remember who is signed in.
            HttpContext.Session.Clear();
            HttpContext.Session.SetString("token", result.AccessToken);
            HttpContext.Session.SetString("expires_at",
                (DateTimeOffset.UtcNow.ToUnixTimeSeconds() + result.ExpiresIn - 60).ToString());
            HttpContext.Session.SetString("staff_id", staff.Id.ToString());
            HttpContext.Session.SetString("staff_name", staff.FullName);
            HttpContext.Session.SetString("staff_email", model.Email.Trim());
            HttpContext.Session.SetString("must_change", staff.MustChangePassword ? "true" : "false");

            //4. First login with the default password? Force a password change.
            return staff.MustChangePassword
                ? RedirectToAction(nameof(ChangePassword))
                : RedirectToAction("Index", "Dashboard");
        }
        catch (SupabaseException ex)
        {
            model.Error = ex.Message;
            return View(model);
        }
    }

    //---- Logout --------------------------------------------------------
    [AllowAnonymous]
    [HttpGet]
    public IActionResult Logout()
    {
        HttpContext.Session.Clear();
        return RedirectToAction(nameof(Login));
    }

    //---- First-login password change ----------------------------------
    [AllowWhenPasswordChangeRequired]
    [HttpGet]
    public IActionResult ChangePassword() => View(new ChangePasswordViewModel());

    [AllowWhenPasswordChangeRequired]
    [HttpPost]
    public async Task<IActionResult> ChangePassword(ChangePasswordViewModel model)
    {
         //Condition to check if password format is right
        if (string.IsNullOrEmpty(model.NewPassword) || model.NewPassword.Length < 8)
        {
            model.Error = "Use at least 8 characters.";
            return View(model);
        }
         //Condition to check if password matches the previous one
        if (model.NewPassword != model.ConfirmPassword)
        {
            model.Error = "The passwords do not match.";
            return View(model);
        }

        var token = HttpContext.Session.Token();
        try
        {
            await _supabase.UpdatePasswordAsync(token, model.NewPassword);

            await _supabase.UpdateAsync(token, "staff",
                $"id=eq.{HttpContext.Session.StaffId()}",
                new { MustChangePassword = false });

            HttpContext.Session.SetString("must_change", "false");
            return RedirectToAction("Index", "Dashboard");
        }
        catch (SupabaseException ex)
        {
            model.Error = ex.Message;
            return View(model);
        }
    }
}
