-- ════════════════════════════════════════════════
-- Supabase SQL Editor에 복붙 후 실행하세요
-- ════════════════════════════════════════════════

create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  nickname text not null,
  created_at timestamp with time zone default now()
);

create table public.playgrounds (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  address text not null,
  lat double precision not null,
  lng double precision not null,
  description text,
  features text[],
  image_urls text[],
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamp with time zone default now()
);

create table public.comments (
  id uuid default gen_random_uuid() primary key,
  playground_id uuid references public.playgrounds(id) on delete cascade not null,
  author_id uuid references public.profiles(id) on delete cascade not null,
  content text not null,
  created_at timestamp with time zone default now()
);

-- RLS 활성화
alter table public.profiles    enable row level security;
alter table public.playgrounds enable row level security;
alter table public.comments    enable row level security;

-- Profiles 정책
create policy "profiles_read"   on public.profiles for select using (true);
create policy "profiles_insert" on public.profiles for insert with check (auth.uid() = id);
create policy "profiles_update" on public.profiles for update using (auth.uid() = id);

-- Playgrounds 정책
create policy "playgrounds_read"   on public.playgrounds for select using (true);
create policy "playgrounds_insert" on public.playgrounds for insert with check (auth.uid() is not null);
create policy "playgrounds_update" on public.playgrounds for update using (auth.uid() = created_by);

-- Comments 정책
create policy "comments_read"   on public.comments for select using (true);
create policy "comments_insert" on public.comments for insert with check (auth.uid() is not null);
create policy "comments_delete" on public.comments for delete using (auth.uid() = author_id);

-- Storage 버킷
insert into storage.buckets (id, name, public) values ('playground-images', 'playground-images', true);
create policy "images_read"   on storage.objects for select using (bucket_id = 'playground-images');
create policy "images_upload" on storage.objects for insert with check (bucket_id = 'playground-images' and auth.uid() is not null);
