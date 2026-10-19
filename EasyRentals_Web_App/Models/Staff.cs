using System.ComponentModel.DataAnnotations;

namespace EasyRentalWebApp.Models
{
    public class Staff
    {
        [Key]
        public int Id { get; set; }
        public string Username { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;
        public string Role { get; set; } = "Staff";
        public bool MustChangePassword { get; set; } = true;
    }
}
