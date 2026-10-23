using EasyRentalsStaff.Models;
using EasyRentalsStaff.Services;
using Microsoft.AspNetCore.Mvc;

namespace EasyRentalsStaff.Controllers;

public class ProfileController : Controller
{
    private readonly SupabaseService _supabase;

    public ProfileController(SupabaseService supabase) => _supabase = supabase;

    // GET /Profile  -> read-only details of the signed-in staff member
    [HttpGet]
    public async Task<IActionResult> Index()
    {
        var token = HttpContext.Session.Token();
        var id = HttpContext.Session.StaffId();

        var staff = (await _supabase.SelectAsync<ProfileRow>(token, "staff",
            $"id=eq.{id}&select=id,full_name,email,role")).FirstOrDefault();

        if (staff is null)
            return RedirectToAction("Logout", "Account");

        // The activity numbers are a bonus: if one fails, show "-" instead of breaking the page.
        var replies = await CountAsync<IdRow>(token, "enquiry_messages", $"staff_id=eq.{id}&select=id");
        var rooms = await CountAsync<IdRow>(token, "rooms", $"updated_by=eq.{id}&select=id");
        var open = await CountAsync<RefRow>(token, "enquiries", "status=eq.new&select=ReferenceNo");

        return View(new ProfileViewModel(staff, replies, rooms, open));
    }

    // GET /Profile/ChangePassword  -> its own page
    [HttpGet]
    public IActionResult ChangePassword() => View(new ChangePasswordViewModel());

    // POST /Profile/ChangePassword
    [HttpPost]
    public async Task<IActionResult> ChangePassword(ChangePasswordViewModel model)
    {
        if (string.IsNullOrEmpty(model.NewPassword) || model.NewPassword.Length < 8)
        {
            model.Error = "Use at least 8 characters.";
            return View(model);
        }
        if (model.NewPassword != model.ConfirmPassword)
        {
            model.Error = "The passwords do not match.";
            return View(model);
        }

        try
        {
            await _supabase.UpdatePasswordAsync(HttpContext.Session.Token(), model.NewPassword);
            TempData["Message"] = "Your password was updated.";
            return RedirectToAction(nameof(Index));
        }
        catch (SupabaseException ex)
        {
            model.Error = ex.Message;
            return View(model);
        }
    }

    private async Task<int?> CountAsync<T>(string token, string table, string query)
    {
        try { return (await _supabase.SelectAsync<T>(token, table, query)).Count; }
        catch (SupabaseException) { return null; }
    }
}
