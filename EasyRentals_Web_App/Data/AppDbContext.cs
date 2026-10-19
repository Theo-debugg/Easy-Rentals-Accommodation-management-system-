using EasyRentalWebApp.Models;
using Microsoft.EntityFrameworkCore;

namespace EasyRentalWebApp.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<Staff> Staff { get; set; }
        public DbSet<Room> Rooms { get; set; }
        public DbSet<ViewingRequest> ViewingRequests { get; set; }
        public DbSet<Enquiry> Enquiries { get; set; }
        public DbSet<Feedback> Feedbacks { get; set; }
    }
}
