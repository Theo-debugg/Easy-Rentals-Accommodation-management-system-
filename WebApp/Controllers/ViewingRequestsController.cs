using System.Text.Json;
using System.Text.RegularExpressions;
using EasyRentalsStaff.Models;
using EasyRentalsStaff.Services;
using Microsoft.AspNetCore.Mvc;

namespace EasyRentalsStaff.Controllers;

public class ViewingRequestsController : Controller
{
    //Field variables
    private readonly SupabaseService _supabase;
    
     //Constructor
    public ViewingRequestsController(SupabaseService supabase) => _supabase = supabase;

    //GET /ViewingRequests?q=&status=&room=&date=
    [HttpGet]
    public async Task<IActionResult> Index(string? q, string? status, string? room, string? date)
    {
        var token = HttpContext.Session.Token();

        List<ViewingRequestRow> rows;
        try
        {
            rows = await _supabase.SelectAsync<ViewingRequestRow>(token, "viewing_request", "select=*&limit=1000");
        }
        catch (SupabaseException ex)
        {
            return View(new ViewingRequestsViewModel { LoadError = ex.Message });
        }

        //Student names/emails: looked up separately so no table relationship is needed.
        var people = await LookupStudentsAsync(token,
            rows.Select(r => r.StudentId ?? r.UserId).Where(i => i.HasValue).Select(i => i!.Value));

        var all = rows
            .OrderByDescending(r => r.CreatedAt ?? DateTimeOffset.MinValue)
            .Select(r =>
            {
                var key = ViewingFormat.StatusKey(r.Status);
                var sid = r.StudentId ?? r.UserId;
                people.TryGetValue(sid ?? Guid.Empty, out var person);
                return new ViewingRequestItem
                {
                    Id = r.Id.ToString(),
                    Student = string.IsNullOrWhiteSpace(person.Name) ? "Student" : person.Name!,
                    Email = person.Email ?? "",
                    Property = r.PropertyTitle ?? "",
                    Address = r.PropertyAddress ?? "",
                    Room = r.Room ?? "-",
                    DateIso = ViewingFormat.DateIso(r),
                    When = ViewingFormat.When(r),
                    Status = key,
                    StatusLabel = ViewingFormat.StatusLabel(key)
                };
            })
            .ToList();
            
         //Conditions
        IEnumerable<ViewingRequestItem> filtered = all;
        if (!string.IsNullOrWhiteSpace(q))
        {
            var term = q.Trim();
            filtered = filtered.Where(i =>
                i.Student.Contains(term, StringComparison.OrdinalIgnoreCase) ||
                i.Email.Contains(term, StringComparison.OrdinalIgnoreCase) ||
                i.Room.Contains(term, StringComparison.OrdinalIgnoreCase) ||
                i.Property.Contains(term, StringComparison.OrdinalIgnoreCase));
        }
        if (!string.IsNullOrWhiteSpace(status) && status != "all")
            filtered = filtered.Where(i => i.Status == status);
        if (!string.IsNullOrWhiteSpace(room))
            filtered = filtered.Where(i => i.Room == room);
        if (!string.IsNullOrWhiteSpace(date))
            filtered = filtered.Where(i => i.DateIso == date);

        return View(new ViewingRequestsViewModel
        {
            Items = filtered.ToList(),
            Rooms = all.Select(i => i.Room).Where(r => r != "-").Distinct().OrderBy(r => r).ToList(),
            Q = q, StatusFilter = status, RoomFilter = room, DateFilter = date,
            Total = all.Count,
            Pending = all.Count(i => i.Status == "pending"),
            Approved = all.Count(i => i.Status == "approved"),
            Declined = all.Count(i => i.Status == "declined")
        });
    }

    //POST /ViewingRequests/Decide   (id = the request, decision = approved | declined)
    //Any signed-in staff member can decide for now.
    [HttpPost]
    public async Task<IActionResult> Decide(string id, string decision)
    {
        if (string.IsNullOrWhiteSpace(id) || !Regex.IsMatch(id, "^[A-Za-z0-9-]+$") ||
            (decision != "approved" && decision != "declined"))
        {
            TempData["Error"] = "That request could not be updated.";
            return RedirectToAction(nameof(Index));
        }

        try
        {
            await _supabase.UpdateAsync(HttpContext.Session.Token(), "viewing_request", $"id=eq.{id}", new
            {
                status = decision
            });
            TempData["Message"] = decision == "approved" ? "Viewing approved." : "Viewing declined.";
        }
        catch (SupabaseException ex)
        {
            TempData["Error"] = ex.Message;
        }

        return RedirectToAction(nameof(Index));
    }

    private async Task<Dictionary<Guid, (string? Name, string? Email)>> LookupStudentsAsync(
        string token, IEnumerable<Guid> ids)
    {
        var result = new Dictionary<Guid, (string? Name, string? Email)>();
        var distinct = ids.Distinct().ToList();
        if (distinct.Count == 0) return result;

        try
        {
            var rows = await _supabase.SelectAsync<Dictionary<string, JsonElement>>(token, "student",
                $"select=id,full_name,email&id=in.({string.Join(",", distinct)})");

            foreach (var row in rows)
            {
                if (!row.TryGetValue("id", out var idEl) || !Guid.TryParse(idEl.GetString(), out var id)) continue;
                string? Str(string k) => row.TryGetValue(k, out var v) && v.ValueKind == JsonValueKind.String ? v.GetString() : null;
                result[id] = (Str("full_name"), Str("email"));
            }
        }
        catch (SupabaseException)
        {
            //names fall back to "Student"; the page still works
        }
        return result;
    }
}
