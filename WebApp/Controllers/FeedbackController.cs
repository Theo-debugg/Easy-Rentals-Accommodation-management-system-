using System;
using System.Collections.Generic;
using System.Linq;
using EasyRentals.Models;
using EasyRentals.ViewModels;
using Microsoft.AspNetCore.Mvc;

namespace EasyRentals.Controllers
{
    // [Authorize(Roles = "Staff")]   // <- enable to match your existing auth
    public class FeedbackController : Controller
    {
        private const int PageSize = 5;

        // GET: /Feedback?searchTerm=wifi&sortOrder=newest&page=1
        public IActionResult Index(string? searchTerm, string sortOrder = "newest", int page = 1)
        {
            var all = GetAllFeedback().ToList();

            var vm = new FeedbackPageViewModel
            {
                TotalReviews = all.Count,
                AverageRating = all.Any() ? Math.Round(all.Average(f => f.Rating), 1) : 0,
                SearchTerm = searchTerm,
                SortOrder = sortOrder,
                PageSize = PageSize
            };

            for (int star = 5; star >= 1; star--)
                vm.RatingBreakdown[star] = all.Count(f => f.Rating == star);

            // Search
            IEnumerable<FeedbackItem> filtered = all;
            if (!string.IsNullOrWhiteSpace(searchTerm))
            {
                var term = searchTerm.Trim().ToLower();
                filtered = filtered.Where(f =>
                    f.Comment.ToLower().Contains(term) ||
                    f.StudentName.ToLower().Contains(term) ||
                    f.PropertyName.ToLower().Contains(term));
            }

            // Sort
            filtered = sortOrder switch
            {
                "oldest" => filtered.OrderBy(f => f.DateSubmitted),
                "highest" => filtered.OrderByDescending(f => f.Rating).ThenByDescending(f => f.DateSubmitted),
                "lowest" => filtered.OrderBy(f => f.Rating).ThenByDescending(f => f.DateSubmitted),
                _ => filtered.OrderByDescending(f => f.DateSubmitted)
            };

            // Page
            var filteredList = filtered.ToList();
            vm.FilteredCount = filteredList.Count;
            vm.Page = Math.Clamp(page, 1, vm.TotalPages);
            vm.Reviews = filteredList.Skip((vm.Page - 1) * PageSize).Take(PageSize).ToList();

            return View(vm);
        }

        // ------------------------------------------------------------------
        // SAMPLE DATA. Replace with your database, e.g.
        //   return _db.Feedbacks.AsNoTracking().ToList();
        // ------------------------------------------------------------------
        private static IEnumerable<FeedbackItem> GetAllFeedback() => new List<FeedbackItem>
        {
            new() { Id = 1, StudentName = "Thabo Mokoena", PropertyName = "Easy Rental Property", Rating = 3,
                    Comment = "Great location, but the Wi-Fi in the shared area could be much faster.",
                    DateSubmitted = DateTime.Today.AddDays(-1) },
            new() { Id = 2, StudentName = "Sizwe Nkosi", PropertyName = "Easy Rental Property", Rating = 4,
                    Comment = "Clean rooms and a helpful landlord. Would recommend to other students.",
                    DateSubmitted = DateTime.Today.AddDays(-3) },
            new() { Id = 3, StudentName = "Lerato Dlamini", PropertyName = "Easy Rental Property", Rating = 5,
                    Comment = "Quiet, safe and close to campus. Rent is fair for what you get.",
                    DateSubmitted = DateTime.Today.AddDays(-5) }
        };
    }
}
