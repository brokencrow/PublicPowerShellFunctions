#Function Version 1.1
Function Write-ScriptMethodVerboseWriter {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Need to use Write Host')]
    param(
        [Parameter(Mandatory = $true)][string]$WriteString
    )
    if ($null -ne $this.LoggerObject) {
        $this.LoggerObject.WriteVerbose($WriteString)
    } elseif ($null -eq $this.VerboseFunctionCaller -and
        $this.WriteVerboseData) {
        Write-Host $WriteString -ForegroundColor Cyan
    } elseif ($this.WriteVerboseData) {
        $this.VerboseFunctionCaller($WriteString)
    }
}