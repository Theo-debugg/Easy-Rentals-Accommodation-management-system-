using System.ComponentModel.DataAnnotations;
using EasyRentalsStaff.Models;

namespace EasyRentalsStaff.ViewModel
{
    public class RoomViewModel
    {
        public Guid Id { get; set; }

        [Required(ErrorMessage = "Property ID is required")]
        [Display(Name = "Property ID")]
        public Guid PropertyId { get; set; }

        [Required(ErrorMessage = "Room Number is required")]
        [Display(Name = "Room Number")]
        public string RoomNumber { get; set; } = string.Empty;

        [Display(Name = "Room Type")]
        public string? RoomType { get; set; }

        public List<string> RoomTypeOptions { get; } = new()
        {
            "Single Room",
            "Sharing",
        };

        [Display(Name = "Price")]
        public decimal? Price { get; set; }

        public string? Description { get; set; }

        [Display(Name = "Availability")]
        public string Availability { get; set; } = "Available";

        public bool HasWiFi { get; set; }
        public bool HasPool { get; set; }
        public bool HasParking { get; set; }
        public bool HasLaundry { get; set; }

        public List<string> ExistingAmenities { get; set; } = new List<string>();

        // Photos already uploaded for this room (read from the room_photo table)
        public List<RoomPhotoRow> Photos { get; set; } = new();
    }
}
