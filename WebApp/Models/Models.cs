namespace EasyRentalsStaff.Models;

// A row of the "staff" table (only the columns the portal needs).
public record StaffRow(Guid Id, string FullName, bool MustChangePassword);

//Login Model class
public class LoginViewModel
{
     //Properties
    public string? Email { get; set; }
    public string? Password { get; set; }
    public string? Error { get; set; }
}

//Change Password Model class
public class ChangePasswordViewModel
{
    //Properties
    public string? NewPassword { get; set; }
    public string? ConfirmPassword { get; set; }
    public string? Error { get; set; }
}
