using EasyRentalsStaff.Models;

namespace EasyRentalsStaff.ViewModels;

public class FeedbackPageViewModel
{
    // Reviews for the current page only
    public List<FeedbackItem> Reviews { get; set; } = new();

    // Summary cards (calculated on ALL reviews)
    public double AverageRating { get; set; }
    public int TotalReviews { get; set; }
    public Dictionary<int, int> RatingBreakdown { get; set; } =
        new() { { 5, 0 }, { 4, 0 }, { 3, 0 }, { 2, 0 }, { 1, 0 } };

    // Search / sort state
    public string? SearchTerm { get; set; }
    public string SortOrder { get; set; } = "newest";

    // Paging
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 5;
    public int FilteredCount { get; set; }
    public int TotalPages => Math.Max(1, (int)Math.Ceiling(FilteredCount / (double)PageSize));
    public int ShowingFrom => FilteredCount == 0 ? 0 : (Page - 1) * PageSize + 1;
    public int ShowingTo => Math.Min(Page * PageSize, FilteredCount);

    // Error message if Supabase can't be reached
    public string? LoadError { get; set; }
}