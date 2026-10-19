using System.ComponentModel.DataAnnotations;

namespace EasyRentalWebApp.Models
{
    public class Enquiry
    {
        [Key]
        public int Id { get; set; }
        public string StudentName { get; set; } = string.Empty;
        public string Subject { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public DateTime ReceivedDate { get; set; } = DateTime.UtcNow;
        public string Status { get; set; } = "New"; //New, In Progress, Resolved
        public string? StaffReply { get; set; }
    }
}
