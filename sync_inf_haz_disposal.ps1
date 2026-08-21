<#
.SYNOPSIS
    Sync and Auto-Generate Infectious & Hazardous Waste Records from infectious_disposal to infectious_hazardous_waste.
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
System.Text.ASCIIEncoding = [System.Text.Encoding]::UTF8

 = 'https://maazhpfkpbmnghjtjhhi.supabase.co'
 = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1hYXpocGZrcGJtbmdoanRqaGhpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY2NzkxNDcsImV4cCI6MjEwMjI1NTE0N30.tuOzwqvN9DGWODwoGKivLjLcevD0cmKF6fsaOrbHIj0'

 = @{
    'apikey'        = 
    'Authorization' = 'Bearer ' + 
    'Content-Type'  = 'application/json'
    'Prefer'        = 'resolution=merge-duplicates,return=representation'
}

 = @('มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม')

Write-Host '==========================================================================' -ForegroundColor Cyan
Write-Host '⚡ ระบบซิงค์ข้อมูลมูลฝอยติดเชื้อ+อันตราย รพ.หลัก จากรอบส่งกำจัด (Disposal Sync)' -ForegroundColor Yellow
Write-Host '==========================================================================' -ForegroundColor Cyan

# 1. Fetch all disposal details
Write-Host '
[1/4] กำลังดึงข้อมูลจากตาราง infectious_disposal...' -ForegroundColor Gray
 = @()
 = 0
 = 1000
 = True

while () {
     =  + '/rest/v1/infectious_disposal?select=*&offset=' +  + '&limit=' + 
     = Invoke-RestMethod -Uri  -Headers  -Method Get
    if ( -and .Count -gt 0) {
         += 
        if (.Count -lt ) {  = False }
        else {  +=  }
    } else {
         = False
    }
}
Write-Host ('  -> พบรายการชั่งทั้งหมด ' + .Count + ' แถว') -ForegroundColor Green

# 2. Fetch existing infectious_hazardous_waste
Write-Host '
[2/4] กำลังตรวจสอบตาราง infectious_hazardous_waste...' -ForegroundColor Gray
 = Invoke-RestMethod -Uri ( + '/rest/v1/infectious_hazardous_waste?select=*') -Headers  -Method Get
 = @{}
foreach ( in ) {
    if (.waste_date) { [.waste_date] =  }
}
Write-Host ('  -> มีข้อมูลบันทึกอยู่แล้ว ' + .Count + ' วัน') -ForegroundColor Green

# Calculate baseline chemical hazard average (~0.20 kg per round)
 =  | Where-Object { [double].chemical_hazard -gt 0 } | ForEach-Object { [double].chemical_hazard }
 = 0.20
if (.Count -gt 0) {
     = ( | Measure-Object -Average).Average
     = [Math]::Max(0.10, [Math]::Min(0.50, [Math]::Round(, 2)))
}
Write-Host ('  -> ค่าเฉลี่ยอันตรายเคมีต่อรอบที่นำมาอิง: ' +  + ' กก./รอบ') -ForegroundColor DarkCyan

# 3. Group disposal details by created_date
Write-Host '
[3/4] กำลังประมวลผลจำแนกประเภทขยะรายวัน...' -ForegroundColor Gray
 =  | Group-Object created_date
 = @()

foreach ( in ) {
     = .Name
    if ([string]::IsNullOrWhiteSpace()) { continue }
    
     = .Group
     = 0.0
     = 0.0
     = 0.0
     = 0.0
     = 0.0

    foreach ( in ) {
         = [string].bin_name
         = [double].net_weight

        if ( -match 'มีคม|sharp') {
             += 
        } elseif ( -match 'อบจ|obg|household|ครัวเรือน') {
             += 
        } elseif ( -match 'รังสี|radio') {
             += 
        } elseif ( -match 'อันตราย|hazard') {
             += 
        } elseif ( -match 'ติดเชื้อ|infect') {
             += 
        } else {
             += 
        }
    }

    # Separate Chemical vs Medical
     = 0.0
     = 0.0
    if ( -gt 0) {
         = [Math]::Min(, )
         = [Math]::Max(0, [Math]::Round( - , 2))
    }

     = [DateTime]::Parse()
     = .Year + 543
     = [.Month - 1]

     = 'INFHAZ-' + .ToString('yyyyMMdd')
    if (.ContainsKey() -and [].id) {
         = [].id
    }

     += @{
        id                   = 
        year                 = 
        month                = 
        waste_date           = 
        sharp_infectious     = [Math]::Round(, 2)
        non_sharp_infectious = [Math]::Round(, 2)
        chemical_hazard      = [Math]::Round(, 2)
        medical_hazard       = [Math]::Round(, 2)
        household_obg_hazard = [Math]::Round(, 2)
        radioactive_hazard   = [Math]::Round(, 2)
        total_infectious     = [Math]::Round( + , 2)
        total_hazardous      = [Math]::Round( +  +  + , 2)
        recorded_by          = 'Sangtawan'
    }
}

Write-Host ('  -> ประมวลผลได้ทั้งหมด ' + .Count + ' วันรอบส่งกำจัด') -ForegroundColor Green

# 4. Upsert to Supabase
Write-Host '
[4/4] กำลังบันทึกข้อมูลลง Supabase (infectious_hazardous_waste)...' -ForegroundColor Gray
 = 50
 = [Math]::Ceiling(.Count / )
 = 0

for ( = 0;  -lt ; ++) {
     =  * 
     = [Math]::Min(, .Count - )
     = [..( +  - 1)]

     =  | ConvertTo-Json -Depth 5
     = Invoke-RestMethod -Uri ( + '/rest/v1/infectious_hazardous_waste') -Method Post -Headers  -Body 
     += 
    Write-Host ('  -> บันทึกชุดที่ ' + ( + 1) + '/' +  + ' (' +  + ' รายการ)...') -ForegroundColor DarkGreen
}

Write-Host '
==========================================================================' -ForegroundColor Cyan
Write-Host ('🎉 สำเร็จ! ซิงค์และบันทึกข้อมูลครบถ้วน ' +  + ' วัน (รอบส่งกำจัด) เข้าสู่ Supabase เรียบร้อยแล้ว') -ForegroundColor Yellow
Write-Host '==========================================================================' -ForegroundColor Cyan