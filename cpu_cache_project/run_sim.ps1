# =============================================================================
# run_sim.ps1 — Build & Simulate script cho cpu_cache_project (Icarus Verilog)
# Cách dùng:
#   .\run_sim.ps1               <- cpu_cache_tb (mặc định)
#   .\run_sim.ps1 -TB alu_tb    <- testbench cụ thể
#   .\run_sim.ps1 -All          <- chạy tất cả testbenches
# =============================================================================
param (
    [string]$TB  = "cpu_cache_tb",
    [switch]$All
)

$PROJECT_ROOT = $PSScriptRoot
$BUILD_DIR    = "$PROJECT_ROOT\build"
$MEM_DIR      = "$PROJECT_ROOT\mem"

if (-not (Test-Path $BUILD_DIR)) { New-Item -ItemType Directory $BUILD_DIR | Out-Null }
if (-not (Test-Path $MEM_DIR))   { New-Item -ItemType Directory $MEM_DIR   | Out-Null }

# =============================================================================
# Danh sách tất cả RTL source (dùng chung cho TB đầy đủ)
# =============================================================================
$RTL_COMMON = @(
    "$PROJECT_ROOT\rtl\core\alu.v",
    "$PROJECT_ROOT\rtl\core\register_file.v",
    "$PROJECT_ROOT\rtl\core\immediate_generator.v",
    "$PROJECT_ROOT\rtl\core\instruction_decoder.v",
    "$PROJECT_ROOT\rtl\core\control_unit.v",
    "$PROJECT_ROOT\rtl\core\pc_unit.v",
    "$PROJECT_ROOT\rtl\core\forwarding_unit.v",
    "$PROJECT_ROOT\rtl\core\hazard_detection_unit.v",
    "$PROJECT_ROOT\rtl\core\pipeline_regs.v",
    "$PROJECT_ROOT\rtl\core\cpu_core.v",
    "$PROJECT_ROOT\rtl\memory\direct_mapped_cache.v",
    "$PROJECT_ROOT\rtl\memory\cache_controller.v",
    "$PROJECT_ROOT\rtl\memory\cache_subsystem.v",
    "$PROJECT_ROOT\rtl\memory\main_memory.v",
    "$PROJECT_ROOT\rtl\memory\memory_arbiter.v",
    "$PROJECT_ROOT\rtl\top\cpu_cache_top.v"
)

# =============================================================================
# Ánh xạ TB → chỉ compile những module cần thiết
# =============================================================================
$TB_SOURCE_MAP = @{
    "alu_tb"                 = @("$PROJECT_ROOT\rtl\core\alu.v")
    "register_file_tb"       = @("$PROJECT_ROOT\rtl\core\register_file.v")
    "immediate_generator_tb" = @("$PROJECT_ROOT\rtl\core\immediate_generator.v")
    "control_unit_tb"        = @("$PROJECT_ROOT\rtl\core\control_unit.v")
    "main_memory_tb"         = @("$PROJECT_ROOT\rtl\memory\main_memory.v")
    "memory_arbiter_tb"      = @("$PROJECT_ROOT\rtl\memory\memory_arbiter.v")
    "cache_tb"               = @(
                                   "$PROJECT_ROOT\rtl\memory\direct_mapped_cache.v",
                                   "$PROJECT_ROOT\rtl\memory\cache_controller.v",
                                   "$PROJECT_ROOT\rtl\memory\cache_subsystem.v"
                               )
    "cpu_cache_tb"           = $RTL_COMMON
    "cpu_core_tb"            = $RTL_COMMON
    "cpu_cache_tb_debug"     = $RTL_COMMON
}

# Thứ tự chạy khi -All (từ đơn giản đến phức tạp)
$ALL_TBS = @(
    "alu_tb",
    "register_file_tb",
    "immediate_generator_tb",
    "control_unit_tb",
    "main_memory_tb",
    "memory_arbiter_tb",
    "cache_tb",
    "cpu_cache_tb",
    "cpu_core_tb"
)

# =============================================================================
# Hàm compile + simulate 1 testbench
# =============================================================================
function Run-TB {
    param([string]$TestName)

    $rtl_sources = $TB_SOURCE_MAP[$TestName]
    if (-not $rtl_sources) {
        Write-Host "[$TestName] WARNING: khong co source map, dung toan bo RTL" -ForegroundColor Yellow
        $rtl_sources = $RTL_COMMON
    }

    $OUTPUT_VVP = "$BUILD_DIR\${TestName}.vvp"
    $TB_FILE    = "$PROJECT_ROOT\tb\${TestName}.v"

    Write-Host ""
    Write-Host "[$TestName] Compiling..." -ForegroundColor Cyan

    $iverilog_args = @(
        "-g2012", "-Wall",
        "-I", "$PROJECT_ROOT\include",
        "-I", "$PROJECT_ROOT\rtl\memory",
        "-o", $OUTPUT_VVP
    ) + $rtl_sources + @($TB_FILE)

    & iverilog @iverilog_args
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[$TestName] FAIL (compile error)" -ForegroundColor Red
        return $false
    }

    Write-Host "[$TestName] Running..." -ForegroundColor Cyan
    & vvp $OUTPUT_VVP
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[$TestName] FAIL (simulation)" -ForegroundColor Red
        return $false
    }

    Write-Host "[$TestName] PASS" -ForegroundColor Green
    return $true
}

# =============================================================================
# MAIN
# =============================================================================
if ($All) {
    $pass = 0; $fail = 0
    foreach ($t in $ALL_TBS) {
        $ok = Run-TB $t
        if ($ok) { $pass++ } else { $fail++ }
    }
    Write-Host ""
    Write-Host "========================================" -ForegroundColor White
    if ($fail -eq 0) {
        Write-Host "  ALL TESTS PASS ($pass/$($pass+$fail))" -ForegroundColor Green
    } else {
        Write-Host "  RESULT: PASS=$pass  FAIL=$fail" -ForegroundColor Red
    }
    Write-Host "========================================" -ForegroundColor White
    if ($fail -gt 0) { exit 1 }
} else {
    $ok = Run-TB $TB
    if (-not $ok) { exit 1 }
}
