using EasyRentalWebApp.Data;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace EasyRentals.StaffPortal.Controllers
{
    public class AccountController : Controller
    {
        private readonly AppDbContext _context;

        public AccountController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public IActionResult Login() => View();

        [HttpPost]
        public async Task<IActionResult> Login(string email, string password)
        {
            var staff = await _context.Staff.FirstOrDefaultAsync(s => s.Email == email);

            // Note: In production, use BCrypt or ASP.NET Core Identity for password hashing
            if (staff != null && staff.PasswordHash == password)
            {
                var claims = new List<Claim>
            {
                new Claim(ClaimTypes.Name, staff.Username),
                new Claim(ClaimTypes.Email, staff.Email),
                new Claim(ClaimTypes.Role, staff.Role)
            };

                var claimsIdentity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
                await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, new ClaimsPrincipal(claimsIdentity));

                //staff.LastLogin = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return RedirectToAction("Index", "Dashboard");
            }

            ViewBag.Error = "Invalid email or password";
            return View();
        }

        public async Task<IActionResult> Logout()
        {
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            return RedirectToAction("Login");
        }
    }
}
