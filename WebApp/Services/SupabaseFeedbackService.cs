using System.Text.Json;
using EasyRentalsStaff.Models;

namespace EasyRentalsStaff.Services;

public interface IFeedbackService
{
    Task<List<FeedbackItem>> GetAllAsync(string token);
}

public class SupabaseFeedbackService : IFeedbackService
{
    // ---- Your table and column names (change these to match Supabase) ----
    private const string FeedbackTable = "feedback";
    // Columns read from the feedback table (ids for student and property, plus the review).
    // The Flutter app saves the written review in the "comments" column.
    private const string FeedbackColumns = "id,student_id,property_id,rating,comments,created_at";

    private const string StudentTable = "student";      // table holding student names
    private const string StudentNameColumn = "full_name"; // column with the student's name

    private const string PropertyTable = "properties";   // table holding properties
    private const string PropertyNameColumn = "title";    // column with the property's name
    // ----------------------------------------------------------------------

    private readonly SupabaseService _supabase;

    public SupabaseFeedbackService(SupabaseService supabase) => _supabase = supabase;

    public async Task<List<FeedbackItem>> GetAllAsync(string token)
    {
        var rows = await _supabase.SelectAsync<FeedbackRow>(
            token, FeedbackTable,
            $"select={FeedbackColumns}&order=created_at.desc&limit=1000");

        // Look up the names for every student and comment that appears
        var students = await LookupNamesAsync(token, StudentTable, StudentNameColumn,
                                              rows.Select(r => r.StudentId));
        var properties = await LookupNamesAsync(token, PropertyTable, PropertyNameColumn,
                                                rows.Select(r => r.PropertyId));

        return rows.Select((r, i) => new FeedbackItem
        {
            Id = i + 1,
            StudentName = Name(students, r.StudentId, "Student"),
            PropertyName = Name(properties, r.PropertyId, ""),
            Rating = Math.Clamp(r.Rating, 1, 5),
            Comment = r.Comments ?? "",
            DateSubmitted = r.CreatedAt.ToLocalTime().DateTime
        }).ToList();
    }

    private static string Name(Dictionary<string, string> lookup, string? id, string fallback) =>
        id != null && lookup.TryGetValue(id, out var name) && !string.IsNullOrWhiteSpace(name)
            ? name
            : fallback;

    // Fetches "id -> name" pairs for the given ids from one table.
    // If the lookup fails (for example no permission), names simply fall back to the default.
    private async Task<Dictionary<string, string>> LookupNamesAsync(
        string token, string table, string nameColumn, IEnumerable<string?> ids)
    {
        var result = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        var distinct = ids.Where(i => !string.IsNullOrWhiteSpace(i)).Distinct().ToList();
        if (distinct.Count == 0) return result;

        try
        {
            var rows = await _supabase.SelectAsync<Dictionary<string, JsonElement>>(
                token, table,
                $"select=id,{nameColumn}&id=in.({string.Join(",", distinct)})");

            foreach (var row in rows)
            {
                if (!row.TryGetValue("id", out var idEl)) continue;
                var id = idEl.ToString();
                var name = row.TryGetValue(nameColumn, out var nameEl) && nameEl.ValueKind == JsonValueKind.String
                    ? nameEl.GetString() ?? ""
                    : "";
                result[id] = name;
            }
        }
        catch (SupabaseException)
        {
            // Leave the dictionary empty: the page still loads, with default names
        }
        return result;
    }
}

// One row of the feedback table. Names convert to snake_case automatically
// (StudentId -> student_id). Change a property name if your column differs.
internal sealed class FeedbackRow
{
    public string? StudentId { get; set; }
    public string? PropertyId { get; set; }
    public int Rating { get; set; }
    public string? Comments { get; set; }      // column "comments" (the Flutter app writes it)
    public DateTimeOffset CreatedAt { get; set; }
}