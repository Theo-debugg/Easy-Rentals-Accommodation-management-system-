using EasyRentalsStaff.Models;
using EasyRentalsStaff.Services;
using Microsoft.AspNetCore.Mvc;

namespace EasyRentalsStaff.Controllers;

public class EnquiriesController : Controller
{
    // If your Supabase table or column names differ, these three lines are the only
    // place in the controller that needs to change (plus the records in EnquiryModels.cs).
    private const string EnquirySelect = "ReferenceNo,subject,message,status,created_at,student_id,student(full_name,email)";
    private const string MessageSelect = "message,staff_id,created_at";
    private const string MessageColumn = "message";
    private const string MessageLinkColumn = "enquiry_ReferenceNo";

    private readonly SupabaseService _supabase;

    public EnquiriesController(SupabaseService supabase) => _supabase = supabase;

    // GET /Enquiries  -> the list page (columns + filters + search)
    [HttpGet]
    public async Task<IActionResult> Index()
    {
        try
        {
            var rows = await _supabase.SelectAsync<EnquiryRow>(HttpContext.Session.Token(), "enquiries",
                $"select={EnquirySelect}&order=created_at.desc&limit=500");

            return View(new EnquiriesViewModel { Items = rows.Select(ToListItem).ToList() });
        }
        catch (SupabaseException ex)
        {
            return View(new EnquiriesViewModel { LoadError = ex.Message });
        }
    }

    // GET /Enquiries/Thread/{reference}  -> JSON for the side panel
    [HttpGet]
    public Task<IActionResult> Thread(Guid id) => ThreadResult(id);

    // POST /Enquiries/Reply/{reference}  -> save a staff reply, return the updated thread
    [HttpPost]
    public async Task<IActionResult> Reply(Guid id, [FromBody] ReplyRequest request)
    {
        var text = request?.Text?.Trim();
        if (string.IsNullOrEmpty(text))
            return BadRequest(new { error = "Type a reply first." });
        if (text.Length > 2000)
            return BadRequest(new { error = "Replies can be at most 2000 characters." });

        var token = HttpContext.Session.Token();
        try
        {
            var enquiry = await FindAsync(token, id);
            if (enquiry is null) return NotFound(new { error = "Enquiry not found." });

            await _supabase.InsertAsync(token, "enquiry_messages", new Dictionary<string, object>
            {
                [MessageLinkColumn] = id,
                ["staff_id"] = HttpContext.Session.StaffId(),
                ["student_id"] = enquiry.StudentId!,
                [MessageColumn] = text
            });

            // First staff reply moves a brand-new enquiry to "in progress".
            if (EnquiryFormat.StatusKey(enquiry.Status) == "new")
                await _supabase.UpdateAsync(token, "enquiries", $"ReferenceNo=eq.{id}", new { status = "in_progress" });
        }
        catch (SupabaseException ex)
        {
            return StatusCode(502, new { error = ex.Message });
        }

        return await ThreadResult(id);
    }

    // POST /Enquiries/Resolve/{reference}
    [HttpPost]
    public async Task<IActionResult> Resolve(Guid id)
    {
        try
        {
            await _supabase.UpdateAsync(HttpContext.Session.Token(), "enquiries",
                $"ReferenceNo=eq.{id}", new { status = "resolved" });
        }
        catch (SupabaseException ex)
        {
            return StatusCode(502, new { error = ex.Message });
        }

        return await ThreadResult(id);
    }

    // ---- helpers -----------------------------------------------------------

    private async Task<EnquiryRow?> FindAsync(string token, Guid id) =>
        (await _supabase.SelectAsync<EnquiryRow>(token, "enquiries",
            $"ReferenceNo=eq.{id}&select={EnquirySelect}")).FirstOrDefault();

    private async Task<IActionResult> ThreadResult(Guid id)
    {
        var token = HttpContext.Session.Token();
        try
        {
            var enquiry = await FindAsync(token, id);
            if (enquiry is null) return NotFound(new { error = "Enquiry not found." });

            var messages = await _supabase.SelectAsync<MessageRow>(token, "enquiry_messages",
                $"{MessageLinkColumn}=eq.{id}&select={MessageSelect}&order=created_at.asc");

            // The student's first message lives on the enquiry itself; replies follow it.
            var thread = new List<ThreadMessageDto>();
            if (!string.IsNullOrWhiteSpace(enquiry.Message))
                thread.Add(new ThreadMessageDto
                {
                    FromStaff = false,
                    Sender = StudentName(enquiry),
                    Stamp = EnquiryFormat.MessageStamp(enquiry.CreatedAt),
                    Text = enquiry.Message!
                });

            var status = EnquiryFormat.StatusKey(enquiry.Status);
            return Json(new ThreadDto
            {
                ReferenceNo = enquiry.ReferenceNo,
                ShortRef = EnquiryFormat.ShortRef(enquiry.ReferenceNo),
                Subject = enquiry.Subject ?? "(no subject)",
                Student = StudentName(enquiry),
                Email = enquiry.Student?.Email ?? "",
                Status = status,
                StatusLabel = EnquiryFormat.StatusLabel(status),
                Messages = thread.Concat(messages.Select(m => new ThreadMessageDto
                {
                    FromStaff = m.StaffId is not null,
                    Sender = m.StaffId is not null ? "Staff" : StudentName(enquiry),
                    Stamp = EnquiryFormat.MessageStamp(m.CreatedAt),
                    Text = m.Message ?? ""
                })).ToList()
            });
        }
        catch (SupabaseException ex)
        {
            return StatusCode(502, new { error = ex.Message });
        }
    }

    private static string StudentName(EnquiryRow e) =>
        string.IsNullOrWhiteSpace(e.Student?.FullName) ? "Student" : e.Student!.FullName!;

    private static EnquiryListItem ToListItem(EnquiryRow e)
    {
        var status = EnquiryFormat.StatusKey(e.Status);
        return new EnquiryListItem
        {
            ReferenceNo = e.ReferenceNo,
            ShortRef = EnquiryFormat.ShortRef(e.ReferenceNo),
            Student = StudentName(e),
            Subject = e.Subject ?? "(no subject)",
            Status = status,
            StatusLabel = EnquiryFormat.StatusLabel(status),
            Received = EnquiryFormat.ListStamp(e.CreatedAt)
        };
    }
}
