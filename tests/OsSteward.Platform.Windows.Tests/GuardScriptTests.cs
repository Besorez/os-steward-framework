using System.Diagnostics;
using Xunit;

namespace OsSteward.Platform.Windows.Tests;

/// <summary>
/// Safety and privacy guards are first-class tested components: these tests
/// run each guard script's embedded deterministic self-test suite.
/// </summary>
public class GuardScriptTests
{
    private static string RepoRoot
    {
        get
        {
            var dir = new DirectoryInfo(AppContext.BaseDirectory);
            while (dir is not null
                && !File.Exists(Path.Combine(dir.FullName, "OsSteward.slnx"))
                && !File.Exists(Path.Combine(dir.FullName, "OsSteward.sln")))
            {
                dir = dir.Parent;
            }

            Assert.NotNull(dir);
            return dir!.FullName;
        }
    }

    private static (int ExitCode, string Output) RunScript(string relativePath)
    {
        var psi = new ProcessStartInfo
        {
            FileName = "powershell.exe",
            Arguments = $"-NoProfile -ExecutionPolicy Bypass -File \"{Path.Combine(RepoRoot, relativePath)}\" -SelfTest",
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
        };
        using var process = Process.Start(psi)!;
        var output = process.StandardOutput.ReadToEnd() + process.StandardError.ReadToEnd();
        process.WaitForExit(60_000);
        return (process.ExitCode, output);
    }

    [Fact]
    public void SafetyGuard_SelfTestsPass()
    {
        var (exitCode, output) = RunScript(@"hooks\safety-guard.ps1");

        Assert.True(exitCode == 0, $"safety-guard self-test failed:\n{output}");
    }

    [Fact]
    public void PrivacyGuard_SelfTestsPass()
    {
        var (exitCode, output) = RunScript(@"scripts\privacy-guard.ps1");

        Assert.True(exitCode == 0, $"privacy-guard self-test failed:\n{output}");
    }
}
