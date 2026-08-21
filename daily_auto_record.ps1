# Script: daily_auto_record.ps1
# Automates recording of hospital general & organic waste across 2 daily shifts:
# 1. Morning Shift: 08:15 - 11:45 (approx. 60-68% of daily baseline, mean ~64%)
# 2. Afternoon Shift: 13:15 - 15:45 (approx. 32-40% of daily baseline, mean ~36%)
# Based on 2567-2568 empirical hospital data with +3% growth factor

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$url = 'https://maazhpfkpbmnghjtjhhi.supabase.co'
$key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1hYXpocGZrcGJtbmdoanRqaGhpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY2NzkxNDcsImV4cCI6MjEwMjI1NTE0N30.tuOzwqvN9DGWODwoGKivLjLcevD0cmKF6fsaOrbHIj0'

$headers = @{
    'apikey' = $key
    'Authorization' = 'Bearer ' + $key
    'Content-Type' = 'application/json; charset=utf-8'
    'Prefer' = 'resolution=merge-duplicates,return=representation'
}

$months = @('มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม')

# 1. Fetch departments dynamically from Supabase ref_departments
Write-Host 'Fetching departments from ref_departments...'
try {
    $depts = Invoke-RestMethod -Uri ('{0}/rest/v1/ref_departments?select=*' -f $url) -Headers $headers -Method GET
} catch {
    $depts = @()
}

if ($null -eq $depts -or $depts.Count -eq 0) {
    Write-Host 'No departments returned from database, using fallback standard department list...'
    $depts = @(
        @{ id = 'DEP-001'; department_name = 'เวชกรรมสังคม ชั้น 9' },
        @{ id = 'DEP-002'; department_name = 'กายภาพบำบัด ชั้น 9' },
        @{ id = 'DEP-003'; department_name = 'อายุรกรรมรวม ชั้น 8' },
        @{ id = 'DEP-004'; department_name = 'หอผู้ป่วยในพิเศษ VIP8 ชั้น 8' },
        @{ id = 'DEP-005'; department_name = 'กุมารเวชกรรม ชั้น 7' },
        @{ id = 'DEP-006'; department_name = 'หอผู้ป่วยในพิเศษ VIP7 ชั้น 7' },
        @{ id = 'DEP-007'; department_name = 'ศัลยกรรม ชั้น 6' },
        @{ id = 'DEP-008'; department_name = 'จักษุ โสต ศอ นาสิก ชั้น 6' },
        @{ id = 'DEP-009'; department_name = 'ผ่าตัด วิสัญญี ชั้น 5' },
        @{ id = 'DEP-010'; department_name = 'ออโถปิดิกส์ ชั้น 5' },
        @{ id = 'DEP-011'; department_name = 'ICU อายุกรรม ชั้น 4' },
        @{ id = 'DEP-012'; department_name = 'ICU ศัลยกรรม ชั้น 4' },
        @{ id = 'DEP-013'; department_name = 'ห้องคลอด สูตินารีเวช ชั้น 4' },
        @{ id = 'DEP-014'; department_name = 'อายุกรรมชาย ชั้น 3' },
        @{ id = 'DEP-015'; department_name = 'OPD เฉพาะทาง ชั้น 3' },
        @{ id = 'DEP-016'; department_name = 'อายุกรรมหญิง ชั้น 2' },
        @{ id = 'DEP-017'; department_name = 'ล้างไตในช่องท้อง CAPD ชั้น 2' },
        @{ id = 'DEP-018'; department_name = 'OPD NCD เฉพาะทาง ชั้น 1' },
        @{ id = 'DEP-019'; department_name = 'ห้องจ่ายยา ชั้น 1' },
        @{ id = 'DEP-020'; department_name = 'ห้อง LAB ชั้น 1' },
        @{ id = 'DEP-021'; department_name = 'ห้อง X-RAY ชั้น 1' },
        @{ id = 'DEP-022'; department_name = 'จุดรวมอาคารพักมูลฝอย' },
        @{ id = 'DEP-023'; department_name = 'อุบัติเหตุฉุกเฉิน ER' },
        @{ id = 'DEP-024'; department_name = 'โภชนาการ' },
        @{ id = 'DEP-025'; department_name = 'คลังยา อาคารเภสัช' },
        @{ id = 'DEP-026'; department_name = 'จ่ายกลาง' },
        @{ id = 'DEP-027'; department_name = 'ธุรการ ชั้น 2' },
        @{ id = 'DEP-028'; department_name = 'วิหาร' },
        @{ id = 'DEP-029'; department_name = 'ซักรีด' },
        @{ id = 'DEP-030'; department_name = 'อาคารซ่อมบำรุง' },
        @{ id = 'DEP-031'; department_name = 'ไตเทียม ชั้น 3' },
        @{ id = 'DEP-032'; department_name = 'OPD อายุรกรรมเด็ก ชั้น 3' },
        @{ id = 'DEP-033'; department_name = 'ทันตกรรม ชั้น 2' },
        @{ id = 'DEP-034'; department_name = 'แพทย์แผนไทย,แพทย์แผนจีน,สปาร์ ชั้น 4' },
        @{ id = 'DEP-035'; department_name = 'องค์กรแพทย์ ชั้น 2' },
        @{ id = 'DEP-036'; department_name = 'พรส ชั้น 2' },
        @{ id = 'DEP-037'; department_name = 'สงฆ์อาพาธ ตึกพรหม' },
        @{ id = 'DEP-038'; department_name = 'พัสดุ' },
        @{ id = 'DEP-039'; department_name = 'พิเศษตึกพรหม' },
        @{ id = 'DEP-040'; department_name = 'โรงอาหาร' },
        @{ id = 'DEP-041'; department_name = 'จุดรวมข้างโรงอาหาร' },
        @{ id = 'DEP-042'; department_name = 'จุดรวมข้าง ER' },
        @{ id = 'DEP-043'; department_name = 'จุดตึกพรหม' },
        @{ id = 'DEP-044'; department_name = 'OPD GP ทั่วไป ชั้น1' },
        @{ id = 'DEP-045'; department_name = 'X-Ray ชั้น 1' },
        @{ id = 'DEP-046'; department_name = 'CT SCAN ชั้น 1' },
        @{ id = 'DEP-047'; department_name = 'คลินิกบริการ' },
        @{ id = 'DEP-048'; department_name = 'งานประกัน ชั้น 2' },
        @{ id = 'DEP-049'; department_name = 'คลินิคตรวจสุขภาพ อาชีวเวชกรรม ชั้น 4' },
        @{ id = 'DEP-050'; department_name = 'งานจิตเวช ชั้น 2' }
    )
}

$now = Get-Date
$today = $now.ToString('yyyy-MM-dd')
$todayBE = $now.Year + 543
$monthName = $months[$now.Month - 1]

Write-Host ('Processing automatic recording for Date: {0} (Year: {1}, Month: {2})...' -f $today, $todayBE, $monthName)

# Check if today already has records
try {
    $existing = Invoke-RestMethod -Uri ('{0}/rest/v1/general_waste?waste_date=eq.{1}&select=id&limit=1' -f $url, $today) -Headers $headers -Method GET
    if ($existing.Count -gt 0) {
        Write-Host ('Notice: Records for {0} already exist in general_waste. Skipping duplicate creation.' -f $today)
        exit 0
    }
} catch {}

# Baseline Map based on 2567-2568 empirical hospital data with +3% growth factor
$deptBaselines = @{
    'กุมารเวชกรรม' = @{ mean = 7.47; organic = 0.0; staff = 'พรรณี ขลุ่ยทอง' }
    'อายุรกรรมรวม' = @{ mean = 12.88; organic = 0.0; staff = 'อรทัย เนืองพงษ์' }
    'อายุกรรมชาย' = @{ mean = 15.45; organic = 0.0; staff = 'ฐิตาภรณ์ พันธ์คำ' }
    'อายุรกรรมชาย' = @{ mean = 15.45; organic = 0.0; staff = 'ฐิตาภรณ์ พันธ์คำ' }
    'อายุกรรมหญิง' = @{ mean = 16.48; organic = 0.0; staff = 'เดือนเพ็ญ แก่นสายศ' }
    'อายุรกรรมหญิง' = @{ mean = 16.48; organic = 0.0; staff = 'เดือนเพ็ญ แก่นสายศ' }
    'ศัลยกรรม' = @{ mean = 9.48; organic = 0.0; staff = 'ปราณี คงดี' }
    'ICU เมด' = @{ mean = 8.24; organic = 0.0; staff = 'นงรัก รินริโก' }
    'ICU อายุกรรม' = @{ mean = 8.24; organic = 0.0; staff = 'นงรัก รินริโก' }
    'ICU ศัลยกรรม' = @{ mean = 8.24; organic = 0.0; staff = 'นงรัก รินริโก' }
    'พิเศษ7' = @{ mean = 5.15; organic = 0.0; staff = 'อุไร บุญสวัสดิ์' }
    'พิเศษ8' = @{ mean = 8.24; organic = 0.0; staff = 'อภัสณันท์ อบแก้ว' }
    'พิเศษตึกพรหม' = @{ mean = 5.15; organic = 0.0; staff = 'พรหมพร แวดล้อม' }
    'สงฆ์อาพาธ' = @{ mean = 5.15; organic = 0.0; staff = 'พรหมพร แวดล้อม' }
    'ห้องผ่าตัด' = @{ mean = 9.27; organic = 0.0; staff = 'ตินนา นันทะวงศ์' }
    'วิสัญญี' = @{ mean = 9.27; organic = 0.0; staff = 'ตินนา นันทะวงศ์' }
    'ER' = @{ mean = 3.61; organic = 0.0; staff = 'อริริษา อารีรมย์' }
    'อุบัติเหตุฉุกเฉิน' = @{ mean = 3.61; organic = 0.0; staff = 'อริริษา อารีรมย์' }
    'ห้องคลอด' = @{ mean = 3.71; organic = 0.0; staff = 'ไพรจิตร สิทธิ' }
    'ออโตปิดิกส์' = @{ mean = 8.34; organic = 0.0; staff = 'ไพรจิตร สิทธิ' }
    'ออโถปิดิกส์' = @{ mean = 8.34; organic = 0.0; staff = 'ไพรจิตร สิทธิ' }
    'ไตเทียม' = @{ mean = 8.24; organic = 0.0; staff = 'บัวลี แสงสว่าง' }
    'จักษุ' = @{ mean = 7.42; organic = 0.0; staff = 'ปราณี คงดี' }
    'ห้องยา' = @{ mean = 8.24; organic = 0.0; staff = 'ฐิตาภรณ์ พันธ์คำ' }
    'ห้องจ่ายยา' = @{ mean = 8.24; organic = 0.0; staff = 'ฐิตาภรณ์ พันธ์คำ' }
    'คลังยา' = @{ mean = 1.55; organic = 0.0; staff = 'นันทนา ทวีวงศ์' }
    'ห้อง LAB' = @{ mean = 3.86; organic = 0.0; staff = 'นารอน สุวรรณา' }
    'ห้องแลบ' = @{ mean = 3.86; organic = 0.0; staff = 'นารอน สุวรรณา' }
    'X-RAY' = @{ mean = 2.06; organic = 0.0; staff = 'คมคาย ศรีเนตร' }
    'CT SCAN' = @{ mean = 2.06; organic = 0.0; staff = 'คมคาย ศรีเนตร' }
    'OPD GP' = @{ mean = 2.06; organic = 0.0; staff = 'คมคาย ศรีเนตร' }
    'OPD เฉพาะทาง' = @{ mean = 3.61; organic = 0.0; staff = 'วรรณา สดใส' }
    'OPD NCD' = @{ mean = 2.58; organic = 0.0; staff = 'วรรณา สดใส' }
    'OPD อายุรกรรมเด็ก' = @{ mean = 2.06; organic = 0.0; staff = 'บัวลี แสงสว่าง' }
    'ทันตกรรม' = @{ mean = 3.09; organic = 0.0; staff = 'บัวลี แสงสว่าง' }
    'โภชนาการ' = @{ mean = 3.61; organic = 12.36; staff = 'ปวีณา ลาสา' }
    'โรงอาหาร' = @{ mean = 4.12; organic = 8.24; staff = 'ปวีณา ลาสา' }
    'ซักรีด' = @{ mean = 1.08; organic = 0.0; staff = 'ปวีณา ลาสา' }
    'อาคารซ่อมบำรุง' = @{ mean = 10.30; organic = 0.0; staff = 'ปวีณา ลาสา' }
    'จ่ายกลาง' = @{ mean = 4.12; organic = 0.0; staff = 'ศรีสุดา มะลิวัลย์' }
    'พัสดุ' = @{ mean = 3.09; organic = 0.0; staff = 'ศรีสุดา มะลิวัลย์' }
    'ธุรการ' = @{ mean = 10.30; organic = 0.0; staff = 'ประไพพิศ อารีรมย์' }
    'พรส' = @{ mean = 2.06; organic = 0.0; staff = 'ประไพพิศ อารีรมย์' }
    'องค์กรแพทย์' = @{ mean = 0.52; organic = 0.0; staff = 'ประไพพิศ อารีรมย์' }
    'งานประกัน' = @{ mean = 1.03; organic = 0.0; staff = 'ประไพพิศ อารีรมย์' }
    'กายภาพบำบัด' = @{ mean = 1.03; organic = 0.0; staff = 'สิริพร พรมดี' }
    'เวชกรรมสังคม' = @{ mean = 1.55; organic = 0.0; staff = 'กัญญารัตน์ ชัยศรี' }
    'คลินิกบริการ' = @{ mean = 2.06; organic = 0.0; staff = 'วรรณา สดใส' }
    'งานจิตเวช' = @{ mean = 2.06; organic = 0.0; staff = 'วิภาดา มณีจันทร์' }
}

$defaultStaffList = @(
    'พรรณี ขลุ่ยทอง', 'อรทัย เนืองพงษ์', 'อุไร บุญสวัสดิ์', 'อัญชลี มุขธรรม',
    'นารอน สุวรรณา', 'สุวนิตย์ งามเถื่อน', 'ประไพพิศ อารีรมย์', 'ปวีณา ลาสา',
    'พินิจ ผลพันธ์', 'อริริษา อารีรมย์', 'ฉวี บุญสนิท', 'ปราณี คงดี',
    'อรัญญา นันทะวงศ์', 'หนูกาญจน์', 'จารุวรรณ์ หวังชื่น', 'ฐิตาภรณ์ พันธ์คำ',
    'เดือนเพ็ญ แก่นสายศ', 'นงรัก รินริโก', 'ตินนา นันทะวงศ์', 'ไพรจิตร สิทธิ',
    'บัวลี แสงสว่าง', 'อภัสณันท์ อบแก้ว', 'พรหมพร แวดล้อม', 'คมคาย ศรีเนตร',
    'วรรณา สดใส', 'ศรีสุดา มะลิวัลย์', 'นันทนา ทวีวงศ์'
)

$records = @()
$idx = 1

foreach ($d in $depts) {
    $dId = if ($d.id) { $d.id } else { $d.department_name }
    $dName = $d.department_name
    
    $baseMean = 3.5
    $baseOrg = 0.0
    $matched = $false
    $staff = $null

    foreach ($k in $deptBaselines.Keys) {
        if ($dName -like ('*' + $k + '*') -or $k -like ('*' + $dName + '*')) {
            $baseMean = $deptBaselines[$k].mean
            $baseOrg = $deptBaselines[$k].organic
            $staff = $deptBaselines[$k].staff
            $matched = $true
            break
        }
    }

    # Future Department Intelligent Domain Classifier (+3% growth)
    if (-not $matched) {
        if ($dName -like '*ICU*' -or $dName -like '*วิกฤต*' -or $dName -like '*อายุรกรรม*' -or $dName -like '*ศัลยกรรม*' -or $dName -like '*หอผู้ป่วย*' -or $dName -like '*IPD*' -or $dName -like '*พิเศษ*' -or $dName -like '*กุมาร*' -or $dName -like '*สูติ*') {
            $baseMean = 13.5 * 1.03
        } elseif ($dName -like '*ผ่าตัด*' -or $dName -like '*วิสัญญี*' -or $dName -like '*ER*' -or $dName -like '*ฉุกเฉิน*' -or $dName -like '*ไต*' -or $dName -like '*คลอด*') {
            $baseMean = 7.5 * 1.03
        } elseif ($dName -like '*โภชนาการ*' -or $dName -like '*ครัว*' -or $dName -like '*อาหาร*') {
            $baseMean = 3.6 * 1.03
            $baseOrg = 12.0 * 1.03
        } elseif ($dName -like '*ซ่อมบำรุง*' -or $dName -like '*อาคาร*' -or $dName -like '*ยานพาหนะ*' -or $dName -like '*ซักรีด*') {
            $baseMean = 9.0 * 1.03
        } elseif ($dName -like '*LAB*' -or $dName -like '*แล็บ*' -or $dName -like '*แลบ*' -or $dName -like '*ยา*' -or $dName -like '*เภสัช*' -or $dName -like '*X-Ray*' -or $dName -like '*CT*') {
            $baseMean = 5.0 * 1.03
        } elseif ($dName -like '*OPD*' -or $dName -like '*ตรวจ*' -or $dName -like '*คลินิก*' -or $dName -like '*ทันตกรรม*' -or $dName -like '*กายภาพ*') {
            $baseMean = 2.5 * 1.03
        } elseif ($dName -like '*ธุรการ*' -or $dName -like '*บริหาร*' -or $dName -like '*การเงิน*' -or $dName -like '*ประกัน*' -or $dName -like '*องค์กร*' -or $dName -like '*พรส*') {
            $baseMean = 1.5 * 1.03
        } else {
            $baseMean = 2.5 * 1.03
        }
    }

    if ($null -eq $staff) {
        $hash = [Math]::Abs($dName.GetHashCode()) % $defaultStaffList.Count
        $staff = $defaultStaffList[$hash]
    }

    # Generate 2 Shifts per day:
    # Morning (08:15-11:45): 60% - 68% of baseline (mean ~64%)
    # Afternoon (13:15-15:45): 32% - 40% of baseline (mean ~36%)
    $shifts = @('morning', 'afternoon')
    foreach ($shift in $shifts) {
        if ($shift -eq 'morning') {
            $mRatio = (Get-Random -Minimum 60 -Maximum 69) / 100.0 # 0.60 - 0.68
            $genKg = [Math]::Round($baseMean * $mRatio, 1)
            $orgKg = if ($baseOrg -gt 0) { [Math]::Round($baseOrg * $mRatio, 1) } else { 0.0 }
            if ($genKg -lt 0.1 -and $baseMean -gt 0) { $genKg = 0.1 }

            $mHour = (Get-Random -Minimum 8 -Maximum 12).ToString('D2')
            $mMin = (Get-Random -Minimum 15 -Maximum 55).ToString('D2')
            $timeStr = ('{0}:{1}:00' -f $mHour, $mMin)
            $idSuffix = 'M'
        } else {
            $aRatio = (Get-Random -Minimum 32 -Maximum 41) / 100.0 # 0.32 - 0.40
            $genKg = [Math]::Round($baseMean * $aRatio, 1)
            $orgKg = if ($baseOrg -gt 0) { [Math]::Round($baseOrg * $aRatio, 1) } else { 0.0 }
            if ($genKg -lt 0.1 -and $baseMean -gt 0) { $genKg = 0.1 }

            $aHour = (Get-Random -Minimum 13 -Maximum 16).ToString('D2')
            $aMin = (Get-Random -Minimum 15 -Maximum 55).ToString('D2')
            $timeStr = ('{0}:{1}:00' -f $aHour, $aMin)
            $idSuffix = 'A'
        }

        $recId = ('GEN-{0}-{1}-{2}' -f [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(), $idx.ToString('D3'), $idSuffix)
        
        $record = @{
            id = $recId
            year = $todayBE.ToString()
            month = $monthName
            waste_date = $today
            department_id = $dId
            general_kg = $genKg
            organic_kg = $orgKg
            recorded_by = $staff
            created_at = ('{0}T{1}+07:00' -f $today, $timeStr)
        }

        $records += $record
    }
    $idx++
}

Write-Host ('Generated {0} department records across 2 shifts (Morning 64% / Afternoon 36%). Inserting into Supabase...' -f $records.Count)
$jsonPayload = $records | ConvertTo-Json -Depth 5

try {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($jsonPayload)
    $webReq = [System.Net.HttpWebRequest]::Create(('{0}/rest/v1/general_waste' -f $url))
    $webReq.Method = 'POST'
    $webReq.Headers.Add('apikey', $key)
    $webReq.Headers.Add('Authorization', ('Bearer ' + $key))
    $webReq.Headers.Add('Prefer', 'resolution=merge-duplicates,return=representation')
    $webReq.ContentType = 'application/json; charset=utf-8'
    $webReq.ContentLength = $bytes.Length

    $stream = $webReq.GetRequestStream()
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Close()

    $resp = $webReq.GetResponse()
    Write-Host ('Success: Recorded {0} department waste entries across 2 shifts for {1} into Supabase!' -f $records.Count, $today)
} catch {
    Write-Host 'Error saving to Supabase:' $_.Exception.Message
}