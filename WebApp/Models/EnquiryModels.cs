using System.Text.Json.Serialization;

namespace EasyRentalsStaff.Models;

// ---- Rows read from Supabase ------------------------------------------------
// (SupabaseService converts snake_case column names to these property names.)

// Embedded student details: enquiries -> student (full_name, email).
public record StudentRef(string? FullName, string? Email);

// A row of the "enquiries" table.
// Note: the key column is spelled "ReferenceNo" in your database (capital letters).
public record EnquiryRow(
    [property: JsonPropertyName("ReferenceNo")] Guid ReferenceNo,
    string? Subject,
    string? Message,          // the student's first message
    string? Status,
    DateTimeOffset CreatedAt,
    [property: JsonPropertyName("student")] StudentRef? Student);

// A row of the "enquiry_messages" table. A message with a staff_id was written by
// staff; a message without one came from the student.
public record MessageRow(string? Message, Guid? StaffId, DateTimeOffset CreatedAt);

// ---- What the pages and the side panel use ---------------------------------

public class EnquiryListItem
{
    public Guid ReferenceNo { get; init; }
    public string ShortRef { get; init; } = "";
    public string Student { get; init; } = "";
    public string Subject { get; init; } = "";
    public string Status { get; init; } = "new";          // new | in_progress | resolved
    public string StatusLabel { get; init; } = "New";
    public string Received { get; init; } = "";
}

public class EnquiriesViewModel
{
    public List<EnquiryListItem> Items { get; init; } = new();
    public string? LoadError { get; init; }
    public int All => Items.Count;
    public int New => Items.Count(i => i.Status == "new");
    public int InProgress => Items.Count(i => i.Status == "in_progress");
    public int Resolved => Items.Count(i => i.Status == "resolved");
}

public class ThreadMessageDto
{
    public bool FromStaff { get; init; }
    public string Sender { get; init; } = "";
    public string Stamp { get; init; } = "";
    public string Text { get; init; } = "";
}

public class ThreadDto
{
    public Guid ReferenceNo { get; init; }
    public string ShortRef { get; init; } = "";
    public string Subject { get; init; } = "";
    public string Student { get; init; } = "";
    public string Email { get; init; } = "";
    public string Status { get; init; } = "new";
    public string StatusLabel { get; init; } = "New";
    public List<ThreadMessageDto> Messages { get; init; } = new();
}

public class ReplyRequest
{
    public string? Text { get; set; }
}

// ---- Small formatting helpers ----------------------------------------------

public static class EnquiryFormat
{
    private static readonly TimeZoneInfo Zone = FindZone();

    private static TimeZoneInfo FindZone()
    {
        foreach (var id in new[] { "South Africa Standard Time", "Africa/Johannesburg" })
        {
            try { return TimeZoneInfo.FindSystemTimeZoneById(id); }
            catch (TimeZoneNotFoundException) { }
            catch (InvalidTimeZoneException) { }
        }
        return TimeZoneInfo.CreateCustomTimeZone("SAST", TimeSpan.FromHours(2), "SAST", "SAST");
    }

    private static DateTime Local(DateTimeOffset t) => TimeZoneInfo.ConvertTime(t, Zone).DateTime;

    // First 8 characters of the reference number, upper case: 3F9A21C4
    public static string ShortRef(Guid id) => id.ToString("N")[..8].ToUpperInvariant();

    public static string StatusKey(string? status) => (status ?? "new").Trim().ToLowerInvariant() switch
    {
        "resolved" => "resolved",
        "in_progress" or "in progress" or "inprogress" or "open" => "in_progress",
        _ => "new"
    };

    public static string StatusLabel(string key) => key switch
    {
        "resolved" => "Resolved",
        "in_progress" => "In progress",
        _ => "New"
    };

    // "Today 09:12", "Yesterday 16:40", "20 Oct 08:30"
    public static string ListStamp(DateTimeOffset t)
    {
        var local = Local(t);
        var today = Local(DateTimeOffset.UtcNow).Date;
        if (local.Date == today) return $"Today {local:HH:mm}";
        if (local.Date == today.AddDays(-1)) return $"Yesterday {local:HH:mm}";
        return local.ToString("d MMM HH:mm");
    }

    // "22 Oct 09:12"
    public static string MessageStamp(DateTimeOffset t) => Local(t).ToString("d MMM HH:mm");
}
