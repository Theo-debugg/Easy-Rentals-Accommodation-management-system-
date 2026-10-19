using System.ComponentModel.DataAnnotations;

namespace EasyRentalWebApp.Models
{
    public class ViewingRequest
    {
        [Key]
        public int Id { get; set; }
        public string StudentName { get; set; } = string.Empty;
        public string StudentEmail { get; set; } = string.Empty;
        public int RoomId { get; set; }
        public Room? Room { get; set; }
        public DateTime RequestedDate { get; set; }
        public string Status { get; set; } = "Pending"; //Pending, Approved, Declined
    }
}
