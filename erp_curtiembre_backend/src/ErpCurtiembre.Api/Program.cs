using ErpCurtiembre.Shared.Composition;
using ErpCurtiembre.Modules.Configuracion.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Evita que Windows Event Log convierta un error de aplicacion en otro fallo
// cuando el proceso se ejecuta sin permisos para escribir en el registro.
builder.Logging.ClearProviders();
builder.Logging.AddSimpleConsole();

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

await using (var scope = app.Services.CreateAsyncScope())
{
    var db = scope.ServiceProvider.GetRequiredService<ConfiguracionDbContext>();
    await db.Database.ExecuteSqlRawAsync("""
        IF OBJECT_ID(N'configuracion.producto', N'U') IS NULL
        BEGIN
            CREATE TABLE configuracion.producto (
                id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
                codigo NVARCHAR(50) NOT NULL CONSTRAINT UQ_producto_codigo UNIQUE,
                tipo NVARCHAR(120) NOT NULL,
                nombre NVARCHAR(150) NOT NULL,
                color NVARCHAR(80) NULL,
                activo BIT NOT NULL CONSTRAINT DF_producto_activo DEFAULT 1,
                creado_en DATETIME2 NOT NULL CONSTRAINT DF_producto_creado_en DEFAULT SYSDATETIME()
            );
        END;
        IF COL_LENGTH(N'configuracion.formula', N'producto_id') IS NULL
            ALTER TABLE configuracion.formula ADD producto_id BIGINT NULL;
        IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_formula_producto' AND parent_object_id = OBJECT_ID(N'configuracion.formula'))
            ALTER TABLE configuracion.formula ADD CONSTRAINT FK_formula_producto FOREIGN KEY (producto_id) REFERENCES configuracion.producto(id);
        """);
}

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
