using System.ComponentModel.DataAnnotations;

namespace EasyRentalWebApp.Models
{
    public class Room
    {
        [Key]
        public int Id { get; set; }
        public string RoomNumber { get; set; } = string.Empty;
        public string RoomType { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal MonthlyRent { get; set; }
        public string Status { get; set; } = "Available"; //Available, Occupied
        public string Amenities { get; set; } = string.Empty; //Comma separated
    }
}
