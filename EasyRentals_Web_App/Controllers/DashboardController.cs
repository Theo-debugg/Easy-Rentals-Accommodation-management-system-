using EasyRentalWebApp.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace EasyRentals.StaffPortal.Controllers
{
    [Authorize]
    public class DashboardController : Controller
    {
        private readonly AppDbContext _context;

        public DashboardController(AppDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> Index()
        {
            ViewBag.PendingRequests = await _context.ViewingRequests.CountAsync(r => r.Status == "Pending");
            ViewBag.NewEnquiries = await _context.Enquiries.CountAsync(e => e.Status == "New");
            ViewBag.AvailableRooms = await _context.Rooms.CountAsync(r => r.Status == "Available");

            var recentRequests = await _context.ViewingRequests
                .Include(r => r.Room)
                .OrderByDescending(r => r.RequestedDate)
                .Take(5)
                .ToListAsync();

            return View(recentRequests);
        }
    }
}
