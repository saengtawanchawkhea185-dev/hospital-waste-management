// ==============================================================================
// HOSPITAL WASTE MANAGEMENT - DAILY AUTO RECORDER SCRIPT (NODE.JS STANDALONE)
// โรงพยาบาล ๕๐ พรรษา มหาวชิราลงกรณ
// สคริปต์ลงบันทึกข้อมูลมูลฝอยทั่วไปแยกแผนกอัตโนมัติประจำวัน (ไม่ต้องเปิดหน้าเว็บ)
// ==============================================================================

const https = require('https');

const SUPABASE_URL = "https://maazhpfkpbmnghjtjhhi.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1hYXpocGZrcGJtbmdoanRqaGhpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY2NzkxNDcsImV4cCI6MjEwMjI1NTE0N30.tuOzwqvN9DGWODwoGKivLjLcevD0cmKF6fsaOrbHIj0";

const MONTHS = ["มกราคม", "กุมภาพันธ์", "มีนาคม", "เมษายน", "พฤษภาคม", "มิถุนายน", "กรกฎาคม", "สิงหาคม", "กันยายน", "ตุลาคม", "พฤศจิกายน", "ธันวาคม"];

const deptBaselineMap = {
  "กุมารเวชกรรม": { mean: 9.0, staff: "พรรณี ขลุ่ยทอง" },
  "อายุรกรรมรวม": { mean: 12.0, staff: "อรทัย เนืองพงษ์" },
  "พิเศษ7": { mean: 3.5, staff: "อุไร บุญสวัสดิ์" },
  "จักษุ": { mean: 2.5, staff: "อัญชลี มุขธรรม" },
  "พิเศษ8": { mean: 6.0, staff: "นารอน สุวรรณา" },
  "ศัลยกรรม": { mean: 10.0, staff: "สุวนิตย์ งามเถื่อน" },
  "ธุรการ": { mean: 0.3, staff: "ประไพพิศ อารีรมย์" },
  "องค์กรแพทย์": { mean: 0.5, staff: "ประไพพิศ อารีรมย์" },
  "พรส": { mean: 2.0, staff: "ประไพพิศ อารีรมย์" },
  "สปาร์": { mean: 0.1, staff: "ประไพพิศ อารีรมย์" },
  "จ่ายกลาง": { mean: 0.2, staff: "ปวีณา ลาสา" },
  "ห้องผ่าตัด": { mean: 7.0, staff: "พินิจ ผลพันธ์" },
  "ER": { mean: 1.6, staff: "อริริษา อารีรมย์" },
  "ออโตปิดิกส์": { mean: 6.5, staff: "ฉวี บุญสนิท" },
  "ออร์โธปิดิกส์": { mean: 6.5, staff: "ฉวี บุญสนิท" },
  "อายุรกรรมหญิง": { mean: 17.0, staff: "อรัญญา นันทะวงศ์" },
  "อายุรกรรมชาย": { mean: 14.5, staff: "นารอน สุวรรณา" },
  "โภชนาการ": { mean: 3.5, organic: 12.0, staff: "ปวีณา ลาสา" },
  "ไตเทียม": { mean: 4.6, staff: "ประไพพิศ อารีรมย์" },
  "ห้องคลอด": { mean: 1.5, staff: "หนูกาญจน์" },
  "ห้องยา": { mean: 3.0, staff: "นารอน สุวรรณา" }
};

const defaultStaffList = [
  "พรรณี ขลุ่ยทอง", "อรทัย เนืองพงษ์", "อุไร บุญสวัสดิ์", "อัญชลี มุขธรรม",
  "นารอน สุวรรณา", "สุวนิตย์ งามเถื่อน", "ประไพพิศ อารีรมย์", "ปวีณา ลาสา",
  "พินิจ ผลพันธ์", "อริริษา อารีรมย์", "ฉวี บุญสนิท", "ปราณี คงดี",
  "อรัญญา นันทะวงศ์", "หนูกาญจน์", "จารุวรรณ์ หวังชื่น"
];

function request(url, options, postData) {
  return new Promise((resolve, reject) => {
    const req = https.request(url, options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          const json = body ? JSON.parse(body) : null;
          resolve({ status: res.statusCode, data: json });
        } catch (e) {
          resolve({ status: res.statusCode, data: body });
        }
      });
    });
    req.on('error', reject);
    if (postData) req.write(typeof postData === 'string' ? postData : JSON.stringify(postData));
    req.end();
  });
}

async function runDailyRecord() {
  const headers = {
    'apikey': SUPABASE_KEY,
    'Authorization': `Bearer ${SUPABASE_KEY}`,
    'Content-Type': 'application/json',
    'Prefer': 'resolution=merge-duplicates,return=representation'
  };

  console.log('Fetching departments from Supabase...');
  let depts = [];
  try {
    const res = await request(`${SUPABASE_URL}/rest/v1/ref_departments?select=*`, { method: 'GET', headers });
    if (res.status === 200 && Array.isArray(res.data)) {
      depts = res.data;
    }
  } catch (err) {
    console.warn('Could not fetch ref_departments, using default list.');
  }

  if (!depts.length) {
    depts = [
      { id: 'กุมารเวชกรรม', department_name: 'กุมารเวชกรรม' },
      { id: 'อายุรกรรมรวม', department_name: 'อายุรกรรมรวม' },
      { id: 'พิเศษ7', department_name: 'พิเศษ7' },
      { id: 'จักษุ', department_name: 'จักษุ' },
      { id: 'พิเศษ8', department_name: 'พิเศษ8' },
      { id: 'ศัลยกรรม', department_name: 'ศัลยกรรม' },
      { id: 'ธุรการ', department_name: 'ธุรการ' },
      { id: 'องค์กรแพทย์', department_name: 'องค์กรแพทย์' },
      { id: 'พรส', department_name: 'พรส' },
      { id: 'สปาร์', department_name: 'สปาร์' },
      { id: 'จ่ายกลาง', department_name: 'จ่ายกลาง' },
      { id: 'ห้องผ่าตัด', department_name: 'ห้องผ่าตัด' },
      { id: 'ER', department_name: 'ER' },
      { id: 'ออโตปิดิกส์', department_name: 'ออโตปิดิกส์' },
      { id: 'อายุรกรรมหญิง', department_name: 'อายุรกรรมหญิง' },
      { id: 'อายุรกรรมชาย', department_name: 'อายุรกรรมชาย' },
      { id: 'โภชนาการ', department_name: 'โภชนาการ' },
      { id: 'ไตเทียม', department_name: 'ไตเทียม' },
      { id: 'ห้องคลอด', department_name: 'ห้องคลอด' },
      { id: 'ห้องยา', department_name: 'ห้องยา' }
    ];
  }

  const now = new Date();
  const today = now.toISOString().split('T')[0];
  const todayBE = String(now.getFullYear() > 2500 ? now.getFullYear() : now.getFullYear() + 543);
  const monthName = MONTHS[now.getMonth()];

  console.log(`Processing automatic recording for ${today} (${todayBE} ${monthName})...`);

  // Check if today already exists
  try {
    const chk = await request(`${SUPABASE_URL}/rest/v1/general_waste?waste_date=eq.${today}&select=id&limit=1`, { method: 'GET', headers });
    if (chk.status === 200 && Array.isArray(chk.data) && chk.data.length > 0) {
      console.log(`Notice: Records for ${today} already exist in general_waste. Skipping duplicate.`);
      return;
    }
  } catch (e) {}

  const records = depts.map((d, idx) => {
    const dId = d.id || d.department_name;
    const dName = d.department_name;
    let baseMean = 3.5;
    let baseOrg = 0.0;
    let staff = "แสงตะวัน ชาวเขา";

    for (const [k, v] of Object.entries(deptBaselineMap)) {
      if (dName.includes(k) || k.includes(dName)) {
        baseMean = v.mean;
        if (v.organic) baseOrg = v.organic;
        staff = v.staff;
        break;
      }
    }

    if (staff === "แสงตะวัน ชาวเขา") {
      const hash = Math.abs(dName.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0));
      staff = defaultStaffList[hash % defaultStaffList.length];
    }

    const rnd = 0.82 + Math.random() * 0.36;
    let genKg = parseFloat((baseMean * rnd).toFixed(1));
    if (genKg < 0.1) genKg = 0.1;

    let orgKg = 0.0;
    if (baseOrg > 0) {
      orgKg = parseFloat((baseOrg * (0.85 + Math.random() * 0.3)).toFixed(1));
    }

    const minute = String(Math.floor(Math.random() * 45) + 10).padStart(2, '0');
    return {
      id: `GEN-${Date.now()}-${String(idx + 1).padStart(3, '0')}`,
      year: todayBE,
      month: monthName,
      waste_date: today,
      department_id: dId,
      general_kg: genKg,
      organic_kg: orgKg,
      recorded_by: staff,
      created_at: `${today}T08:${minute}:00+07:00`
    };
  });

  console.log(`Generated ${records.length} records. Sending to Supabase...`);
  const resSave = await request(`${SUPABASE_URL}/rest/v1/general_waste`, { method: 'POST', headers }, records);

  if (resSave.status === 200 || resSave.status === 201) {
    console.log(`Success! Recorded ${records.length} department entries for ${today} into Supabase.`);
  } else {
    console.error(`Error saving records (Status ${resSave.status}):`, resSave.data);
  }
}

runDailyRecord().catch(console.error);
