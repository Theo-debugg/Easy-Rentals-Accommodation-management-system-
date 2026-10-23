
using Microsoft.AspNetCore.Mvc;

namespace EasyRentalsStaff.Controllers;

public class ViewingRequestsController : Controller
{
    [HttpGet]
    public IActionResult Index()
    {
        return View();
    }
}
