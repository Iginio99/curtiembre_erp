using ErpCurtiembre.Shared.Composition;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddCors(options =>
{
    options.AddPolicy("FrontendDevelopment", policy =>
    {
        policy
            .SetIsOriginAllowed(origin =>
            {
                if (!Uri.TryCreate(origin, UriKind.Absolute, out var uri))
                {
                    return false;
                }

                return uri.Host is "localhost" or "127.0.0.1";
            })
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new()
    {
        Title = "ERP Curtiembre API",
        Version = "v1",
        Description = "Documentacion OpenAPI de los endpoints actuales del backend ERP Curtiembre."
    });
});
builder.Services.AddProblemDetails();
builder.Services.AddErpModules(builder.Configuration);

var app = builder.Build();

app.UseExceptionHandler();
if (app.Environment.IsDevelopment())
{
    app.UseCors("FrontendDevelopment");
}
app.UseSwagger();
app.UseSwaggerUI(options =>
{
    options.SwaggerEndpoint("/swagger/v1/swagger.json", "ERP Curtiembre API v1");
    options.RoutePrefix = "swagger";
    options.DocumentTitle = "ERP Curtiembre API";
});

app.MapGet("/", () => Results.Ok(new
{
    application = "ErpCurtiembre.Api",
    architecture = "Monolito modular con arquitectura hexagonal por modulo",
    modules = ErpModuleCatalog.ModuleNames
}));

app.MapErpModules();

app.Run();

public partial class Program;
