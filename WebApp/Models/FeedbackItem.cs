using System;

namespace EasyRentalsStaff.Models
{
    public class FeedbackItem
    {
        //Properties
        public int Id { get; set; }
        public string StudentName { get; set; } = "";
        public string PropertyName { get; set; } = "";
        public int Rating { get; set; }            // 1 - 5
        public string Comment { get; set; } = "";
        public DateTime DateSubmitted { get; set; }

        public string Initials
        {
            get
            {
                //Condition
                if (string.IsNullOrWhiteSpace(StudentName)) return "?";
                var parts = StudentName.Split(' ', StringSplitOptions.RemoveEmptyEntries);
                return parts.Length == 1
                    ? parts[0].Substring(0, 1).ToUpper()
                    : (parts[0].Substring(0, 1) + parts[^1].Substring(0, 1)).ToUpper();
            }
        }
    }
}
