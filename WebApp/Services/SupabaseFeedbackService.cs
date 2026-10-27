using EasyRentalsStaff.Models;

namespace EasyRentalsStaff.Services
{
    public interface IFeedbackService
    {
        Task<List<FeedbackItem>> GetAllAsync(string token);
    }

    /// Reads student feedback using the signed-in staff member's own token,
    /// so Supabase's security rules decide what they may see.
    public class SupabaseFeedbackService : IFeedbackService
    {
        // Change these if your table or columns are named differently
        private const string Table = "feedback";
        private const string Query =
            "select=id,student_id,property_id,rating,comments,created_at" +
            "&order=created_at.desc&limit=1000";

        private readonly SupabaseService _supabase;

        public SupabaseFeedbackService(SupabaseService supabase) => _supabase = supabase;

        public async Task<List<FeedbackItem>> GetAllAsync(string token)
        {
            var rows = await _supabase.SelectAsync<FeedbackRow>(token, Table, Query);

            return rows.Select((r, i) => new FeedbackItem
            {
                Id = i + 1,
                StudentName = string.IsNullOrWhiteSpace(r.Id) ? "Student" : r.Student_Id!,
                PropertyName = r.Property_Id ?? "",
                Rating = Math.Clamp(r.Rating, 1, 5),
                Comment = r.Comment ?? "",
                DateSubmitted = r.CreatedAt.ToLocalTime().DateTime
            }).ToList();
        }
    }

    // One row of the Supabase table. Property names are converted to snake_case
    // by SupabaseService.Json (StudentName -> student_name).
    internal sealed class FeedbackRow
    {
        public string? Id { get; set; }
        public string? Student_Id { get; set; }
        public string? Property_Id { get; set; }
        public int Rating { get; set; }
        public string? Comment { get; set; }
        public DateTimeOffset CreatedAt { get; set; }
    }
}
