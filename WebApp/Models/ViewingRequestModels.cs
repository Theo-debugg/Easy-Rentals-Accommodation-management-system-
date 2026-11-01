using System.Globalization;
using System.Text.Json;

namespace EasyRentalsStaff.Models;

//A row of the "viewing_request" table, exactly as the Flutter app saves it.
//Every field is optional and the query uses select=*, so a column that is
//missing from your table can never break the page.
public record ViewingRequestRow(
    JsonElement Id,                 //uuid (or a number): kept as-is and shown as text
    Guid? StudentId,
    Guid? UserId,
    string? PropertyTitle,
    string? PropertyAddress,
    string? Room,
    string? PreferredDate,
    string? PreferredTime,
    string? ViewingDate,
    string? ViewingTime,
    string? Status,
    DateTimeOffset? CreatedAt);

public class ViewingRequestItem
{
    //Properties some with default values
    public string Id { get; init; } = "";
    public string Student { get; init; } = "Student";
    public string Email { get; init; } = "";
    public string Property { get; init; } = "";
    public string Address { get; init; } = "";
    public string Room { get; init; } = "";
    public string DateIso { get; init; } = "";       // yyyy-MM-dd, used by the date filter
    public string When { get; init; } = "";           // "27 Oct 2026, 09:00 AM - 10:00 AM"
    public string Status { get; init; } = "pending";  // pending | approved | declined
    public string StatusLabel { get; init; } = "Pending";
}

public class ViewingRequestsViewModel
{
    //Properties
    public List<ViewingRequestItem> Items { get; init; } = new();   //after the filters
    public List<string> Rooms { get; init; } = new();                //for the room filter
    public string? LoadError { get; init; }

    public string? Q { get; init; }
    public string? StatusFilter { get; init; }
    public string? RoomFilter { get; init; }
    public string? DateFilter { get; init; }

    //Counts always cover ALL requests, not just the filtered ones.
    public int Total { get; init; }
    public int Pending { get; init; }
    public int Approved { get; init; }
    public int Declined { get; init; }
}

public static class ViewingFormat
{
    public static string StatusKey(string? status) => (status ?? "pending").Trim().ToLowerInvariant() switch
    {
        "approved" or "approve" or "accepted" => "approved",
        "declined" or "decline" or "rejected" or "denied" => "declined",
        _ => "pending"           // "pending", "review", empty ...
    };

    public static string StatusLabel(string key) => key switch
    {
        "approved" => "Approved",
        "declined" => "Declined",
        _ => "Pending"
    };

    public static string DateIso(ViewingRequestRow r)
    {
        var raw = r.PreferredDate ?? r.ViewingDate;
        return DateOnly.TryParse(raw, CultureInfo.InvariantCulture, DateTimeStyles.None, out var d)
            ? d.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)
            : "";
    }

    public static string When(ViewingRequestRow r)
    {
        var date = DateIso(r);
        var dateText = date == ""
            ? "-"
            : DateOnly.ParseExact(date, "yyyy-MM-dd", CultureInfo.InvariantCulture)
                .ToString("d MMM yyyy", CultureInfo.InvariantCulture);

        //The Flutter app keeps the slot the student picked ("09:00 AM - 10:00 AM") in viewing_time
        var time = !string.IsNullOrWhiteSpace(r.ViewingTime) ? r.ViewingTime!.Trim()
                 : !string.IsNullOrWhiteSpace(r.PreferredTime)
                     ? (r.PreferredTime!.Length >= 5 ? r.PreferredTime![..5] : r.PreferredTime!)
                     : "";
        return time == "" ? dateText : $"{dateText}, {time}";
    }
}
