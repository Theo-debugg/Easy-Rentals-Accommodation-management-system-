using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace EasyRentalsStaff.Services;

public record SignInResult(string AccessToken, int ExpiresIn, Guid UserId);

public class SupabaseException : Exception
{
    public SupabaseException(string message) : base(message) { }
}

/// Talks to Supabase over plain HTTPS (Auth and the database REST API).
/// Every call after sign-in sends the staff member's own access token, so
/// the database security rules treat the request as coming from that person.
public class SupabaseService
{
    private readonly HttpClient _http;
    private readonly string _url;
    private readonly string _key;
    private readonly string _roomPhotosBucket;

    public static readonly JsonSerializerOptions Json = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
        PropertyNameCaseInsensitive = true
    };

    public SupabaseService(HttpClient http, IConfiguration config)
    {
        _http = http;
        _url = (config["Supabase:Url"] ?? throw new InvalidOperationException("Supabase:Url is missing in appsettings.json")).TrimEnd('/');
        _key = config["Supabase:PublishableKey"] ?? throw new InvalidOperationException("Supabase:PublishableKey is missing in appsettings.json");
        _roomPhotosBucket = config["Supabase:RoomPhotosBucket"] ?? "room-photos";
        if (string.IsNullOrWhiteSpace(_roomPhotosBucket) || _roomPhotosBucket.Any(char.IsWhiteSpace))
            throw new InvalidOperationException("Supabase:RoomPhotosBucket must be a non-empty bucket name without spaces.");
    }

    private HttpRequestMessage Build(HttpMethod method, string path, string? token, HttpContent? content = null)
    {
        var req = new HttpRequestMessage(method, _url + path) { Content = content };
        req.Headers.Add("apikey", _key);
        if (token != null)
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return req;
    }

    private static async Task<string> ReadOrThrow(HttpResponseMessage res)
    {
        var body = await res.Content.ReadAsStringAsync();
        if (res.IsSuccessStatusCode) return body;

        var message = string.IsNullOrWhiteSpace(body) ? res.ReasonPhrase ?? "Request failed" : body;
        try
        {
            using var doc = JsonDocument.Parse(body);
            foreach (var name in new[] { "msg", "message", "error_description", "error" })
            {
                if (doc.RootElement.TryGetProperty(name, out var p) && p.ValueKind == JsonValueKind.String)
                {
                    message = p.GetString()!;
                    break;
                }
            }
        }
        catch (JsonException) { /* body was not JSON; keep raw text */ }

        throw new SupabaseException(message);
    }

    private static StringContent JsonBody(object value) =>
        new(JsonSerializer.Serialize(value, Json), Encoding.UTF8, "application/json");

    // ---- Auth ---------------------------------------------------------

    public async Task<SignInResult> SignInAsync(string email, string password)
    {
        using var res = await _http.SendAsync(Build(
            HttpMethod.Post, "/auth/v1/token?grant_type=password", null,
            JsonBody(new { email, password })));
        var body = await ReadOrThrow(res);

        using var doc = JsonDocument.Parse(body);
        var root = doc.RootElement;
        return new SignInResult(
            root.GetProperty("access_token").GetString()!,
            root.GetProperty("expires_in").GetInt32(),
            Guid.Parse(root.GetProperty("user").GetProperty("id").GetString()!));
    }

    public async Task UpdatePasswordAsync(string token, string newPassword)
    {
        using var res = await _http.SendAsync(Build(
            HttpMethod.Put, "/auth/v1/user", token, JsonBody(new { password = newPassword })));
        await ReadOrThrow(res);
    }

    // ---- Database (REST) ----------------------------------------------

    public async Task<List<T>> SelectAsync<T>(string token, string table, string query)
    {
        using var res = await _http.SendAsync(Build(HttpMethod.Get, $"/rest/v1/{table}?{query}", token));
        var body = await ReadOrThrow(res);
        return JsonSerializer.Deserialize<List<T>>(body, Json) ?? new List<T>();
    }

    public async Task InsertAsync(string token, string table, object row)
    {
        var req = Build(HttpMethod.Post, $"/rest/v1/{table}", token, JsonBody(row));
        req.Headers.Add("Prefer", "return=minimal");
        using var res = await _http.SendAsync(req);
        await ReadOrThrow(res);
    }

    public async Task UpdateAsync(string token, string table, string filter, object changes)
    {
        var req = Build(HttpMethod.Patch, $"/rest/v1/{table}?{filter}", token, JsonBody(changes));
        req.Headers.Add("Prefer", "return=minimal");
        using var res = await _http.SendAsync(req);
        await ReadOrThrow(res);
    }

    public async Task DeleteAsync(string token, string table, string filter)
    {
        using var res = await _http.SendAsync(Build(HttpMethod.Delete, $"/rest/v1/{table}?{filter}", token));
        await ReadOrThrow(res);
    }

    // ---- Storage (room photos) ----------------------------------------

    /// Uploads a file to the public "room-photos" bucket and returns its public URL.
    public async Task<string> UploadRoomPhotoAsync(string token, string path, byte[] bytes, string contentType)
    {
        var content = new ByteArrayContent(bytes);
        content.Headers.ContentType = new MediaTypeHeaderValue(contentType);

        using var res = await _http.SendAsync(Build(
            HttpMethod.Post, $"/storage/v1/object/{_roomPhotosBucket}/{path}", token, content));
        await ReadOrThrow(res);

        return $"{_url}/storage/v1/object/public/{_roomPhotosBucket}/{path}";
    }

    /// Deletes a file from the "room-photos" bucket (path = the path inside the bucket).
    public async Task DeleteRoomPhotoAsync(string token, string path)
    {
        using var res = await _http.SendAsync(Build(
            HttpMethod.Delete, $"/storage/v1/object/{_roomPhotosBucket}/{path}", token));
        await ReadOrThrow(res);
    }

    /// Turns ".../storage/v1/object/public/room-photos/<path>" back into "<path>".
    public static string? PathFromPublicUrl(string url)
    {
        const string marker = "/object/public/";
        var i = url.IndexOf(marker, StringComparison.Ordinal);
        if (i < 0) return null;
        var objectPath = url[(i + marker.Length)..];
        var slash = objectPath.IndexOf('/');
        return slash < 0 ? null : Uri.UnescapeDataString(objectPath[(slash + 1)..]);
    }
}

/// Small helpers for reading the signed-in staff member from the session.
public static class StaffSession
{
    public static string Token(this ISession s) => s.GetString("token") ?? "";
    public static Guid StaffId(this ISession s) => Guid.Parse(s.GetString("staff_id")!);
    public static string StaffName(this ISession s) => s.GetString("staff_name") ?? "Staff";
}
