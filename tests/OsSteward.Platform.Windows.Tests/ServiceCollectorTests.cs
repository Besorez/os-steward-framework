using OsSteward.Platform.Windows;
using Xunit;

namespace OsSteward.Platform.Windows.Tests;

public class ServiceCollectorTests
{
    [Fact]
    public void CollectAll_ReturnsServicesWithRequiredFields()
    {
        var (services, _) = new ServiceCollector().CollectAll();

        Assert.NotEmpty(services);
        Assert.All(services, s =>
        {
            Assert.False(string.IsNullOrWhiteSpace(s.Name));
            Assert.False(string.IsNullOrWhiteSpace(s.State));
            Assert.False(string.IsNullOrWhiteSpace(s.StartMode));
        });
    }

    [Fact]
    public void Inspect_UnknownService_ReturnsNull_NotFakeData()
    {
        var (inspection, _) = new ServiceCollector().Inspect("NoSuchService-TESTBOX-01");

        Assert.Null(inspection);
    }

    [Theory]
    [InlineData("\"C:\\Program Files\\TestVendor\\testsvc.exe\" --service", "C:\\Program Files\\TestVendor\\testsvc.exe")]
    [InlineData("\"C:\\Windows\\System32\\spoolsv.exe\"", "C:\\Windows\\System32\\spoolsv.exe")]
    public void TryResolveExecutablePath_HandlesQuotedPaths(string pathName, string expected)
        => Assert.Equal(expected, ServiceCollector.TryResolveExecutablePath(pathName));

    [Fact]
    public void TryResolveExecutablePath_ResolvesRealUnquotedPathWithArguments()
    {
        var svchost = @"C:\Windows\System32\svchost.exe";
        Assert.Equal(svchost, ServiceCollector.TryResolveExecutablePath($"{svchost} -k netsvcs -p"));
    }

    [Fact]
    public void TryResolveExecutablePath_FallsBackToFirstToken_WhenNothingOnDisk()
        => Assert.Equal(
            @"C:\Gone\vendor.exe",
            ServiceCollector.TryResolveExecutablePath(@"C:\Gone\vendor.exe --flag"));
}
