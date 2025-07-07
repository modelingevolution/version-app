using System.Reflection;

var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Get version from assembly
var version = Assembly.GetExecutingAssembly()
    .GetCustomAttribute<AssemblyInformationalVersionAttribute>()
    ?.InformationalVersion ?? "1.0.0";

// API endpoints
app.MapGet("/version", () => Results.Ok(new { version = version }))
    .WithName("GetVersion")
    .WithOpenApi()
    .Produces<VersionResponse>(StatusCodes.Status200OK);

app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }))
    .WithName("HealthCheck")
    .WithOpenApi();

app.MapGet("/", () => Results.Ok(new 
{ 
    application = "VersionApp",
    version = version,
    endpoints = new[]
    {
        "/version - Get current version",
        "/health - Health check",
        "/swagger - API documentation"
    }
}))
    .WithName("GetInfo")
    .WithOpenApi();

app.Logger.LogInformation("VersionApp API starting with version {Version}", version);

app.Run();

// Response models
record VersionResponse(string Version);