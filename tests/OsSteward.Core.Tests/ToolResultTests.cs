using System.Globalization;
using OsSteward.Core.Serialization;
using OsSteward.Core.ToolResults;
using Xunit;

namespace OsSteward.Core.Tests;

public class ToolResultTests
{
    [Fact]
    public void Fail_SerializesExplicitErrorKind()
    {
        var result = ToolResult.Fail("os_test", ErrorKind.PermissionDenied, "Access denied reading X.");

        var json = OsJson.Serialize(result);

        Assert.Contains("\"success\": false", json);
        Assert.Contains("\"permissionDenied\"", json);
        Assert.Contains("Access denied reading X.", json);
    }

    [Fact]
    public void Ok_CarriesWarningsAndRedactionState()
    {
        var result = ToolResult
            .Ok("os_test", new { value = 1 }, ["disk:NotAvailable counters unreadable"])
            .AsRedacted();

        var json = OsJson.Serialize(result);

        Assert.Contains("\"redacted\"", json);
        Assert.Contains("disk:NotAvailable", json);
    }

    [Fact]
    public void EnumIdentifiers_StayEnglish_UnderUkrainianCulture()
    {
        var previous = CultureInfo.CurrentCulture;
        try
        {
            CultureInfo.CurrentCulture = new CultureInfo("uk-UA");
            var json = OsJson.Serialize(ToolResult.Fail("os_test", ErrorKind.CollectorFailed, "x"));
            Assert.Contains("\"collectorFailed\"", json);
        }
        finally
        {
            CultureInfo.CurrentCulture = previous;
        }
    }

    [Fact]
    public void RoundTrip_PreservesEnvelope()
    {
        var original = ToolResult.Fail("os_test", ErrorKind.NoData, "nothing");

        var restored = OsJson.Deserialize<ToolResult>(OsJson.Serialize(original));

        Assert.NotNull(restored);
        Assert.False(restored!.Success);
        Assert.Equal(ErrorKind.NoData, restored.Errors[0].Kind);
        Assert.Equal("os_test", restored.Source);
    }
}
