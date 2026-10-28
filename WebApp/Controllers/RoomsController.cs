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
                Photos = await LoadPhotosAsync(token, id),
            };

            return View(model);
        }

        //POST: Rooms/Edit
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(Guid id, RoomViewModel model)
        {
            if (id != model.Id) return NotFound();

            var token = HttpContext.Session.Token();

            if (ModelState.IsValid)
            {
                var updatedRoom = new
                {
                    room_number = model.RoomNumber,
                    room_type = model.RoomType,
                    price = model.Price,
                    description = model.Description,
                    availability = model.Availability,
                    amenities = GetSelectedAmenities(model),
                    staff_id = HttpContext.Session.StaffId(),   // who made the last change
                    updated_at = DateTime.UtcNow
                };

                try
                {
                    await _supabase.UpdateAsync(token, "room", $"id=eq.{id}", updatedRoom);
                    return RedirectToAction(nameof(Index));
                }
                catch (SupabaseException ex)
                {
                    ModelState.AddModelError("", $"Supabase Error: {ex.Message}");
                }
            }

            model.Photos = await LoadPhotosAsync(token, id);
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
                Photos = await LoadPhotosAsync(token, id),
            };

            return View(model);
        }
        // ---- Room photos (Supabase Storage bucket "room-photos" + table "room_photo") ----

        private const long MaxPhotoBytes = 5 * 1024 * 1024;
        private static readonly Dictionary<string, string> PhotoTypes = new()
        {
            [".jpg"] = "image/jpeg",
            [".jpeg"] = "image/jpeg",
            [".png"] = "image/png",
            [".webp"] = "image/webp"
        };

        private async Task<List<RoomPhotoRow>> LoadPhotosAsync(string token, Guid roomId)
        {
            try
            {
                return await _supabase.SelectAsync<RoomPhotoRow>(token, "room_photo",
                    $"room_id=eq.{roomId}&select=id,photo_url&order=created_at.asc");
            }
            catch (SupabaseException)
            {
                // Photos are optional: if the table is not set up yet the page still opens.
                return new List<RoomPhotoRow>();
            }
        }

        // GET: Rooms/Photos/{id}  -> JSON list of the room's photos
        [HttpGet]
        public async Task<IActionResult> Photos(Guid id) =>
            Json(new { photos = await LoadPhotosAsync(HttpContext.Session.Token(), id) });

        // POST: Rooms/UploadPhoto/{id}  (called with fetch() from the Edit page; id = room id)
        [HttpPost]
        public async Task<IActionResult> UploadPhoto(Guid id, IFormFile? photo)
        {
            if (photo is null || photo.Length == 0)
                return BadRequest(new { error = "Choose a photo first." });
            if (photo.Length > MaxPhotoBytes)
                return BadRequest(new { error = "That photo is larger than 5 MB." });

            var ext = Path.GetExtension(photo.FileName).ToLowerInvariant();
            if (!PhotoTypes.TryGetValue(ext, out var contentType))
                return BadRequest(new { error = "Only JPG, PNG or WebP photos are allowed." });

            var token = HttpContext.Session.Token();
            var path = $"{id}/{Guid.NewGuid():N}{ext}";
            var uploaded = false;

            try
            {
                using var ms = new MemoryStream();
                await photo.CopyToAsync(ms);

                // 1. the file goes into the bucket
                var url = await _supabase.UploadRoomPhotoAsync(token, path, ms.ToArray(), contentType);
                uploaded = true;

                // 2. the room_photo row links the room to the file's public address
                await _supabase.InsertAsync(token, "room_photo", new { room_id = id, photo_url = url });
            }
            catch (SupabaseException ex)
            {
                if (uploaded)
                {
                    // don't leave an orphan file behind if the row could not be saved
                    try { await _supabase.DeleteRoomPhotoAsync(token, path); } catch (SupabaseException) { }
                }
                return StatusCode(502, new { error = ex.Message });
            }

            return Json(new { photos = await LoadPhotosAsync(token, id) });
        }

        // POST: Rooms/DeletePhoto/{id}?photoId=...  (id = room id)
        [HttpPost]
        public async Task<IActionResult> DeletePhoto(Guid id, Guid photoId)
        {
            var token = HttpContext.Session.Token();
            try
            {
                // the room_id filter makes sure the photo really belongs to this room
                var photo = (await _supabase.SelectAsync<RoomPhotoRow>(token, "room_photo",
                    $"id=eq.{photoId}&room_id=eq.{id}&select=id,photo_url")).FirstOrDefault();

                if (photo is null)
                    return NotFound(new { error = "That photo no longer exists." });

                var path = SupabaseService.PathFromPublicUrl(photo.PhotoUrl);
                if (path != null)
                    await _supabase.DeleteRoomPhotoAsync(token, path);

                await _supabase.DeleteAsync(token, "room_photo", $"id=eq.{photoId}");
            }
            catch (SupabaseException ex)
            {
                return StatusCode(502, new { error = ex.Message });
            }

            return Json(new { photos = await LoadPhotosAsync(token, id) });
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
