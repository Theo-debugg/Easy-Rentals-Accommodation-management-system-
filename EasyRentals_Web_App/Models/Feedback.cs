using System.ComponentModel.DataAnnotations;

namespace EasyRentalWebApp.Models
{
    public class Feedback
    {
        [Key]
        public int Id { get; set; }
        public string StudentName { get; set; } = string.Empty;
        public string Comment { get; set; } = string.Empty;
        public int Rating { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
