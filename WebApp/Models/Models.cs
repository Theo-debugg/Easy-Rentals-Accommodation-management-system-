namespace EasyRentalsStaff.Models;

// A row of the "staff" table (only the columns the portal needs).
public record StaffRow(Guid Id, string FullName, bool MustChangePassword);

public class LoginViewModel
{
    public string? Email { get; set; }
    public string? Password { get; set; }
    public string? Error { get; set; }
}

public class ChangePasswordViewModel
{
    public string? NewPassword { get; set; }
    public string? ConfirmPassword { get; set; }
    public string? Error { get; set; }
}
