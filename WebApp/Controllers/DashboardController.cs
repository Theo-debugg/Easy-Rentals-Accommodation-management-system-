using Microsoft.AspNetCore.Mvc;

namespace EasyRentalsStaff.Controllers;

public class DashboardController : Controller
{
    //GET Dashboard(the StaffAuthFilter already guarantees a signed-in staff member)
    [HttpGet]
    public IActionResult Index() => View();
}
