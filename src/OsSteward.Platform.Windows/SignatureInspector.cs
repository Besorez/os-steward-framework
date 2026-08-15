using System.Runtime.InteropServices;
using System.Security.Cryptography.X509Certificates;
using OsSteward.Core.Telemetry;

namespace OsSteward.Platform.Windows;

/// <summary>
/// Authenticode signature inspection via WinVerifyTrust. Read-only evidence
/// source: reports Signed / Unsigned / Invalid / Unknown plus the signer
/// subject where available. Makes no judgement about the binary itself.
/// </summary>
public static class SignatureInspector
{
    private const uint TrustENoSignature = 0x800B0100;
    private const uint TrustEExplicitDistrust = 0x800B0111;
    private const uint TrustESubjectNotTrusted = 0x800B0004;
    private const uint CertEExpired = 0x800B0101;
    private const uint CertEUntrustedRoot = 0x800B0109;
    private const uint TrustEBadDigest = 0x80096010;

    public static SignatureInfo Inspect(string filePath)
    {
        uint verdict;
        try
        {
            verdict = VerifyTrust(filePath);
        }
        catch (Exception ex) when (ex is DllNotFoundException or EntryPointNotFoundException)
        {
            return new SignatureInfo(SignatureStatus.Unknown, null);
        }

        var status = verdict switch
        {
            0 => SignatureStatus.Signed,
            TrustENoSignature => SignatureStatus.Unsigned,
            TrustEExplicitDistrust or TrustESubjectNotTrusted or CertEExpired
                or CertEUntrustedRoot or TrustEBadDigest => SignatureStatus.Invalid,
            _ => SignatureStatus.Unknown,
        };

        string? signer = null;
        if (status is SignatureStatus.Signed or SignatureStatus.Invalid)
        {
            signer = TryGetSignerSubject(filePath);
        }

        return new SignatureInfo(status, signer);
    }

    private static string? TryGetSignerSubject(string filePath)
    {
        try
        {
            // SYSLIB0057's suggested replacement (X509CertificateLoader) loads
            // certificate blobs; it cannot extract the signer from a signed PE,
            // so CreateFromSignedFile remains the only managed option here.
#pragma warning disable SYSLIB0057
            using var certificate = new X509Certificate2(X509Certificate.CreateFromSignedFile(filePath));
#pragma warning restore SYSLIB0057
            return certificate.Subject;
        }
        catch (Exception ex) when (ex is System.Security.Cryptography.CryptographicException or IOException)
        {
            return null;
        }
    }

    private static uint VerifyTrust(string filePath)
    {
        var actionId = new Guid("00AAC56B-CD44-11d0-8CC2-00C04FC295EE");

        var fileInfo = new WintrustFileInfo
        {
            StructSize = (uint)Marshal.SizeOf<WintrustFileInfo>(),
            FilePath = Marshal.StringToCoTaskMemUni(filePath),
        };
        var fileInfoPtr = Marshal.AllocCoTaskMem(Marshal.SizeOf<WintrustFileInfo>());
        Marshal.StructureToPtr(fileInfo, fileInfoPtr, false);

        var trustData = new WintrustData
        {
            StructSize = (uint)Marshal.SizeOf<WintrustData>(),
            UiChoice = 2,           // WTD_UI_NONE
            RevocationChecks = 0,   // WTD_REVOKE_NONE
            UnionChoice = 1,        // WTD_CHOICE_FILE
            FileInfo = fileInfoPtr,
            StateAction = 1,        // WTD_STATEACTION_VERIFY
        };

        try
        {
            var result = (uint)WinVerifyTrust(IntPtr.Zero, ref actionId, ref trustData);

            trustData.StateAction = 2; // WTD_STATEACTION_CLOSE
            WinVerifyTrust(IntPtr.Zero, ref actionId, ref trustData);

            return result;
        }
        finally
        {
            Marshal.FreeCoTaskMem(fileInfo.FilePath);
            Marshal.FreeCoTaskMem(fileInfoPtr);
        }
    }

    [DllImport("wintrust.dll", ExactSpelling = true)]
    private static extern int WinVerifyTrust(IntPtr hwnd, ref Guid actionId, ref WintrustData data);

    [StructLayout(LayoutKind.Sequential)]
    private struct WintrustFileInfo
    {
        public uint StructSize;
        public IntPtr FilePath;
        public IntPtr FileHandle;
        public IntPtr KnownSubject;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct WintrustData
    {
        public uint StructSize;
        public IntPtr PolicyCallbackData;
        public IntPtr SipClientData;
        public uint UiChoice;
        public uint RevocationChecks;
        public uint UnionChoice;
        public IntPtr FileInfo;
        public uint StateAction;
        public IntPtr StateData;
        public IntPtr UrlReference;
        public uint ProviderFlags;
        public uint UiContext;
        public IntPtr SignatureSettings;
    }
}
