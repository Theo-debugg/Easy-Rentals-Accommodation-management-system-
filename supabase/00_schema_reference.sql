create table if not exists public.student (
  id          uuid not null,
  full_name   text not null,
  email       text not null unique,
  created_at  timestamptz not null default timezone('utc'::text, now()),
  constraint student_pkey primary key (id),
  constraint students_id_fkey foreign key (id) references auth.users(id)
);

create table if not exists public.staff (
  id                    uuid not null,
  full_name             text not null,
  email                 text not null unique,
  created_at            timestamptz not null default timezone('utc'::text, now()),
  must_change_password  boolean not null,
  constraint staff_pkey primary key (id),
  constraint staff_id_fkey foreign key (id) references auth.users(id)
);

create table if not exists public.property (
  id           uuid not null default gen_random_uuid(),
  title        text not null,
  address      text not null,
  description  text,
  created_at   timestamptz not null default timezone('utc'::text, now()),
  constraint property_pkey primary key (id)
);

create table if not exists public.room (
  id            uuid not null default gen_random_uuid(),
  property_id   uuid not null,
  room_number   text not null,
  room_type     text,
  price         numeric,
  updated_at    timestamptz not null default timezone('utc'::text, now()),
  description   text not null default ''::text,
  availability  text not null default ''::text,
  amenities     text default ''::text,
  staff_id      uuid not null,
  photo_url     text,
  constraint room_pkey primary key (id),
  constraint rooms_property_id_fkey foreign key (property_id) references public.property(id),
  constraint room_staff_id_fkey foreign key (staff_id) references public.staff(id)
);

create table if not exists public.viewing_request (
  id                uuid not null default gen_random_uuid(),
  student_id        uuid not null,
  room_id           uuid not null default gen_random_uuid(),
  preferred_date    date not null,
  preferred_time    time without time zone not null,
  status            text default 'pending'::text
                    check (status = any (array['pending'::text, 'approved'::text, 'declined'::text, 'cancelled'::text])),
  created_at        timestamptz not null default timezone('utc'::text, now()),
  cancelled_at      timestamptz not null default timezone('utc'::text, now()),
  staff_id          uuid,
  property_address  text,
  property_title    text,
  room              text,
  user_id           uuid,
  viewing_date      date,
  viewing_time      text,
  constraint viewing_request_pkey primary key (id),
  constraint viewing_appointment_student_id_fkey foreign key (student_id) references public.student(id),
  constraint viewing_appointment_staff_id_fkey foreign key (staff_id) references public.staff(id),
  constraint viewing_request_room_id_fkey foreign key (room_id) references public.room(id)
);

create table if not exists public.enquiries (
  "ReferenceNo"  uuid not null default gen_random_uuid(),
  student_id     uuid not null,
  property_id    uuid,
  message        text not null,
  created_at     timestamptz not null default timezone('utc'::text, now()),
  room_id        uuid,
  subject        text,
  status         text default 'new'::text,
  constraint enquiries_pkey primary key ("ReferenceNo"),
  constraint enquiries_student_id_fkey foreign key (student_id) references public.student(id),
  constraint enquiries_property_id_fkey foreign key (property_id) references public.property(id),
  constraint enquiries_room_id_fkey foreign key (room_id) references public.room(id)
);

create table if not exists public.feedback (
  id           uuid not null default gen_random_uuid(),
  student_id   uuid not null,
  property_id  uuid,
  rating       integer check (rating >= 1 and rating <= 5),
  comments     text,
  created_at   timestamptz not null default timezone('utc'::text, now()),
  constraint feedback_pkey primary key (id),
  constraint feedback_property_id_fkey foreign key (property_id) references public.property(id),
  constraint feedback_student_id_fkey foreign key (student_id) references public.student(id)
);

create table if not exists public.enquiry_messages (
  "enquiry_ReferenceNo"  uuid not null default gen_random_uuid(),
  id                     uuid not null default gen_random_uuid(),
  message                text not null,
  created_at             timestamptz not null default timezone('utc'::text, now()),
  student_id             uuid not null default auth.uid(),
  staff_id               uuid,
  constraint enquiry_messages_pkey primary key (id),
  constraint enquiry_conversations_student_id_fkey foreign key (student_id) references public.student(id),
  constraint enquiry_conversations_staff_id_fkey foreign key (staff_id) references public.staff(id),
  constraint "enquiry_messages_enquiry_ReferenceNo_fkey" foreign key ("enquiry_ReferenceNo") references public.enquiries("ReferenceNo")
);

create table if not exists public.room_photo (
  id          uuid not null default gen_random_uuid(),
  room_id     uuid not null,
  photo_url   text not null,
  created_at  timestamptz not null default now(),
  constraint room_photo_pkey primary key (id),
  constraint room_photo_room_id_fkey foreign key (room_id) references public.room(id)
);
