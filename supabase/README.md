# Easy Rentals — Supabase Database

> This folder documents the Supabase backend used by the Easy Rentals Student Accommodation Management System.

**Responsibilities**
- Store shared data used by the Flutter mobile app and ASP.NET Core web app.
- Manage authentication for students and authorised staff.
- Apply Row Level Security (RLS) policies to protect data.
- Support property listings, rooms, viewing requests, enquiries, enquiry messages and feedback.

**Planned database tables**
- student
- staff
- property
- room
- viewing_request
- enquiry
- enquiry_messages
- feedback

**Security**
- Students must only access data permitted by their role.
- Staff access must be restricted to authorised staff accounts.
- RLS policies must be tested before the system is used.
