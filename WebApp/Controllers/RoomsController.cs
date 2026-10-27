using EasyRentalsStaff.Models;
using EasyRentalsStaff.Services;
using EasyRentalsStaff.ViewModel;
using Microsoft.AspNetCore.Mvc;


namespace EasyRentalsStaff.Controllers
{
    //[Authorize]
    public class RoomsController : Controller
    {
        private readonly SupabaseService _supabase;

        public RoomsController(SupabaseService supabase)
        {
            _supabase = supabase;
        }

        //GET: Rooms
        public async Task<IActionResult> Index(string searchString, string statusFilter)
        {
            var token = HttpContext.Session.Token();

            //Fetch all rooms using supabase service
            var rooms = await _supabase.SelectAsync<Room>(token, "room", "select=*");

            //Apply search and filter in memory
            if (!string.IsNullOrEmpty(searchString))
            {
                rooms = rooms.Where(r => r.RoomNumber.Contains(searchString, StringComparison.OrdinalIgnoreCase)).ToList();
            }

            //Apply status tab filter
            if (!string.IsNullOrEmpty(statusFilter) && statusFilter != "All")
            {
                rooms = rooms.Where(r => r.Availability == statusFilter).ToList();
            }

            ViewBag.TotalRooms = rooms.Count;
            ViewBag.AvailableRooms = rooms.Count(r => r.Availability == "Available");
            ViewBag.OccupiedRooms = rooms.Count(r => r.Availability == "Occupied");
            ViewBag.MaintenanceRooms = rooms.Count(r => r.Availability == "Maintenance");

            return View(rooms);
        }

        //GET: Rooms/Add
        [HttpGet]
        public IActionResult Add() => View(new RoomViewModel());

        //POST: Rooms/Add
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Add(RoomViewModel model)
        {
            if (ModelState.IsValid)
            {
                var token = HttpContext.Session.Token();
                var staffId = HttpContext.Session.StaffId();

                var newRoom = new
                {
                    property_id = model.PropertyId,
                    room_number = model.RoomNumber,
                    room_type = model.RoomType,
                    price = model.Price,
                    description = model.Description,
                    availability = model.Availability,
                    amenities = GetSelectedAmenities(model),
                    staff_id = staffId,
                    updated_at = DateTime.UtcNow
                };

                try
                {
                    //Use supabase service to insert the data
                    await _supabase.InsertAsync(token, "room", newRoom);
                    return RedirectToAction(nameof(Index));
                }
                catch (SupabaseException ex)
                {
                    ModelState.AddModelError("", $"Supabase Error: {ex.Message}");
                }
            }

            return View(model);
        }

        //GET: Rooms/Edit
        [HttpGet]
        public async Task<IActionResult> Edit(Guid id)
        {
            var token = HttpContext.Session.Token();

            // Use your SelectAsync with a filter
            var rooms = await _supabase.SelectAsync<Room>(token, "room", $"select=*&id=eq.{id}");
            var room = rooms.FirstOrDefault();

            if (room == null) return NotFound();

            var model = new RoomViewModel
            {
                Id = room.Id,
                PropertyId = room.PropertyId,
                RoomNumber = room.RoomNumber,
                RoomType = room.RoomType,
                Price = room.Price,
                Description = room.Description,
                Availability = room.Availability ?? "Available",
                HasWiFi = room.Amenities?.Contains("Wi-Fi") ?? false,
                HasPool = room.Amenities?.Contains("Pool") ?? false,
                HasParking = room.Amenities?.Contains("Parking") ?? false,
                HasLaundry = room.Amenities?.Contains("Laundry") ?? false,
            };

            return View(model);
        }

        //POST: Rooms/Edit
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(Guid id, RoomViewModel model)
        {
            if (id != model.Id) return NotFound();

            if (ModelState.IsValid)
            {
                var token = HttpContext.Session.Token();

                var updatedRoom = new
                {
                    room_number = model.RoomNumber,
                    room_type = model.RoomType,
                    price = model.Price,
                    description = model.Description,
                    availability = model.Availability,
                    amenities = GetSelectedAmenities(model),
                    updated_at = DateTime.UtcNow
                };

                //Use your UpdateAsync method
                await _supabase.UpdateAsync(token, "room", $"id=eq.{id}", updatedRoom);

                return RedirectToAction(nameof(Index));
            }
            return View(model);
        }

        //GET: Rooms/Details/
        public async Task<IActionResult> Details(Guid id)
        {
            var token = HttpContext.Session.Token();

            // Fetch the specific room from Supabase
            var rooms = await _supabase.SelectAsync<Room>(token, "room", $"select=*&id=eq.{id}");
            var room = rooms.FirstOrDefault();

            if (room == null)
            {
                return NotFound();
            }

            // Map database model to ViewModel
            var model = new RoomViewModel
            {
                Id = room.Id,
                PropertyId = room.PropertyId,
                RoomNumber = room.RoomNumber,
                RoomType = room.RoomType,
                Price = room.Price,
                Description = room.Description,
                Availability = room.Availability ?? "Available",
                HasWiFi = room.Amenities?.Contains("Wi-Fi") ?? false,
                HasPool = room.Amenities?.Contains("Pool") ?? false,
                HasParking = room.Amenities?.Contains("Parking") ?? false,
                HasLaundry = room.Amenities?.Contains("Laundry") ?? false,
            };

            return View(model);
        }
        private string GetSelectedAmenities(RoomViewModel model)
        {
            var amenities = new List<string>();
            if (model.HasWiFi) amenities.Add("Wi-Fi");
            if (model.HasPool) amenities.Add("Pool");
            if (model.HasParking) amenities.Add("Parking");
            if (model.HasLaundry) amenities.Add("Laundry");
            return string.Join(",", amenities);
        }
       
    }
}
