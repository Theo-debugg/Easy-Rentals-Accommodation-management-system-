using EasyRentalsStaff.Models;
using EasyRentalsStaff.Services;
using EasyRentalsStaff.ViewModels;
using Microsoft.AspNetCore.Mvc;

namespace EasyRentalsStaff.Controllers;

public class FeedbackController : Controller
{
     //Field variables
    private const int PageSize = 5;

    private readonly IFeedbackService _feedback;
    private readonly ILogger<FeedbackController> _logger;

     //Constructor
    public FeedbackController(IFeedbackService feedback, ILogger<FeedbackController> logger)
    {
        _feedback = feedback;
        _logger = logger;
    }

    //GET: /Feedback
    public async Task<IActionResult> Index(string? searchTerm, string sortOrder = "newest", int page = 1)
    {
        //Not signed in? Send them to log in.
        //Match this to what your other controllers (e.g. Dashboard) do.
        var token = HttpContext.Session.Token();
        if (string.IsNullOrEmpty(token))
            return RedirectToAction("Login", "Account");

        List<FeedbackItem> all;
        string? loadError = null;
        try
        {
            all = await _feedback.GetAllAsync(token);
        }
        catch (SupabaseException ex)
        {
            _logger.LogError(ex, "Supabase refused the feedback request");
            all = new List<FeedbackItem>();
            loadError = "Supabase says: " + ex.Message;       //temporary
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Could not load feedback");
            all = new List<FeedbackItem>();
            loadError = "Error: " + ex.Message;               //temporary
        }

        var vm = new FeedbackPageViewModel
        {
            TotalReviews = all.Count,
            AverageRating = all.Any() ? Math.Round(all.Average(f => f.Rating), 1) : 0,
            SearchTerm = searchTerm,
            SortOrder = sortOrder,
            PageSize = PageSize,
            LoadError = loadError
        };

        for (int star = 5; star >= 1; star--)
            vm.RatingBreakdown[star] = all.Count(f => f.Rating == star);

        //Search
        IEnumerable<FeedbackItem> filtered = all;
        if (!string.IsNullOrWhiteSpace(searchTerm))
        {
            var term = searchTerm.Trim().ToLower();
            filtered = filtered.Where(f =>
                f.Comment.ToLower().Contains(term) ||
                f.StudentName.ToLower().Contains(term) ||
                f.PropertyName.ToLower().Contains(term));
        }

        //Sort
        filtered = sortOrder switch
        {
            "oldest" => filtered.OrderBy(f => f.DateSubmitted),
            "highest" => filtered.OrderByDescending(f => f.Rating).ThenByDescending(f => f.DateSubmitted),
            "lowest" => filtered.OrderBy(f => f.Rating).ThenByDescending(f => f.DateSubmitted),
            _ => filtered.OrderByDescending(f => f.DateSubmitted)
        };

        //Page
        var filteredList = filtered.ToList();
        vm.FilteredCount = filteredList.Count;
        vm.Page = Math.Clamp(page, 1, vm.TotalPages);
        vm.Reviews = filteredList.Skip((vm.Page - 1) * PageSize).Take(PageSize).ToList();

        return View(vm);
    }
}
