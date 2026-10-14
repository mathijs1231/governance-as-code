@{
    Severity     = @('Error', 'Warning')
    ExcludeRules = @(
        # Pipeline scripts intentionally write progress to the host (ADO log commands use Write-Host).
        'PSAvoidUsingWriteHost',
        # Reconcile functions return collections named after the resource (e.g. Get-GaCDlpPolicies style helpers).
        'PSUseSingularNouns',
        # Configuration objects are ordered dictionaries passed through many functions.
        'PSReviewUnusedParameter'
    )
    Rules        = @{
        PSUseCompatibleSyntax = @{ Enable = $true; TargetVersions = @('7.2') }
        PSPlaceOpenBrace      = @{ Enable = $true; OnSameLine = $true }
        PSUseConsistentIndentation = @{ Enable = $true; IndentationSize = 4; Kind = 'space' }
    }
}
