using OsSteward.Privacy;
using Xunit;

namespace OsSteward.Privacy.Tests;

public class RedactorTests
{
    // Deterministic synthetic identity — tests never depend on the real machine.
    private static readonly Redactor Redactor = new(
        userName: "RealPerson",
        userProfilePath: @"C:\Users\RealPerson",
        machineName: "TESTMACHINE-99");

    [Theory]
    [InlineData(@"C:\Users\RealPerson\Documents\log.txt", @"%USERPROFILE%\Documents\log.txt")]
    [InlineData(@"c:\users\realperson\app.exe", @"%USERPROFILE%\app.exe")]
    public void RedactsCurrentUserProfilePath(string input, string expected)
        => Assert.Equal(expected, Redactor.Redact(input));

    [Fact]
    public void RedactsJsonEscapedProfilePath()
    {
        var json = "{\"path\": \"C:\\\\Users\\\\RealPerson\\\\x.dll\"}";

        var redacted = Redactor.Redact(json);

        Assert.DoesNotContain("RealPerson", redacted);
        Assert.Contains("%USERPROFILE%", redacted);
    }

    [Fact]
    public void RedactsOtherUserProfileSegment()
    {
        var redacted = Redactor.Redact(@"C:\Users\SomebodyElse\secret.txt");

        Assert.DoesNotContain("SomebodyElse", redacted);
        Assert.Contains(@"C:\Users\<USER>", redacted);
    }

    [Theory]
    [InlineData(@"C:\Users\Public\shared.txt")]
    [InlineData(@"C:\Users\TestUser\fixture.json")]
    public void LeavesWellKnownProfilesUntouched(string input)
        => Assert.Equal(input, Redactor.Redact(input));

    [Fact]
    public void RedactsMachineNameToken()
        => Assert.Equal(
            "host <LOCAL_MACHINE> responded",
            Redactor.Redact("host TESTMACHINE-99 responded"));

    [Fact]
    public void RedactsStandaloneUsernameToken()
        => Assert.Equal(
            "owner: <USER>",
            Redactor.Redact("owner: RealPerson"));

    [Fact]
    public void RedactionIsIdempotent()
    {
        var once = Redactor.Redact(@"C:\Users\RealPerson\a on TESTMACHINE-99");

        Assert.Equal(once, Redactor.Redact(once));
    }
}
