using System.Text.Json.Serialization;

namespace EasyRentalsStaff.Models;

//A row of the "staff" table, as shown on the profile page.
public record ProfileRow(Guid Id, string FullName, string? Email);

//Tiny rows used only to count records.
public record IdRow(Guid Id);
public record RefRow([property: JsonPropertyName("ReferenceNo")] Guid ReferenceNo);

public class ProfileViewModel
{
    //Constructor
    public ProfileViewModel(ProfileRow staff, int? repliesSent, int? roomsUpdated, int? openEnquiries)
    {
        StaffId = staff.Id;
        FullName = staff.FullName;
        Email = staff.Email ?? "-";
        RepliesSent = repliesSent;
        RoomsUpdated = roomsUpdated;
        OpenEnquiries = openEnquiries;
    }
      //Properties
    public Guid StaffId { get; }
    public string FullName { get; }
    public string Email { get; }
    public int? RepliesSent { get; }
    public int? RoomsUpdated { get; }
    public int? OpenEnquiries { get; }

    public string Initials
    {
        get
        {
            var parts = FullName.Split(' ', StringSplitOptions.RemoveEmptyEntries);
            return parts.Length == 0 ? "?"
                : string.Concat(parts.Take(2).Select(p => char.ToUpper(p[0])));
        }
    }
}
