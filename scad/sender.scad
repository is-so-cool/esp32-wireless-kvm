// =========================================================
// PCB 外壳 - 圆形散热孔版 (散热区域收缩 2mm)
// (底壳 16mm 容纳排针，上盖 2mm 平盖加长填缝块)
// 坐标系以内部腔体底面中心为原点 (0, 0, 0)
// =========================================================

$fn = 32; // 圆角平滑度

// =========================================================
// 0. 渲染模式选择
// =========================================================
// 1 = 仅显示底壳 (导出底壳 STL)
// 2 = 仅显示上盖 (导出上盖 STL, 已自动倒置便于打印)
// 3 = 组合预览模式 (上下盖扣合状态)
render_mode = 3;

// =========================================================
// 1. 基础尺寸参数 (单位: mm)
// =========================================================
pcb_width = 18.20; // PCB 宽度 (Y轴)
pcb_length = 23.00; // PCB 长度 (X轴)
margin = 0.40; // 容差间隙 (单边 0.2mm)
pcb_thick = 0.8;

wall = 1.60; // 墙壁厚度
floor_thick = 2.00; // 上盖/底板厚度 (2mm)
radius = 2.50; // 四周外圆角

// 上盖扣合唇 (Lip/Plug) 参数
lip_height = 1.00; // 伸入底壳内腔的深度
lip_gap = 0.0; // 扣合公差

// 圆形散热孔参数
hole_r = 1.00; // 散热圆孔半径 (直径 2.0mm)
hole_spacing = 2.80; // 圆孔中心距

// =========================================================
// 2. 接口尺寸与位置
// =========================================================
// 后墙 Type-C 母座 (Z=0 贴地)
typec_w = 9.0; // 开孔宽度
typec_h = 4.0; // 开孔高度
typec_r = 1.25; // Type-C 圆角

// 前墙 USB-A 公口 (Z=5.5 起始，纯矩形无圆角)
usba_w = 12.0; // 开孔宽度
usba_h = 4.4; // 开孔高度
usba_z = 5.5; // USB-A 开孔底边离内部底面的距离
// USB-A 盖帽专有参数
cap_depth = 24.00; // 包裹 USB-A 金属公头的深度 (15mm)
cap_wall_len = 2.00; // 盖帽最外侧封底厚度 (2mm)
cap_gap = 0.15; // 套入单边公差 (0.15mm)

// =========================================================
// 3. 尺寸自动计算
// =========================================================
box_height = pcb_thick + typec_h + lip_height; // 5.8 底壳内腔总高度
in_x = pcb_length + margin; // 23.4 mm
in_y = pcb_width + margin; // 18.6 mm

out_x = in_x + wall * 2; // 26.6
out_y = in_y + wall * 2; // 21.8
out_z = box_height + floor_thick;

lip_x = in_x - lip_gap * 2;
lip_y = in_y - lip_gap * 2;

// =========================================================
// 4. 基础图形模块
// =========================================================

module rounded_box(x, y, z, r) {
  hull() {
    for (dx = [-x / 2 + r, x / 2 - r]) {
      for (dy = [-y / 2 + r, y / 2 - r]) {
        translate([dx, dy, 0])
          cylinder(r=r, h=z);
      }
    }
  }
}
// 前端 (X正方向) 纯直角，后端 (X负方向) 带圆角的特殊柱体
module custom_box(x, y, z, r) {
  hull() {
    // 后端 (X负方向)：带有圆角 r
    for (dy = [-y / 2 + r, y / 2 - r]) {
      translate([-x / 2 + r, dy, 0])
        cylinder(r=r, h=z);
    }
    // 前端 (X正方向)：纯直角 (极小圆角或0，这里直接放直角点)
    translate([x / 2 - 0.01, -y / 2, 0])
      cube([0.01, y, z]);
  }
}
// 圆孔交错阵列
module round_holes_pattern(bound_x, bound_y, h) {
  dx = hole_spacing;
  dy = hole_spacing * sin(60);

  nx = floor(bound_x / dx);
  ny = floor(bound_y / dy);

  intersection() {
    // 限制圆孔阵列范围在安全边界内
    cube([bound_x, bound_y, h + 2], center=true);

    // 错位交错排列圆孔
    for (i = [-nx / 2:nx / 2]) {
      for (j = [-ny / 2:ny / 2]) {
        x_offset = i * dx + ( (abs(j) % 2 == 1) ? dx / 2 : 0);
        y_offset = j * dy;

        translate([x_offset, y_offset, 0])
          cylinder(r=hole_r, h=h + 4, center=true);
      }
    }
  }
}

// 标准 Type-C 椭圆形孔
module typec_cutout() {
  hull() {
    for (dy = [-typec_w / 2 + typec_r, typec_w / 2 - typec_r]) {
      for (dz = [typec_r, typec_h - typec_r]) {
        translate([0, dy, dz])
          rotate([0, 90, 0])
            cylinder(r=typec_r, h=wall * 3, center=true);
      }
    }
  }
}

// =========================================================
// 5. 件形生成
// =========================================================

// --- 底壳组件 (带底面圆孔) ---
module bottom_case() {
  difference() {
    // 1. 外壳主体
    translate([0, 0, -floor_thick])
      custom_box(out_x, out_y, out_z, radius);

    // 2. 掏空内腔
    translate([-in_x / 2, -in_y / 2, 0])
      cube([in_x, in_y, box_height + 2]);

    // 3. 后墙 Type-C 贯通槽
    translate([-out_x / 2 - 0.1, -typec_w / 2, typec_h / 2]) {
      cube([wall * 2, typec_w, box_height + 1]);
    }
    translate([-out_x / 2 - 0.1, 0, 0]) {
      typec_cutout();
    }

    // 5. 底板圆孔散热网 (散热区域收缩 2mm: in_x - 5.0, in_y - 5.0)
    translate([0, 0, -floor_thick / 2])
      round_holes_pattern(in_x - 5.0, in_y - 5.0, floor_thick + 2);
  }
  translate([-in_x / 2, -in_y / 2, 0])  cube([2, 2, typec_h]);
  translate([-in_x / 2, in_y / 2 - 2, 0])  cube([2, 2, typec_h]);
  translate([in_x / 2 - 2, -in_y / 2, 0])  cube([2, 2, typec_h]);
  translate([in_x / 2 - 2, in_y / 2 - 2, 0])  cube([2, 2, typec_h]);
}

// --- 上盖组件 (带顶面圆孔) ---
module top_lid() {
  union() {
    // 带有圆孔的平板顶盖
    difference() {
      // 1. 2mm 平板顶盖
      translate([0, 0, 0])
        custom_box(out_x, out_y, floor_thick, radius);

      // 2. 顶面圆孔散热网 (散热区域收缩 2mm)
        // translate([0, 0, floor_thick / 2])
        //   round_holes_pattern(lip_x - wall * 2 - 4.0, lip_y - wall * 2 - 4.0, floor_thick + 2);
    }

    // 3. 下沉定位榫 (Lip)
    translate([0, 0, -lip_height])
      difference() {
        rounded_box(lip_x, lip_y, lip_height + 0.01, max(0.5, radius - wall));
        translate([0, 0, -0.1])
          rounded_box(lip_x - wall * 2, lip_y - wall * 2, lip_height + 0.3, max(0.2, radius - wall * 2));
      }

    // 5. 后墙 Type-C 填缝挡块
    translate([0, 0, -box_height]) {
      difference() {
        translate([-out_x / 2 + wall / 2, 0, box_height / 2])
          cube([wall, typec_w - lip_gap * 2, box_height], center=true);

        translate([-in_x / 2 - wall / 2, 0, 0])
          typec_cutout();
        translate([-in_x / 2 - wall, -typec_w / 2, 0])
          cube([wall, typec_w, typec_h / 2]);
      }
    }
  }
}

// =========================================================
// 6. 渲染逻辑控制
// =========================================================

function get_sender_height() = out_z + floor_thick; // 9.8
function get_sender_length() = out_x;

module sender_diff() {
  translate([0, 0, -floor_thick])
    custom_box(out_x, out_y, out_z + floor_thick, radius);
}

module sender_box() {
  bottom_case();
}

module sender_lid() {
  translate([0, 0, box_height])
    top_lid();
}
