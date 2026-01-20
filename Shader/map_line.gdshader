shader_type canvas_item;

uniform float dash_count = 10.0;     // จำนวนจุดวงกลมต่อหนึ่งเส้น
uniform float circle_radius = 0.3;  // ขนาดวงกลม (0.1 - 0.5)
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    // ตรวจสอบว่าเส้นเป็นแนวตั้งหรือแนวนอนโดยดูจากอนุพันธ์ของ UV
    // fwidth ช่วยให้เรารู้ว่า UV เปลี่ยนแปลงในทิศทางไหนมากกว่ากัน
    vec2 fw = fwidth(UV);
    float progress;
    
    if (fw.y > fw.x) {
        // ถ้าการเปลี่ยนแปลงแกน Y มากกว่า แสดงว่าเป็นเส้นแนวตั้ง
        progress = UV.y;
    } else {
        // ถ้าการเปลี่ยนแปลงแกน X มากกว่า หรือพอๆ กัน แสดงว่าเป็นเส้นแนวนอนหรือเฉียง
        progress = UV.x;
    }

    // สร้างช่วงซ้ำๆ (Fract) ตามจำนวนจุดที่ต้องการ
    float m = fract(progress * dash_count);
    
    // คำนวณระยะห่างจากจุดศูนย์กลาง (0.5, 0.5) เพื่อสร้างทรงกลม
    // ใช้ fw.y > fw.x เพื่อสลับแกนการวาดให้เหมาะสมกับทิศทางเส้น
    float dist;
    if (fw.y > fw.x) {
        dist = distance(vec2(UV.x, m), vec2(0.5, 0.5));
    } else {
        dist = distance(vec2(m, UV.y), vec2(0.5, 0.5));
    }

    // ตัดส่วนที่ไม่ใช่วงกลมทิ้ง
    if (dist > circle_radius) {
        discard;
    }

    COLOR = line_color;
}