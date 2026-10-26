using Supabase.Postgrest.Attributes;
using Supabase.Postgrest.Models;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;
using ColumnAttribute = Supabase.Postgrest.Attributes.ColumnAttribute;
using TableAttribute = Supabase.Postgrest.Attributes.TableAttribute;

namespace EasyRentalsStaff.Models
{
    public class Room
    {
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
        public DateTime UpdatedAt { get; set; }

        [JsonPropertyName("staff_id")]
        public Guid? StaffId { get; set; }
    }
}
