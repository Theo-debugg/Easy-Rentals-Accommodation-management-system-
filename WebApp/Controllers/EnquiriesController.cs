using System.Text.Json;
using EasyRentalsStaff.Models;
using EasyRentalsStaff.Services;
using Microsoft.AspNetCore.Mvc;

namespace EasyRentalsStaff.Controllers;

public class EnquiriesController : Controller
{
    /Field Variables
    private const string EnquirySelect = "ReferenceNo,subject,message,status,created_at,student_id";
    private const string MessageSelect = "message,staff_id,created_at";
    private const string MessageColumn = "message";
    private const string MessageLinkColumn = "enquiry_ReferenceNo";

    private readonly SupabaseService _supabase;
    
     //Constructor
    public EnquiriesController(SupabaseService supabase) => _supabase = supabase;

    //GET /Enquiries -> the list page (columns + filters + search)
    [HttpGet]
    public async Task<IActionResult> Index()
    {
        try
        {
            var rows = await _supabase.SelectAsync<EnquiryRow>(HttpContext.Session.Token(), "enquiries",
                $"select={EnquirySelect}&order=created_at.desc&limit=500");
            var students = await LookupStudentsAsync(HttpContext.Session.Token(), rows.Select(r => r.StudentId));

            return View(new EnquiriesViewModel { Items = rows.Select(row => ToListItem(row, students)).ToList() });
        }
        catch (SupabaseException ex)
        {
            return View(new EnquiriesViewModel { LoadError = ex.Message });
        }
    }

    //GET /Enquiries/Thread/{reference}  -> JSON for the side panel
    [HttpGet]
    public Task<IActionResult> Thread(Guid id) => ThreadResult(id);

    //POST /Enquiries/Reply/{reference}  -> save a staff reply, return the updated thread
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

            //First staff reply moves a brand-new enquiry to "in progress".
            if (EnquiryFormat.StatusKey(enquiry.Status) == "new")
                await _supabase.UpdateAsync(token, "enquiries", $"ReferenceNo=eq.{id}", new { status = "in_progress" });
        }
        catch (SupabaseException ex)
        {
            return StatusCode(502, new { error = ex.Message });
        }

        return await ThreadResult(id);
    }

    //POST /Enquiries/Resolve/{reference}
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

    //---- helpers -----------------------------------------------------------
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
            var students = await LookupStudentsAsync(token, new[] { enquiry.StudentId });

            var messages = await _supabase.SelectAsync<MessageRow>(token, "enquiry_messages",
                $"{MessageLinkColumn}=eq.{id}&select={MessageSelect}&order=created_at.asc");

            //The student's first message lives on the enquiry itself; replies follow it.
            var thread = new List<ThreadMessageDto>();
            if (!string.IsNullOrWhiteSpace(enquiry.Message))
                thread.Add(new ThreadMessageDto
                {
                    FromStaff = false,
                    Sender = StudentName(enquiry, students),
                    Stamp = EnquiryFormat.MessageStamp(enquiry.CreatedAt),
                    Text = enquiry.Message!
                });

            var status = EnquiryFormat.StatusKey(enquiry.Status);
            return Json(new ThreadDto
            {
                ReferenceNo = enquiry.ReferenceNo,
                ShortRef = EnquiryFormat.ShortRef(enquiry.ReferenceNo),
                Subject = enquiry.Subject ?? "(no subject)",
                Student = StudentName(enquiry, students),
                Email = enquiry.StudentId is Guid studentId && students.TryGetValue(studentId, out var student)
                    ? student.Email ?? ""
                    : "",
                Status = status,
                StatusLabel = EnquiryFormat.StatusLabel(status),
                Messages = thread.Concat(messages.Select(m => new ThreadMessageDto
                {
                    FromStaff = m.StaffId is not null,
                    Sender = m.StaffId is not null ? "Staff" : StudentName(enquiry, students),
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

    private static string StudentName(EnquiryRow e, IReadOnlyDictionary<Guid, StudentRef> students) =>
        e.StudentId is Guid id && students.TryGetValue(id, out var student) &&
        !string.IsNullOrWhiteSpace(student.FullName) ? student.FullName! : "Student";

    private static EnquiryListItem ToListItem(EnquiryRow e, IReadOnlyDictionary<Guid, StudentRef> students)
    {
        var status = EnquiryFormat.StatusKey(e.Status);
        return new EnquiryListItem
        {
            ReferenceNo = e.ReferenceNo,
            ShortRef = EnquiryFormat.ShortRef(e.ReferenceNo),
            Student = StudentName(e, students),
            Subject = e.Subject ?? "(no subject)",
            Status = status,
            StatusLabel = EnquiryFormat.StatusLabel(status),
            Received = EnquiryFormat.ListStamp(e.CreatedAt)
        };
    }

    private async Task<Dictionary<Guid, StudentRef>> LookupStudentsAsync(string token, IEnumerable<Guid?> ids)
    {
        var result = new Dictionary<Guid, StudentRef>();
        var distinct = ids.Where(id => id.HasValue).Select(id => id!.Value).Distinct().ToList();
        if (distinct.Count == 0) return result;

        try
        {
            var rows = await _supabase.SelectAsync<Dictionary<string, JsonElement>>(
                token, "student", $"select=id,full_name,email&id=in.({string.Join(",", distinct)})");

            foreach (var row in rows)
            {
                if (!row.TryGetValue("id", out var idElement) || !Guid.TryParse(idElement.GetString(), out var id))
                    continue;

                string? StringValue(string name) =>
                    row.TryGetValue(name, out var value) && value.ValueKind == JsonValueKind.String
                        ? value.GetString()
                        : null;

                result[id] = new StudentRef(StringValue("full_name"), StringValue("email"));
            }
        }
        catch (SupabaseException)
        {
            //Keep the page usable and use the standard fallback when lookup access is unavailable.
        }

        return result;
    }
}
