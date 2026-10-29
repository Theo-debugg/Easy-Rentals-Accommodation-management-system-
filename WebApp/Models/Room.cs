using System.Text.Json.Serialization;

namespace EasyRentalsStaff.Models
{
    public class Room
    {
        //Properties
        [JsonPropertyName("id")]
        public Guid Id { get; set; }

        [JsonPropertyName("property_id")]
        public Guid PropertyId { get; set; }

        [JsonPropertyName("room_number")]
        public string RoomNumber { get; set; } = string.Empty;

        [JsonPropertyName("room_type")]
        public string? RoomType { get; set; }

        [JsonPropertyName("price")]
        public decimal? Price { get; set; }

        [JsonPropertyName("description")]
        public string? Description { get; set; }

        [JsonPropertyName("availability")]
        public string? Availability { get; set; }

        [JsonPropertyName("amenities")]
        public string? Amenities { get; set; }

        [JsonPropertyName("updated_at")]
        public DateTime? UpdatedAt { get; set; }

        [JsonPropertyName("staff_id")]
        public Guid? StaffId { get; set; }
    }

    //A row of the "room_photo" table (one uploaded picture of a room).
    public record RoomPhotoRow(Guid Id, string PhotoUrl);
}
